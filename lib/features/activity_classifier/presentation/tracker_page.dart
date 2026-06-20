import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flowfit/services/phone_data_listener.dart';
import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/models/sensor_batch.dart';
import 'package:provider/provider.dart';

import 'providers.dart';
import '../platform/tflite_activity_classifier.dart';
import '../platform/heart_bpm_adapter.dart';

enum BpmSource { simulation, plugin, watch }

enum AccelSource { phone, simulation, watch }

abstract class ActivityWatchDataListener {
  Future<bool> startListening();
  Stream<HeartRateData> get heartRateStream;
  Stream<SensorBatch> get sensorBatchStream;
}

class PhoneActivityWatchDataListener implements ActivityWatchDataListener {
  PhoneActivityWatchDataListener(this._phoneListener);

  final PhoneDataListener _phoneListener;

  @override
  Future<bool> startListening() => _phoneListener.startListening();

  @override
  Stream<HeartRateData> get heartRateStream => _phoneListener.heartRateStream;

  @override
  Stream<SensorBatch> get sensorBatchStream => _phoneListener.sensorBatchStream;
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({
    super.key,
    this.watchDataListener,
    this.initialAccelSource = AccelSource.phone,
    this.initialBpmSource = BpmSource.simulation,
  });

  final ActivityWatchDataListener? watchDataListener;
  final AccelSource initialAccelSource;
  final BpmSource initialBpmSource;

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  // Buffers
  final List<List<double>> _dataBuffer = [];
  static const int _windowSize = 320; // 10 seconds @ ~32Hz

  // State
  double _simulatedHR = 80.0; // Slider to control Heart Rate manually

  // Sensor subscription
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<int?>? _bpmSub;
  StreamSubscription? _sensorBatchSub;
  Timer? _accelTimer;
  int _accelSimTick = 0;
  double _accelAmplitude = 1.0; // Synthetic amplitude
  double _accelFreqHz = 1.0; // Tones per second in simulation
  late AccelSource _accelSource;

  // Local references to providers
  late ActivityClassifierViewModel _viewModel;
  late TFLiteActivityClassifier _platformClassifier;
  late ActivityWatchDataListener _watchDataListener;
  bool _initialized = false;
  int? _currentBpmValue;
  late bool _forceSimulate;
  late BpmSource _bpmSource;
  bool _pluginAvailable = false;
  // plugin availability determined dynamically by adapter connection

  // Always-on watch HR monitor (independent of selected source)
  int? _watchLiveBpm;
  bool _watchLiveConnected = false;
  StreamSubscription<HeartRateData>? _watchLiveSub;
  Future<bool>? _watchListenerStartFuture;
  bool _isStartingWatchListener = false;
  bool _watchListenerStarted = false;
  String? _watchListenerError;

  @override
  void initState() {
    super.initState();
    _accelSource = widget.initialAccelSource;
    _bpmSource = widget.initialBpmSource;
    _forceSimulate = widget.initialBpmSource == BpmSource.simulation;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      // Resolve providers from the widget tree
      _viewModel = Provider.of<ActivityClassifierViewModel>(
        context,
        listen: false,
      );
      _platformClassifier = Provider.of<TFLiteActivityClassifier>(
        context,
        listen: false,
      );
      _watchDataListener =
          widget.watchDataListener ??
          PhoneActivityWatchDataListener(
            Provider.of<PhoneDataListener>(context, listen: false),
          );

      // Ensure model is loaded once at startup
      if (!_platformClassifier.isLoaded) {
        _platformClassifier.loadModel();
      }

      _startSensorSubscription();

      // Subscribe to BPM stream (if any)
      // connect adapter to the selected source (default Simulation)
      _connectToSelectedSource();

      // Always subscribe to watch HR for the persistent banner
      _subscribeWatchLive();

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _stopSensorSubscription();
    _bpmSub?.cancel();
    _sensorBatchSub?.cancel();
    _watchLiveSub?.cancel();
    super.dispose();
  }

