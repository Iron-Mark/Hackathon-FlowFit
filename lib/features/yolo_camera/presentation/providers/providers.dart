import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:flowfit/features/yolo_camera/domain/repositories/yolo_repository.dart';
import 'package:flowfit/features/yolo_camera/data/repositories/yolo_repository_impl.dart';
import 'package:flowfit/features/yolo_camera/domain/usecases/detect_object_usecase.dart';
import 'package:flowfit/features/yolo_camera/domain/usecases/detect_pose_usecase.dart';
import 'package:flowfit/features/yolo_camera/domain/usecases/detect_image_usecase.dart';
import 'package:flowfit/features/yolo_camera/domain/entities/detection_result.dart';

// Repository Provider
final yoloRepositoryProvider = Provider<YoloRepository>((ref) {
  return YoloRepositoryImpl();
});

// Use Case Providers
final detectObjectUseCaseProvider = Provider<DetectObjectUseCase>((ref) {
  final repository = ref.watch(yoloRepositoryProvider);
  return DetectObjectUseCase(repository);
});

final detectPoseUseCaseProvider = Provider<DetectPoseUseCase>((ref) {
  final repository = ref.watch(yoloRepositoryProvider);
  return DetectPoseUseCase(repository);
});

final detectImageUseCaseProvider = Provider<DetectImageUseCase>((ref) {
  final repository = ref.watch(yoloRepositoryProvider);
  return DetectImageUseCase(repository);
});

// State for Detection Results
final detectionResultsProvider = StateProvider<List<DetectionResult>>(
  (ref) => [],
);

// Camera Controller Provider
final cameraDescriptionProvider = FutureProvider<List<CameraDescription>>((
  ref,
) async {
  return availableCameras();
});
