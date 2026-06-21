import 'package:flutter/material.dart';
import '../../presentation/widgets/yolo_camera_widget.dart';
import '../../domain/entities/detection_result.dart';

typedef YoloDebugCameraBuilder =
    Widget Function(
      BuildContext context,
      DetectionMode detectionMode,
      CameraMode cameraMode,
      ValueChanged<List<DetectionResult>> onDetection,
    );

class YoloDebugScreen extends StatefulWidget {
  const YoloDebugScreen({super.key, this.cameraBuilder});

  final YoloDebugCameraBuilder? cameraBuilder;

  @override
  State<YoloDebugScreen> createState() => _YoloDebugScreenState();
}

class _YoloDebugScreenState extends State<YoloDebugScreen>
    with WidgetsBindingObserver {
  DetectionMode _detectionMode = DetectionMode.object;
  CameraMode _cameraMode = CameraMode.realtime;
  List<DetectionResult> _latestResults = [];
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🟢 YoloDebugScreen: initState called');
  }

  @override
  void dispose() {
    debugPrint('🔴 YoloDebugScreen: dispose called');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🔄 YoloDebugScreen: App lifecycle changed to $state');
    super.didChangeAppLifecycleState(state);
  }

  @override
  void deactivate() {
    debugPrint('⚠️ YoloDebugScreen: deactivate called');
    super.deactivate();
  }

  void _handleError(String error) {
    debugPrint('❌ YoloDebugScreen: Error occurred: $error');
    if (!mounted || (_hasError && _errorMessage == error)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = error;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔨 YoloDebugScreen: build called');

    return PopScope<Object?>(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          debugPrint('⬅️ YoloDebugScreen: Back button pressed');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('YOLO Debug Preview'),
          backgroundColor: _hasError ? Colors.red : null,
          actions: [
            if (_hasError)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                  });
                },
                tooltip: 'Clear Error',
              ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showInfo,
            ),
          ],
        ),
        body: _hasError
            ? _buildErrorView()
            : Column(
                children: [
                  // Control Panel
                  _buildControlPanel(),

                  // Camera/Detection View
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        try {
                          void handleDetection(List<DetectionResult> results) {
                            debugPrint(
                              '📊 YoloDebugScreen: Received ${results.length} detections',
                            );
                            if (mounted) {
                              setState(() {
                                _latestResults = results;
                              });
                            }
                          }

                          final cameraBuilder = widget.cameraBuilder;
                          if (cameraBuilder != null) {
                            return cameraBuilder(
                              context,
                              _detectionMode,
                              _cameraMode,
                              handleDetection,
                            );
                          }

                          return YoloCameraWidget(
                            detectionMode: _detectionMode,
                            cameraMode: _cameraMode,
                            onDetection: handleDetection,
                          );
                        } catch (e, stackTrace) {
                          debugPrint(
                            '💥 YoloDebugScreen: Error building camera widget: $e',
                          );
                          debugPrint('Stack trace: $stackTrace');
                          _handleError('Camera error: $e');
                          return _buildErrorView();
                        }
                      },
                    ),
                  ),

                  // Results Panel
                  _buildResultsPanel(),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'An Error Occurred',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: SelectableText(
                        _errorMessage ?? 'Unknown error',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        debugPrint(
                          '🏠 YoloDebugScreen: Navigating back to home',
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detection Mode',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<DetectionMode>(
                  segments: const [
                    ButtonSegment(
                      value: DetectionMode.object,
                      label: Text('Object'),
                      icon: Icon(Icons.category),
                    ),
                    ButtonSegment(
                      value: DetectionMode.pose,
                      label: Text('Pose unavailable'),
                      icon: Icon(Icons.accessibility_new),
                      enabled: false,
                    ),
                  ],
                  selected: {_detectionMode},
                  onSelectionChanged: (Set<DetectionMode> newSelection) {
                    setState(() {
                      _detectionMode = newSelection.first;
                      _latestResults = []; // Clear results on mode change
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Camera Mode',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<CameraMode>(
                  segments: const [
                    ButtonSegment(
                      value: CameraMode.realtime,
                      label: Text('Real-time'),
                      icon: Icon(Icons.videocam),
                    ),
                    ButtonSegment(
                      value: CameraMode.singleShot,
                      label: Text('Picture'),
                      icon: Icon(Icons.photo_camera),
                    ),
                  ],
                  selected: {_cameraMode},
                  onSelectionChanged: (Set<CameraMode> newSelection) {
                    setState(() {
                      _cameraMode = newSelection.first;
                      _latestResults = []; // Clear results on mode change
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Detections: ${_latestResults.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _latestResults.isEmpty
                ? const Center(
                    child: Text(
                      'No detections yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _latestResults.length,
                    itemBuilder: (context, index) {
                      final result = _latestResults[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              result.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(result.confidence * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('YOLO Debug Info'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detection Modes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Object: YOLOv11s model'),
            Text('• Pose: unavailable until a compatible pose model is added'),
            SizedBox(height: 16),
            Text(
              'Camera Modes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Real-time: Live camera stream'),
            Text('• Picture: Select from gallery'),
            SizedBox(height: 16),
            Text(
              'Note: This screen is only visible in debug mode.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
