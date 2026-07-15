import 'dart:typed_data';
import 'package:flowfit/features/yolo_camera/domain/entities/detection_result.dart';
import 'package:flowfit/features/yolo_camera/domain/repositories/yolo_repository.dart';

class DetectImageUseCase {
  final YoloRepository _repository;

  DetectImageUseCase(this._repository);

  Future<List<DetectionResult>> detectObjects(Uint8List imageBytes) {
    return _repository.detectFromImageBytes(
      imageBytes,
      isObjectDetection: true,
    );
  }

  Future<List<DetectionResult>> detectPose(Uint8List imageBytes) {
    return _repository.detectFromImageBytes(
      imageBytes,
      isObjectDetection: false,
    );
  }
}
