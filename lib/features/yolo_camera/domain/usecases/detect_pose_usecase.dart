import 'package:camera/camera.dart';
import 'package:flowfit/features/yolo_camera/domain/entities/detection_result.dart';
import 'package:flowfit/features/yolo_camera/domain/repositories/yolo_repository.dart';

class DetectPoseUseCase {
  final YoloRepository _repository;

  DetectPoseUseCase(this._repository);

  Future<List<DetectionResult>> call(CameraImage image) {
    return _repository.detectPose(image);
  }
}
