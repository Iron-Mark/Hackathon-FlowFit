export 'tflite_activity_classifier_native.dart'
    if (dart.library.html) 'tflite_activity_classifier_web.dart'
    if (dart.library.js_interop) 'tflite_activity_classifier_web.dart';
