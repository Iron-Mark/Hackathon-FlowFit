import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:image/image.dart' as img;
import '../../domain/entities/detection_result.dart';
import '../../domain/repositories/yolo_repository.dart';

class YoloRepositoryImpl implements YoloRepository {
  YOLO? _objectDetector;
  YOLO? _poseDetector;

  final String _objectModelPath = 'yolov11s_food';

  @override
  Future<void> initObjectDetector() async {
    if (_objectDetector != null) return;

    _objectDetector = YOLO(
      modelPath: _objectModelPath,
      useMultiInstance: true,
      useGpu: false,
      task: YOLOTask.detect,
    );
    await _objectDetector!.loadModel();
  }

  @override
  Future<void> initPoseDetector() async {
    if (_poseDetector != null) return;

    // TODO: Pose detection disabled - YOLOv11n-pose format incompatible with plugin
    // The plugin expects 56 features (17 keypoints × 3 + 5 bbox)
    // YOLOv11n-pose outputs 50 features (different format)
    // Solution: Use YOLOv8n-pose instead or update plugin
    debugPrint('⚠️ Pose detection disabled - incompatible model format');
    return;

    // Commented out until compatible model is available
    // _poseDetector = YOLO(modelPath: 'yolov11n_pose', task: YOLOTask.pose);
    // await _poseDetector!.loadModel();
  }

  @override
  Future<List<DetectionResult>> detectObjects(CameraImage image) async {
    if (_objectDetector == null) return [];

    try {
      // Convert CameraImage to Uint8List
      final imageBytes = await _convertCameraImageToBytes(image);

      // Run prediction
      final results = await _objectDetector!.predict(imageBytes);

      // Parse results
      final boxes = results['boxes'] as List<dynamic>? ?? [];
      return _parseDetectionResults(boxes);
    } catch (e) {
      debugPrint('Object detection error: $e');
      return [];
    }
  }

  @override
  Future<List<DetectionResult>> detectPose(CameraImage image) async {
    if (_poseDetector == null) return [];

    try {
      // Convert CameraImage to Uint8List
      final imageBytes = await _convertCameraImageToBytes(image);

      // Run prediction
      final results = await _poseDetector!.predict(imageBytes);

      // Parse results - pose results might be in 'poses' or 'boxes' depending on model
      final poses =
          results['poses'] as List<dynamic>? ??
          results['boxes'] as List<dynamic>? ??
          [];
      return _parseDetectionResults(poses, isPose: true);
    } catch (e) {
      debugPrint('Pose detection error: $e');
      return [];
    }
  }

  @override
  Future<List<DetectionResult>> detectFromImageBytes(
    Uint8List imageBytes, {
    required bool isObjectDetection,
  }) async {
    try {
      final detector = isObjectDetection ? _objectDetector : _poseDetector;

      if (detector == null) {
        // Initialize if not already done
        if (isObjectDetection) {
          await initObjectDetector();
        } else {
          await initPoseDetector();
        }
      }

      final activeDetector = isObjectDetection
          ? _objectDetector
          : _poseDetector;
      if (activeDetector == null) return [];

      // Run prediction directly on image bytes
      final results = await activeDetector.predict(imageBytes);

      // Parse results
      if (isObjectDetection) {
        final boxes = results['boxes'] as List<dynamic>? ?? [];
        return _parseDetectionResults(boxes);
      } else {
        final poses =
            results['poses'] as List<dynamic>? ??
            results['boxes'] as List<dynamic>? ??
            [];
        return _parseDetectionResults(poses, isPose: true);
      }
    } catch (e) {
      debugPrint('Static image detection error: $e');
      return [];
    }
  }

  /// Converts CameraImage (YUV format) to JPEG bytes for YOLO prediction
  Future<Uint8List> _convertCameraImageToBytes(CameraImage image) async {
    try {
      // Convert YUV420 to RGB
      final img.Image rgbImage = _convertYUV420ToImage(image);

      // Encode to JPEG
      final jpegBytes = Uint8List.fromList(
        img.encodeJpg(rgbImage, quality: 85),
      );

      return jpegBytes;
    } catch (e) {
      debugPrint('Image conversion error: $e');
      rethrow;
    }
  }

  /// Converts YUV420 CameraImage to RGB Image
  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = cameraImage.planes[0].bytes[index];
        final up = cameraImage.planes[1].bytes[uvIndex];
        final vp = cameraImage.planes[2].bytes[uvIndex];

        // Convert YUV to RGB
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  /// Parses detection results from YOLO output to DetectionResult entities
  List<DetectionResult> _parseDetectionResults(
    List<dynamic> results, {
    bool isPose = false,
  }) {
    return results.map((r) {
      try {
        final label =
            r['class'] as String? ?? r['className'] as String? ?? 'Unknown';
        final confidence = (r['confidence'] as num?)?.toDouble() ?? 0.0;

        // Parse bounding box - YOLO returns x, y, width, height
        // We need to convert to normalized [x1, y1, x2, y2]
        final x = (r['x'] as num?)?.toDouble() ?? 0.0;
        final y = (r['y'] as num?)?.toDouble() ?? 0.0;
        final w = (r['width'] as num?)?.toDouble() ?? 0.0;
        final h = (r['height'] as num?)?.toDouble() ?? 0.0;

        // Convert to normalized coordinates [0..1]
        // Assuming the model returns absolute pixel coordinates
        final bbox = [x, y, x + w, y + h];

        // Parse keypoints for pose detection
        List<List<double>>? keypoints;
        if (isPose && r.containsKey('keypoints')) {
          final kps = r['keypoints'] as List<dynamic>? ?? [];
          keypoints = kps.map((kp) {
            final x = (kp['x'] as num?)?.toDouble() ?? 0.0;
            final y = (kp['y'] as num?)?.toDouble() ?? 0.0;
            final conf = (kp['confidence'] as num?)?.toDouble() ?? 0.0;
            return [x, y, conf];
          }).toList();
        }

        return DetectionResult(
          label: label,
          confidence: confidence,
          bbox: bbox,
          keypoints: keypoints,
        );
      } catch (e) {
        debugPrint('Error parsing detection result: $e');
        return DetectionResult(
          label: 'Error',
          confidence: 0.0,
          bbox: [0, 0, 0, 0],
        );
      }
    }).toList();
  }

  @override
  Future<void> dispose() async {
    await _objectDetector?.dispose();
    await _poseDetector?.dispose();
    _objectDetector = null;
    _poseDetector = null;
  }
}