  void _subscribeWatchLive({bool startListener = true}) {
    if (startListener) {
      unawaited(_startWatchListener());
    }
    _watchLiveSub = _watchDataListener.heartRateStream.listen(
      (HeartRateData data) {
        if (mounted && data.bpm != null && data.bpm! > 0) {
          setState(() {
            _watchLiveBpm = data.bpm;
            _watchLiveConnected = true;
          });
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _watchLiveConnected = false;
          _watchListenerStarted = false;
          _watchListenerError =
              'Watch data stream stopped. Check Bluetooth and Wear OS connection, then retry.';
        });
      },
    );
  }

  void _startSensorSubscription() {
    _stopSensorSubscription();

    if (_accelSource == AccelSource.watch) {
      // Use watch sensor batches (accelerometer + heart rate combined)
      unawaited(_startWatchSensorBatchSubscription());
    } else if (_accelSource == AccelSource.simulation) {
      // Simulate at ~32Hz (31ms per sample)
      final sampleMs = (1000 / 32).round();
      _accelTimer = Timer.periodic(Duration(milliseconds: sampleMs), (_) {
        // Synthetic signal: sinusoidal components + noise
        final t = _accelSimTick / 32.0; // seconds
        final x =
            _accelAmplitude * sin(2 * pi * _accelFreqHz * t) +
            (Random().nextDouble() - 0.5) * 0.05;
        final y =
            _accelAmplitude * sin(2 * pi * _accelFreqHz * t + pi / 3) +
            (Random().nextDouble() - 0.5) * 0.05;
        final z =
            _accelAmplitude * sin(2 * pi * _accelFreqHz * t + 2 * pi / 3) +
            9.8 +
            (Random().nextDouble() - 0.5) * 0.05;
        _accelSimTick++;
        _addToBuffer(AccelerometerEvent(x, y, z));
      });
    } else {
      // Use phone accelerometer
      _accelSub = accelerometerEventStream().listen((event) {
        _addToBuffer(event);
      });
    }
  }

  Future<void> _startWatchSensorBatchSubscription() async {
    final started = await _startWatchListener();
    if (!mounted || _accelSource != AccelSource.watch || !started) return;

    await _sensorBatchSub?.cancel();
    _sensorBatchSub = _watchDataListener.sensorBatchStream.listen(
      (sensorBatch) {
        // Sensor batch contains samples as 4-feature vectors [accX, accY, accZ, bpm]
        // Add all samples from the batch to our buffer
        for (final sample in sensorBatch.samples) {
          if (sample.length == 4) {
            _dataBuffer.add(sample);

            // Keep buffer at exactly 320 items
            if (_dataBuffer.length > _windowSize) {
              _dataBuffer.removeAt(0);
            }
          }
        }

        // Run inference when we have a full window
        if (_dataBuffer.length == _windowSize && !_viewModel.isLoading) {
          _runInference();
        }

        // Update UI with current BPM from watch (extract from first sample)
        if (sensorBatch.samples.isNotEmpty && sensorBatch.samples[0][3] > 0) {
          setState(() => _currentBpmValue = sensorBatch.samples[0][3].toInt());
        }
      },
      onError: (error) {
        debugPrint('Error receiving sensor batch from watch: $error');
        if (!mounted) return;
        setState(() {
          _watchListenerStarted = false;
          _watchListenerError =
              'Watch sensor batch stream stopped. Check Bluetooth and Wear OS connection, then retry.';
        });
      },
    );
  }

  void _stopSensorSubscription() {
    _accelSub?.cancel();
    _accelSub = null;
    _accelTimer?.cancel();
    _accelTimer = null;
    _sensorBatchSub?.cancel();
    _sensorBatchSub = null;
    _accelSimTick = 0;
  }

  void _addToBuffer(AccelerometerEvent event) {
    // 1. Add current reading + Simulated Heart Rate to buffer
    // Your model expects: [AccX, AccY, AccZ, BPM]
    final activeBpm = _forceSimulate
        ? _simulatedHR.round()
        : (_currentBpmValue ?? _simulatedHR.round());
    _dataBuffer.add([event.x, event.y, event.z, activeBpm.toDouble()]);

    // 2. Keep buffer at exactly 320 items
    if (_dataBuffer.length > _windowSize) {
      _dataBuffer.removeAt(0); // Slide window
    }

    // 3. Run inference every ~32 samples (approx once per second)
    // We don't run on every frame to save battery
    if (_dataBuffer.length == _windowSize &&
        !_viewModel.isLoading &&
        _dataBuffer.length % 32 == 0) {
      _runInference();
    }
  }

  Future<void> _runInference() async {
    // Make a defensive copy of the window for inference
    final input = List<List<double>>.from(_dataBuffer);

    try {
      await _viewModel.classify(input);
    } catch (_) {
      // ViewModel handles error logging and exposing error state
    }
  }

  Future<void> _connectToSelectedSource() async {
    final adapter = Provider.of<HeartBpmAdapter>(context, listen: false);

    // Cancel existing subscription
    _bpmSub?.cancel();
    _bpmSub = null;

    switch (_bpmSource) {
      case BpmSource.simulation:
        // Disconnect any external source and use manual slider bpm
        adapter.connectExternalStream(null);
        setState(() {
          _forceSimulate = true;
          _currentBpmValue = null;
        });
        break;
      case BpmSource.plugin:
        // Plugin connection is managed by app (main.dart) or other init code.
        // We assume main.dart or other code may have already connected the plugin stream.
        // If no plugin is connected, keep adapter disconnected and notify UI.
        // Optionally, application initialization can call:
        // `context.read<HeartBpmAdapter>().connectExternalStream(HeartBpm.heartBpmStream);`
        // no-op: assume plugin is connected externally (e.g., main.dart or other)
        setState(() {
          _forceSimulate = false;
        });
        break;
      case BpmSource.watch:
        // Start listening for watch data (with error handling)
        final started = await _startWatchListener();
        if (!started) {
          adapter.connectExternalStream(null);
          if (mounted) {
            setState(() {
              _forceSimulate = false;
              _currentBpmValue = null;
            });
          }
          break;
        }

        // Connect the watch heart rate stream to the adapter
        adapter.connectExternalStream(
          _watchDataListener.heartRateStream
              .map((hr) => hr.bpm ?? 0)
              .where((bpm) => bpm > 0),
        );

        setState(() {
          _forceSimulate = false;
        });
        break;
    }

    // Also locally subscribe to adapter stream to show current BPM in UI
    _bpmSub = adapter.bpmStream.listen((bpm) {
      if (mounted) {
        setState(() => _currentBpmValue = bpm);
      }
    });

    // Update plugin availability state (shows connected or not)
    setState(() {
      _pluginAvailable = adapter.hasExternalConnection;
    });
  }

  Future<bool> _startWatchListener({bool force = false}) {
    if (_watchListenerStarted && !force) {
      return Future.value(true);
    }
    if (_watchListenerStartFuture != null && !force) {
      return _watchListenerStartFuture!;
    }

    _watchListenerStartFuture = _performStartWatchListener().whenComplete(() {
      _watchListenerStartFuture = null;
    });
    return _watchListenerStartFuture!;
  }

  Future<bool> _performStartWatchListener() async {
    if (mounted) {
      setState(() {
        _isStartingWatchListener = true;
        _watchListenerError = null;
      });
    }

    try {
      final started = await _watchDataListener.startListening();
      if (!mounted) return started;

      setState(() {
        _isStartingWatchListener = false;
        _watchListenerStarted = started;
        _watchListenerError = started
            ? null
            : 'Could not start watch listener. Check Bluetooth and Wear OS connection, then retry.';
      });
      return started;
    } catch (error) {
      if (!mounted) return false;

      setState(() {
        _isStartingWatchListener = false;
        _watchListenerStarted = false;
        _watchListenerError =
            'Could not start watch listener. Check Bluetooth and Wear OS connection, then retry.';
      });
      return false;
    }
  }

  Future<void> _retryWatchListener() async {
    final started = await _startWatchListener(force: true);
    if (!mounted || !started) return;

    await _watchLiveSub?.cancel();
    _watchLiveSub = null;
    _subscribeWatchLive(startListener: false);

    if (_accelSource == AccelSource.watch) {
      _startSensorSubscription();
    }
    if (_bpmSource == BpmSource.watch) {
      await _connectToSelectedSource();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the ViewModel
    final viewModel = Provider.of<ActivityClassifierViewModel>(context);

    final currentActivity = viewModel.currentActivity?.label ?? 'Waiting...';
    final probs = viewModel.currentActivity?.probabilities ?? [0.0, 0.0, 0.0];
    final isLoading = viewModel.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Activity AI Classifier'),
            Text(
              'TensorFlow Lite Model',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Open Map',
            onPressed: () {
              Navigator.of(context).pushNamed('/mission');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // Always-on watch heart rate banner
            _buildWatchLiveBanner(),
            if (_watchListenerError != null) ...[
              const SizedBox(height: 8),
              _buildWatchListenerError(),
            ],
            const SizedBox(height: 16),
            // 1. The Result (Big Text)
            Text(
              currentActivity,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: currentActivity == 'Stress' ? Colors.red : Colors.green,
              ),
            ),

            const SizedBox(height: 20),

            // 2. The Probabilities (Debug View)
            Text('Stress: ${(_formatProb(probs[0]))}%'),
            Text('Cardio: ${(_formatProb(probs[1]))}%'),
            Text('Strength: ${(_formatProb(probs[2]))}%'),

            const SizedBox(height: 24),

            // Loading state
            if (isLoading) const CircularProgressIndicator(),

            const SizedBox(height: 24),

            // 3. Heart Rate Source Display
            if (_bpmSource == BpmSource.watch && _currentBpmValue != null) ...[
              // Show live watch heart rate
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      '❤️ Live Watch Heart Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_currentBpmValue BPM',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Using real-time data from Galaxy Watch',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Show simulation controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Simulate Heart Rate: ${_simulatedHR.round()} BPM'),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      const Text('Use simulation'),
                      Switch(
                        value: _forceSimulate,
                        onChanged: _bpmSource == BpmSource.simulation
                            ? (v) => setState(() => _forceSimulate = v)
                            : null, // Disable when not in simulation mode
                      ),
                    ],
                  ),
                ],
              ),
              Slider(
                min: 60,
                max: 180,
                value: _simulatedHR,
                onChanged: _bpmSource == BpmSource.simulation
                    ? (val) => setState(() => _simulatedHR = val)
                    : null, // Disable when not in simulation mode
                activeColor: Colors.red,
              ),
              const SizedBox(height: 4),
              Text(
                _bpmSource == BpmSource.simulation
                    ? 'Drag slider HIGH to simulate Panic/Running'
                    : 'Switch to Simulation mode to use slider',
                style: TextStyle(
                  color: _bpmSource == BpmSource.simulation
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Accelerometer Source Selection
            const Text(
              'Accelerometer Source',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Phone'),
                  selected: _accelSource == AccelSource.phone,
                  onSelected: (s) {
                    setState(() {
                      _accelSource = AccelSource.phone;
                      _startSensorSubscription();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Simulation'),
                  selected: _accelSource == AccelSource.simulation,
                  onSelected: (s) {
                    setState(() {
                      _accelSource = AccelSource.simulation;
                      _startSensorSubscription();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Watch'),
                  selected: _accelSource == AccelSource.watch,
                  onSelected: (s) {
                    setState(() {
                      _accelSource = AccelSource.watch;
                      _startSensorSubscription();
                    });
                  },
                ),
              ],
            ),

            // Simulation controls (only show when simulation is selected)
            if (_accelSource == AccelSource.simulation) ...[
              const SizedBox(height: 16),
              const Text(
                'Simulation Controls',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Amplitude:'),
                  Expanded(
                    child: Slider(
                      min: 0.0,
                      max: 2.0,
                      value: _accelAmplitude,
                      onChanged: (v) {
                        setState(() => _accelAmplitude = v);
                      },
                      divisions: 20,
                      label: _accelAmplitude.toStringAsFixed(2),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Frequency:'),
                  Expanded(
                    child: Slider(
                      min: 0.5,
                      max: 4.0,
                      value: _accelFreqHz,
                      onChanged: (v) {
                        setState(() => _accelFreqHz = v);
                      },
                      divisions: 35,
                      label: '${_accelFreqHz.toStringAsFixed(2)}Hz',
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Heart Rate Source Selection
            const Text(
              'Heart Rate Source',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Simulation'),
                  selected: _bpmSource == BpmSource.simulation,
                  onSelected: (s) {
                    setState(() {
                      _bpmSource = BpmSource.simulation;
                      _forceSimulate = true;
                      _connectToSelectedSource();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Plugin'),
                  selected: _bpmSource == BpmSource.plugin,
                  onSelected: (s) {
                    setState(() {
                      _bpmSource = BpmSource.plugin;
                      _forceSimulate = false;
                      _connectToSelectedSource();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Watch HR'),
                  selected: _bpmSource == BpmSource.watch,
                  onSelected: (s) {
                    setState(() {
                      _bpmSource = BpmSource.watch;
                      _forceSimulate = false;
                      _connectToSelectedSource();
                    });
                  },
                ),
              ],
            ),

            // Optional: show last error from ViewModel
            if (viewModel.hasError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  'Error: ${viewModel.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Display connection status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Accelerometer Status
                  Row(
                    children: [
                      Icon(
                        _accelSource == AccelSource.watch
                            ? Icons.watch
                            : _accelSource == AccelSource.phone
                            ? Icons.phone_android
                            : Icons.science,
                        color: _accelSource == AccelSource.watch
                            ? Colors.green
                            : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _accelSource == AccelSource.watch
                              ? 'Accelerometer: Watch'
                              : _accelSource == AccelSource.phone
                              ? 'Accelerometer: Phone'
                              : 'Accelerometer: Simulated',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Heart Rate Status
                  if (_bpmSource == BpmSource.plugin) ...[
                    Row(
                      children: [
                        Icon(
                          _pluginAvailable ? Icons.check_circle : Icons.error,
                          color: _pluginAvailable
                              ? Colors.green
                              : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pluginAvailable
                                ? 'Heart Rate: Plugin connected'
                                : 'Heart Rate: Plugin not connected',
                            style: TextStyle(
                              color: _pluginAvailable
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_bpmSource == BpmSource.watch) ...[
                    Row(
                      children: [
                        Icon(
                          _currentBpmValue != null
                              ? Icons.check_circle
                              : Icons.watch_off,
                          color: _currentBpmValue != null
                              ? Colors.green
                              : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentBpmValue != null
                                ? 'Heart Rate: Watch connected'
                                : 'Heart Rate: Waiting for watch...',
                            style: TextStyle(
                              color: _currentBpmValue != null
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_bpmSource == BpmSource.simulation) ...[
                    Row(
                      children: [
                        const Icon(Icons.science, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Heart Rate: Simulated (${_simulatedHR.round()} BPM)',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Buffer status
                  Row(
                    children: [
                      Icon(
                        _dataBuffer.length == _windowSize
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                        color: _dataBuffer.length == _windowSize
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Buffer: ${_dataBuffer.length}/$_windowSize samples',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),

                  // Watch integration tip
                  if (_accelSource == AccelSource.watch ||
                      _bpmSource == BpmSource.watch) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _accelSource == AccelSource.watch
                                  ? 'Using complete sensor batch from watch (accel + HR)'
                                  : 'Using watch heart rate only',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom padding for scrolling
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchLiveBanner() {
    final connected = _watchLiveConnected && _watchLiveBpm != null;
    final color = connected
        ? Colors.red
        : _watchListenerError != null
        ? Colors.orange
        : Colors.grey;
    final label = _isStartingWatchListener
        ? 'Starting listener...'
        : _watchListenerError != null
        ? 'Listener inactive'
        : connected
        ? '$_watchLiveBpm BPM'
        : 'Not connected';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.watch, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            'Galaxy Watch: ',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: connected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchListenerError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.watch_off, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _watchListenerError!,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isStartingWatchListener ? null : _retryWatchListener,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry watch listener'),
          ),
        ],
      ),
    );
  }

  String _formatProb(double p) => (p * 100).toStringAsFixed(1);
}
