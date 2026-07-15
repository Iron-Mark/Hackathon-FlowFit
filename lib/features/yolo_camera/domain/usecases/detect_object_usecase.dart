import 'package:camera/camera.dart';
import 'package:flowfit/features/yolo_camera/domain/entities/detection_result.dart';
import 'package:flowfit/features/yolo_camera/domain/repositories/yolo_repository.dart';

class DetectObjectUseCase {
  final YoloRepository _repository;

  DetectObjectUseCase(this._repository);

  Future<List<DetectionResult>> call(CameraImage image) {
    return _repository.detectObjects(image);
  }
}
