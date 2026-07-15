export 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier_native.dart'
    if (dart.library.html) 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier_web.dart'
    if (dart.library.js_interop) 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier_web.dart';
