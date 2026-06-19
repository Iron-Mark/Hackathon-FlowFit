# YOLO Model Setup Checklist

## Issue
Error: `Error during prediction: yolov11s_food`

This means the model file cannot be found or loaded.

## Solution Steps

### 1. Verify Model Files Exist
Check that these files exist in your Android assets:
```
android/app/src/main/assets/yolov11s_food.tflite
android/app/src/main/assets/yolov11n_pose.tflite
```

### 2. File Format
- Files MUST be `.tflite` format (TensorFlow Lite)
- The ultralytics_yolo package expects `.tflite` files

### 3. Verify Asset Registration
Check that your models are accessible. You may need to add to `android/app/build.gradle.kts`:
```kotlin
android {
    ...
    aaptOptions {
        noCompress("tflite")
    }
}
```

### 4. Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

## Current Configuration
The code expects:
- Object detection: `yolov11s_food.tflite`
- Pose detection: `yolov11n_pose.tflite`

Both in `android/app/src/main/assets/`

## How to Get Models

Download YOLOv11 TFLite models from Ultralytics:
```bash
# Or export from PyTorch models
pip install ultralytics
python -c "from ultralytics import YOLO; YOLO('yolov11s.pt').export(format='tflite')"
python -c "from ultralytics import YOLO; YOLO('yolov11n-pose.pt').export(format='tflite')"
```
