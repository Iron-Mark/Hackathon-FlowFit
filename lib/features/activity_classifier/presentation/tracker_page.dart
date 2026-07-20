import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flowfit/models/heart_rate_data.dart';

import 'package:flowfit/features/activity_classifier/presentation/providers.dart';
import 'package:flowfit/features/activity_classifier/presentation/watch_data_listener.dart';
import 'package:flowfit/features/activity_classifier/presentation/widgets/tracker_source_controls.dart';
import 'package:flowfit/features/activity_classifier/presentation/widgets/tracker_status_card.dart';
import 'package:flowfit/features/activity_classifier/presentation/widgets/tracker_watch_banners.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';

export 'package:flowfit/features/activity_classifier/presentation/watch_data_listener.dart';

class TrackerPage extends ConsumerStatefulWidget {
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
  ConsumerState<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends ConsumerState<TrackerPage> {
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
  String? _modelLoadError;

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
      // Resolve dependencies from the Riverpod container
      _viewModel = ref.read(activityClassifierViewModelProvider);
      _platformClassifier = ref.read(tfliteActivityClassifierProvider);
      _watchDataListener =
          widget.watchDataListener ??
          PhoneActivityWatchDataListener(ref.read(phoneDataListenerProvider));

      // Ensure model is loaded once at startup
      if (!_platformClassifier.isLoaded) {
        unawaited(_loadActivityModel());
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

  Future<void> _loadActivityModel() async {
    try {
      await _platformClassifier.loadModel();
      if (!mounted) return;
      setState(() {
        _modelLoadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _modelLoadError =
            'The TensorFlow Lite model could not be loaded. '
            'Use simulation controls for display-only testing, then restart the app.';
      });
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
    final adapter = ref.read(heartBpmAdapterProvider);

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

  void _onAccelSourceChanged(AccelSource source) {
    setState(() {
      _accelSource = source;
      _startSensorSubscription();
    });
  }

  void _onBpmSourceChanged(BpmSource source) {
    setState(() {
      _bpmSource = source;
      _forceSimulate = source == BpmSource.simulation;
      _connectToSelectedSource();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the ViewModel
    final viewModel = ref.watch(activityClassifierViewModelProvider);

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
            TrackerWatchLiveBanner(
              watchLiveConnected: _watchLiveConnected,
              watchLiveBpm: _watchLiveBpm,
              isStartingWatchListener: _isStartingWatchListener,
              watchListenerError: _watchListenerError,
            ),
            if (_watchListenerError != null) ...[
              const SizedBox(height: 8),
              TrackerWatchListenerError(
                message: _watchListenerError!,
                isStartingWatchListener: _isStartingWatchListener,
                onRetry: _retryWatchListener,
              ),
            ],
            if (_modelLoadError != null) ...[
              const SizedBox(height: 8),
              TrackerModelLoadError(message: _modelLoadError!),
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

            // Source selection + simulation controls
            TrackerSourceControls(
              accelSource: _accelSource,
              bpmSource: _bpmSource,
              currentBpmValue: _currentBpmValue,
              simulatedHr: _simulatedHR,
              forceSimulate: _forceSimulate,
              accelAmplitude: _accelAmplitude,
              accelFreqHz: _accelFreqHz,
              onAccelSourceChanged: _onAccelSourceChanged,
              onBpmSourceChanged: _onBpmSourceChanged,
              onForceSimulateChanged: (v) => setState(() => _forceSimulate = v),
              onSimulatedHrChanged: (val) => setState(() => _simulatedHR = val),
              onAccelAmplitudeChanged: (v) =>
                  setState(() => _accelAmplitude = v),
              onAccelFreqHzChanged: (v) => setState(() => _accelFreqHz = v),
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
            TrackerStatusCard(
              accelSource: _accelSource,
              bpmSource: _bpmSource,
              pluginAvailable: _pluginAvailable,
              currentBpmValue: _currentBpmValue,
              simulatedHr: _simulatedHR,
              bufferLength: _dataBuffer.length,
              windowSize: _windowSize,
            ),

            // Bottom padding for scrolling
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatProb(double p) => (p * 100).toStringAsFixed(1);
}
