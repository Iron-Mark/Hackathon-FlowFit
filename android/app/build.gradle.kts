plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.0"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flowfit"
    compileSdk = 36  // Use Android 15 (API 36) - required by plugins
    ndkVersion = "28.0.13004108"  // Updated to match ultralytics_yolo requirement

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Enable core library desugaring to support libraries that require newer java APIs
        isCoreLibraryDesugaringEnabled = true
    }

    lint {
        checkReleaseBuilds = false
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flowfit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 30  // Required for Wear OS 3.0+ and Samsung Health Sensor API (article recommends 23, but 30 needed for Samsung Health)
        targetSdk = 36  // Use Android 15 (API 36) - required by plugins
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Samsung Health Sensor API
    implementation(files("libs/samsung-health-sensor-api-1.4.1.aar"))
    
    // AndroidX Health Services Client
    implementation("androidx.health:health-services-client:1.0.0-beta03")
    
    // Wear OS libraries
    implementation("androidx.wear:wear:1.3.0")
    implementation("com.google.android.support:wearable:2.9.0")
    // Include the Wearable runtime dependency at runtime so classes (e.g. WearableActivityController)
    // are present when plugins such as wearable_rotary or wear access them at runtime.
    implementation("com.google.android.wearable:wearable:2.9.0")
    
    // Wearable Data Layer API for watch-phone communication
    implementation("com.google.android.gms:play-services-wearable:18.1.0")
    
    // Kotlin Coroutines for async operations
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")
    
    // Kotlin Serialization for JSON encoding/decoding
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
    // Enable the desugaring support library for plugin compatibility (e.g., flutter_local_notifications)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}