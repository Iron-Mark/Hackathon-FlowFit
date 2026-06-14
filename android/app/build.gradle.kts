import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.0"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val flowfitApplicationId = providers
    .gradleProperty("FLOWFIT_ANDROID_APPLICATION_ID")
    .orElse("com.oldstlabs.flowfit")
    .get()
val flowfitAuthScheme = providers
    .gradleProperty("FLOWFIT_AUTH_SCHEME")
    .orElse(flowfitApplicationId)
    .get()
val flowfitDevAuthScheme = providers
    .gradleProperty("FLOWFIT_DEV_AUTH_SCHEME")
    .orElse("$flowfitApplicationId.dev")
    .get()

fun isProductionShapedFlowFitValue(value: String?): Boolean {
    val normalized = value?.trim().orEmpty()
    if (normalized.isBlank()) {
        return false
    }

    val lower = normalized.lowercase()
    return !(
        lower.contains("your_") ||
            lower.contains("replace_with") ||
            lower.contains("<your-") ||
            lower.contains("your-") ||
            lower.contains("your_") ||
            lower.contains("com.example.") ||
            lower.contains("com.yourcompany.") ||
            lower == "com.flowfit.smoke" ||
            lower.startsWith("com.flowfit.smoke.") ||
            lower.contains(".example.") ||
            lower.endsWith(".example") ||
            lower.contains("localhost") ||
            lower.contains("127.0.0.1") ||
            lower.contains("\$(")
    )
}

val dartDefines = providers
    .gradleProperty("dart-defines")
    .orElse("")
    .get()
    .split(",")
    .filter { it.isNotBlank() }
    .mapNotNull {
        runCatching {
            String(Base64.getDecoder().decode(it), Charsets.UTF_8)
        }.getOrNull()
    }
    .mapNotNull {
        val separator = it.indexOf('=')
        if (separator <= 0) null else it.substring(0, separator) to it.substring(separator + 1)
    }
    .toMap()

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val hasReleaseSigning = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
).all { (keystoreProperties[it] as String?)?.isNotBlank() == true }
val allowDebugReleaseSigning = providers
    .gradleProperty("FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING")
    .map { it.equals("true", ignoreCase = true) }
    .orElse(false)
    .get()

gradle.taskGraph.whenReady {
    val isReleasePackage = allTasks.any {
        it.path == ":app:bundleRelease" || it.path == ":app:assembleRelease"
    }
    val hasProductionApplicationId =
        isProductionShapedFlowFitValue(flowfitApplicationId)
    val hasProductionAuthScheme =
        isProductionShapedFlowFitValue(flowfitAuthScheme)

    if (isReleasePackage && !hasReleaseSigning && !allowDebugReleaseSigning) {
        throw GradleException(
            "Release signing is not configured. Copy android/key.properties.example " +
                "to android/key.properties and add an upload keystore, or set " +
                "Gradle property FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING=true " +
                "(or env var ORG_GRADLE_PROJECT_FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING=true) " +
                "only for local smoke builds.",
        )
    }
    if (
        isReleasePackage &&
        (!hasProductionApplicationId || !hasProductionAuthScheme) &&
        (hasReleaseSigning || !allowDebugReleaseSigning)
    ) {
        throw GradleException(
            "Release builds must not use placeholder, smoke, or example FlowFit package/auth IDs. " +
                "Set FLOWFIT_ANDROID_APPLICATION_ID and FLOWFIT_AUTH_SCHEME before building a store artifact.",
        )
    }
    if (isReleasePackage && hasReleaseSigning) {
        val dartAuthScheme = dartDefines["FLOWFIT_AUTH_SCHEME"]
        val hasProductionDartAuthScheme =
            dartAuthScheme != null &&
                dartAuthScheme == flowfitAuthScheme &&
                isProductionShapedFlowFitValue(dartAuthScheme)

        if (!hasProductionDartAuthScheme) {
            throw GradleException(
                "Signed release builds must pass matching Dart auth schemes: " +
                    "--dart-define=FLOWFIT_AUTH_SCHEME=$flowfitAuthScheme",
            )
        }
    }
}

android {
    namespace = "com.oldstlabs.flowfit"
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
        // Defaults are local-development values. Set FLOWFIT_ANDROID_APPLICATION_ID
        // for Play Store builds so the package belongs to the maintainer account.
        applicationId = flowfitApplicationId
        minSdk = 30  // Required for Wear OS 3.0+ and Samsung Health Sensor API (article recommends 23, but 30 needed for Samsung Health)
        targetSdk = 36  // Use Android 15 (API 36) - required by plugins
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["flowfitAuthScheme"] = flowfitAuthScheme
        manifestPlaceholders["flowfitDevAuthScheme"] = flowfitDevAuthScheme
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
