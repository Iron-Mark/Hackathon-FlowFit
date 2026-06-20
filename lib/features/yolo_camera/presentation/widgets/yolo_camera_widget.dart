import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/providers.dart';
import 'detection_overlay_widget.dart';
import '../../domain/entities/detection_result.dart';

enum DetectionMode { object, pose }

enum CameraMode { realtime, singleShot }

typedef YoloGalleryImagePicker = Future<String?> Function();
typedef YoloImageByteReader = Future<Uint8List> Function(String path);

class YoloCameraWidget extends ConsumerStatefulWidget {
  final DetectionMode detectionMode;
  final CameraMode cameraMode;
  final Function(List<DetectionResult>)? onDetection;
  final YoloGalleryImagePicker? pickImage;
  final YoloImageByteReader? readImageBytes;

  const YoloCameraWidget({
    super.key,
    this.detectionMode = DetectionMode.object,
    this.cameraMode = CameraMode.realtime,
    this.onDetection,
    this.pickImage,
    this.readImageBytes,
  });

  @override
  ConsumerState<YoloCameraWidget> createState() => _YoloCameraWidgetState();
}

class _YoloCameraWidgetState extends ConsumerState<YoloCameraWidget>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isDetecting = false;
  bool _isPickingImage = false;
  bool _isInitialized = false;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.cameraMode == CameraMode.realtime) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant YoloCameraWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detectionMode != widget.detectionMode &&
        widget.cameraMode == CameraMode.realtime) {
      _reinitializeDetector();
    }
    if (oldWidget.cameraMode != widget.cameraMode) {
      if (widget.cameraMode == CameraMode.realtime) {
        _initializeCamera();
      } else {
        _controller?.dispose();
        setState(() {
          _isInitialized = false;
          _controller = null;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed &&
        widget.cameraMode == CameraMode.realtime) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await ref.read(cameraDescriptionProvider.future);
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      // Initialize detector separately with error handling
      try {
        await _reinitializeDetector();
      } catch (e) {
        debugPrint('Error initializing detector (continuing anyway): $e');
        // Continue even if detector fails - camera will still work
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startImageStream();
      }
    } catch (e, stackTrace) {
      debugPrint('Error initializing camera: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _reinitializeDetector() async {
    try {
      final repo = ref.read(yoloRepositoryProvider);
      if (widget.detectionMode == DetectionMode.object) {
        await repo.initObjectDetector();
      } else {
        await repo.initPoseDetector();
      }
    } catch (e) {
      debugPrint('Detector initialization failed: $e');
      rethrow; // Let caller handle it
    }
  }

  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('Cannot start image stream - controller not initialized');
      return;
    }

    _controller!.startImageStream((CameraImage image) async {
      if (_isDetecting || !mounted) return;
      _isDetecting = true;

      try {
        List<DetectionResult> results = [];

        try {
          if (widget.detectionMode == DetectionMode.object) {
            results = await ref.read(detectObjectUseCaseProvider).call(image);
          } else {
            results = await ref.read(detectPoseUseCaseProvider).call(image);
          }
        } catch (detectionError) {
          // Log but don't crash - just skip this frame
          debugPrint('Detection error (skipping frame): $detectionError');
        }

        if (mounted && results.isNotEmpty) {
          ref.read(detectionResultsProvider.notifier).state = results;
          widget.onDetection?.call(results);
        }
      } catch (e) {
        debugPrint('Image stream error: $e');
      } finally {
        if (mounted) {
          _isDetecting = false;
        }
      }
    });
  }

  Future<void> _pickAndDetectImage() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final imagePath = await (widget.pickImage ?? _defaultPickImage)();

      if (imagePath == null || !mounted) return;

      final selectedImage = File(imagePath);
      setState(() {
        _capturedImage = selectedImage;
      });

      // Read image bytes
      final imageBytes =
          await (widget.readImageBytes ?? _defaultReadImageBytes)(imagePath);

      // Run detection
      final useCase = ref.read(detectImageUseCaseProvider);
      List<DetectionResult> results;
      if (widget.detectionMode == DetectionMode.object) {
        results = await useCase.detectObjects(imageBytes);
      } else {
        results = await useCase.detectPose(imageBytes);
      }

      if (mounted) {
        ref.read(detectionResultsProvider.notifier).state = results;
        widget.onDetection?.call(results);
      }
    } catch (e) {
      debugPrint('Error picking/detecting image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not analyze image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<String?> _defaultPickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile?.path;
  }

  Future<Uint8List> _defaultReadImageBytes(String path) {
    return File(path).readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(detectionResultsProvider);

    if (widget.cameraMode == CameraMode.singleShot) {
      return _buildSingleShotMode(results);
    }

    if (!_isInitialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        DetectionOverlayWidget(results: results),
      ],
    );
  }

  Widget _buildSingleShotMode(List<DetectionResult> results) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_capturedImage != null)
          Image.file(_capturedImage!, fit: BoxFit.contain)
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.photo_library, size: 80, color: Colors.white54),
            ),
          ),
        if (_capturedImage != null) DetectionOverlayWidget(results: results),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _isPickingImage ? null : _pickAndDetectImage,
              icon: const Icon(Icons.photo_library),
              label: Text(
                _isPickingImage
                    ? 'Analyzing...'
                    : (_capturedImage == null ? 'Pick Image' : 'Pick Another'),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
