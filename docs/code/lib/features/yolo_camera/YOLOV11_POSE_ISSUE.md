# YOLOv11 vs YOLOv8 Pose Format Incompatibility

## The Problem

Your `yolov11n_pose.tflite` model is **incompatible** with the `ultralytics_yolo` Flutter plugin (v0.1.40).

### Error:
```
java.lang.IllegalArgumentException: Unexpected output feature size. Expected=56, Actual=50
```

## Why This Happens

### Plugin Expectation (YOLOv8 Format):
The Flutter plugin was built for **YOLOv8-pose** models:
- **17 keypoints** (COCO format: nose, eyes, ears, shoulders, elbows, wrists, hips, knees, ankles)
- Each keypoint has: `[x, y, confidence]` = 3 values
- Plus bounding box: `[x, y, w, h, conf]` = 5 values
- **Total**: (17 × 3) + 5 = **56 features**

### Your Model (YOLOv11 Format):
YOLOv11n-pose outputs:
- **50 features** (different output structure)
- YOLOv11 changed the output format from YOLOv8
- The coordinates are relative to bounding boxes (not absolute)
- Different post-processing requirements

## Why It Works on PC But Not Mobile

- **PC (Python)**: The Ultralytics Python library supports both YOLOv8 and YOLOv11 formats
- **Mobile (Flutter)**: The `ultralytics_yolo` plugin (v0.1.40) only supports YOLOv8 format
- The plugin hasn't been updated for YOLOv11's new output structure yet

## Solutions

### ✅ Solution 1: Use YOLOv8-pose (Recommended)
Export a YOLOv8-pose model instead:

```bash
pip install ultralytics
python -c "from ultralytics import YOLO; YOLO('yolov8n-pose.pt').export(format='tflite')"
```

Then:
1. Rename the exported file to `yolov11n_pose.tflite`
2. Replace the file in `android/app/src/main/assets/`
3. Uncomment the pose detector code in `yolo_repository_impl.dart`

### ✅ Solution 2: Disable Pose Detection (Current)
We've temporarily disabled pose detection:
- Object detection works perfectly
- Switching to pose mode will show a warning but won't crash
- You can still use all object detection features

### ⏳ Solution 3: Wait for Plugin Update
The `ultralytics_yolo` plugin may be updated to support YOLOv11 format in the future.

## Current Status

✅ **Object Detection**: Fully functional with `yolov11s_food.tflite`
⚠️ **Pose Detection**: Disabled due to model incompatibility
✅ **App Stability**: No crashes, graceful degradation

## Technical Details

### YOLOv8-pose Output:
```
[x, y, w, h, conf, kp1_x, kp1_y, kp1_conf, kp2_x, kp2_y, kp2_conf, ...]
 └─ 5 bbox values ─┘ └────────────── 17 keypoints × 3 ──────────────┘
                                    = 56 total features
```

### YOLOv11-pose Output:
```
[Different structure with 50 features]
- Relative coordinates (normalized to bbox)
- Different keypoint encoding
- Requires different post-processing
```

## Recommendation

**Use YOLOv8n-pose** for now. It's:
- ✅ Compatible with the Flutter plugin
- ✅ Well-tested and stable
- ✅ Similar performance to YOLOv11n
- ✅ Same 17 keypoints (COCO format)

The performance difference between YOLOv8n and YOLOv11n is minimal for mobile use cases.
