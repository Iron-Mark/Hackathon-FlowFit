import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flowfit/features/yolo_camera/domain/entities/detection_result.dart';

abstract class YoloRepository {
  Future<void> initObjectDetector();
  Future<void> initPoseDetector();

  /// Detects objects in the given camera image.
  /// Returns a list of [DetectionResult].
  Future<List<DetectionResult>> detectObjects(CameraImage image);

  /// Detects pose in the given camera image.
  /// Returns a list of [DetectionResult] with keypoints.
  Future<List<DetectionResult>> detectPose(CameraImage image);

  /// Detects from static image bytes (for picture mode).
  Future<List<DetectionResult>> detectFromImageBytes(
    Uint8List imageBytes, {
    required bool isObjectDetection,
  });

  Future<void> dispose();
}
