# YOLO Camera Feature Integration Guide

This guide explains how to integrate the reusable YOLO Camera widget into your application.

## Overview

The `YoloCameraWidget` is a flexible widget that supports:
- Real-time object and pose detection using camera stream
- Single-shot detection from gallery images
- Automatic lifecycle management
- Dynamic mode switching

## Prerequisites

### 1. Android Asset Placement
Place your `.tflite` model files in `android/app/src/main/assets/`:
- `android/app/src/main/assets/yolov11s_food.tflite`
- `android/app/src/main/assets/yolov11n_pose.tflite`

**Important**: The models must be `.tflite` files (TensorFlow Lite format).

### 2. Model Files
The repository is configured to use:
- `yolov11s_food.tflite` for Object Detection ✅ **Working**
- `yolov11n_pose.tflite` for Pose Detection

**⚠️ Pose Model Compatibility:**
The `ultralytics_yolo` plugin expects pose models with **17 keypoints** (COCO format).
If you get an error like `Unexpected output feature size. Expected=56, Actual=50`, your pose model is incompatible.

**Solution:** Use YOLOv8/v11 pose models with 17 keypoints:
```bash
pip install ultralytics
python -c "from ultralytics import YOLO; YOLO('yolov8n-pose.pt').export(format='tflite')"
# Rename the exported file to yolov11n_pose.tflite
```

These names are referenced in the code without the `.tflite` extension.

## Usage

### 1. Import
```dart
import 'package:flowfit/features/yolo_camera/presentation/widgets/yolo_camera_widget.dart';
```

### 2. Real-time Detection
```dart
YoloCameraWidget(
  detectionMode: DetectionMode.object, // or DetectionMode.pose
  cameraMode: CameraMode.realtime,
  onDetection: (results) {
    print('Detected ${results.length} objects');
  },
)
```

### 3. Picture Mode
```dart
YoloCameraWidget(
  detectionMode: DetectionMode.pose,
  cameraMode: CameraMode.singleShot,
  onDetection: (results) {
    // Process results from picked image
  },
)
```

## Debug Preview

For testing, use the debug screen (visible only in debug builds):

```dart
import 'package:flowfit/features/yolo_camera/presentation/screens/yolo_debug_screen.dart';

// Add to your routes or navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const YoloDebugScreen()),
);
```

### Adding to main.dart (Debug Only)

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: kDebugMode ? const YoloDebugScreen() : const YourMainScreen(),
    );
  }
}
```

## Architecture

- **Domain Layer**: `DetectionResult` entity, repository interfaces, use cases.
- **Data Layer**: `YoloRepositoryImpl` with camera image processing and static image support.
- **Presentation Layer**: `YoloCameraWidget` with dual-mode support.

## Customization

- **Models**: Update names in `lib/features/yolo_camera/data/repositories/yolo_repository_impl.dart`.
- **Overlay**: Modify `lib/features/yolo_camera/presentation/widgets/detection_overlay_widget.dart`.

## Current Status

✅ **Object Detection**: Working perfectly with `yolov11s_food.tflite`
⚠️ **Pose Detection**: Requires compatible model (17 keypoints COCO format)
✅ **Camera**: Stable, no crashes
✅ **Debug Screen**: Stays open indefinitely in debug mode
