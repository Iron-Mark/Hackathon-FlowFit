# Design Document: Advanced Sensor Integration

## Overview

This design extends FlowFit's sensor capabilities by integrating three key technologies:

1. **WearOS Sensors Library** - Provides unified access to IMU sensors (accelerometer, gyroscope), GPS, and concurrent sensor data collection with background support
2. **Android SensorManager** - Native access to environmental sensors (barometer for altitude, ambient light sensor)
3. **Complications API** - WearOS API for displaying health data on any watch face

The design maintains compatibility with the existing Samsung Health Sensor SDK integration while adding complementary sensor data streams. All sensor data will flow through a unified architecture that handles collection, processing, synchronization, and error recovery.

### Key Design Goals

- Extend existing sensor architecture without breaking Samsung Health SDK integration
- Provide automatic activity detection using IMU sensor fusion
- Enable outdoor activity tracking with GPS and altitude monitoring
- Optimize battery usage through intelligent sensor management
- Expose health metrics to watch faces via Complications API
- Maintain robust error handling and data synchronization

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      FlowFit Watch App                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Unified Sensor Manager (Dart)                 │  │
│  │  - Coordinates all sensor streams                     │  │
│  │  - Manages sensor lifecycle                           │  │
│  │  - Handles data buffering & sync                      │  │
│  └──────────────────────────────────────────────────────┘  │
│           │              │              │                    │
│           ▼              ▼              ▼                    │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────┐         │
│  │   Samsung   │ │   WearOS    │ │   Native     │         │
│  │   Health    │ │   Sensors   │ │   Sensors    │         │
│  │   Bridge    │ │   Bridge    │ │   Bridge     │         │
│  └─────────────┘ └─────────────┘ └──────────────┘         │
│           │              │              │                    │
└───────────┼──────────────┼──────────────┼────────────────────┘
            │              │              │
            ▼              ▼              ▼
┌───────────────────────────────────────────────────────────┐
│              Native Android Layer (Kotlin)                 │
├───────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │   Samsung    │  │   WearOS     │  │  SensorManager  │ │
│  │   Health     │  │   Sensors    │  │   (Barometer,   │ │
│  │   Sensor SDK │  │   Library    │  │   Light)        │ │
│  └──────────────┘  └──────────────┘  └─────────────────┘ │
└───────────────────────────────────────────────────────────┘
            │              │              │
            ▼              ▼              ▼
┌───────────────────────────────────────────────────────────┐
│                    Hardware Sensors                        │
│  Heart Rate │ Accelerometer │ Gyroscope │ GPS │ Barometer │
└───────────────────────────────────────────────────────────┘
```


### Data Flow

1. **Sensor Collection**: Multiple sensor streams collect data concurrently
2. **Data Processing**: Raw sensor data is processed and classified (activity detection, altitude calculation)
3. **Local Buffering**: Processed data is buffered locally on the watch
4. **Synchronization**: Data syncs to phone when connection is available
5. **Cloud Upload**: Phone app uploads to Supabase for long-term storage
6. **Complication Updates**: Real-time data is exposed to watch faces

## Components and Interfaces

### 1. Unified Sensor Manager (Dart)

Central coordinator for all sensor operations.

```dart
class UnifiedSensorManager {
  final WatchBridgeService _samsungHealthBridge;
  final WearOSSensorsBridge _wearOsSensorsBridge;
  final NativeSensorsBridge _nativeSensorsBridge;
  final SensorDataBuffer _dataBuffer;
  
  // Sensor state
  bool _isTracking = false;
  ActivityType _currentActivity = ActivityType.idle;
  
  // Start all sensors
  Future<bool> startAllSensors();
  
  // Stop all sensors
  Future<void> stopAllSensors();
  
  // Get unified sensor stream
  Stream<UnifiedSensorData> get sensorDataStream;
  
  // Activity detection
  Stream<ActivityType> get activityStream;
  
  // Battery optimization
  void optimizeSensorUsage(BatteryLevel level);
}
```

### 2. WearOS Sensors Bridge (Dart)

Interface to WearOS Sensors library for IMU and GPS data.

```dart
class WearOSSensorsBridge {
  static const MethodChannel _channel = 
      MethodChannel('com.flowfit.wearos_sensors');
  
  // Start accelerometer tracking
  Future<bool> startAccelerometer({
    Duration interval = const Duration(milliseconds: 100),
  });
  
  // Start gyroscope tracking
  Future<bool> startGyroscope({
    Duration interval = const Duration(milliseconds: 100),
  });
  
  // Start GPS tracking
  Future<bool> startGPS({
    Duration interval = const Duration(seconds: 5),
  });
  
  // Get sensor data streams
  Stream<AccelerometerData> get accelerometerStream;
  Stream<GyroscopeData> get gyroscopeStream;
  Stream<GPSData> get gpsStream;
  
  // Stop sensors
  Future<void> stopAccelerometer();
  Future<void> stopGyroscope();
  Future<void> stopGPS();
}
```


### 3. Native Sensors Bridge (Dart)

Interface to Android SensorManager for environmental sensors.

```dart
class NativeSensorsBridge {
  static const MethodChannel _channel = 
      MethodChannel('com.flowfit.native_sensors');
  
  // Start barometer tracking
  Future<bool> startBarometer({
    Duration interval = const Duration(seconds: 1),
  });
  
  // Start ambient light sensor
  Future<bool> startAmbientLight({
    Duration interval = const Duration(seconds: 1),
  });
  
  // Get sensor data streams
  Stream<BarometerData> get barometerStream;
  Stream<AmbientLightData> get ambientLightStream;
  
  // Stop sensors
  Future<void> stopBarometer();
  Future<void> stopAmbientLight();
}
```

### 4. Activity Detector

Analyzes IMU sensor data to classify activity type and intensity.

```dart
class ActivityDetector {
  // Process accelerometer and gyroscope data
  ActivityType detectActivity({
    required List<AccelerometerData> accelData,
    required List<GyroscopeData> gyroData,
  });
  
  // Calculate activity intensity (0.0 to 1.0)
  double calculateIntensity(List<AccelerometerData> accelData);
  
  // Detect stationary state
  bool isStationary(List<AccelerometerData> accelData);
}
```

### 5. Altitude Calculator

Converts barometer pressure readings to altitude.

```dart
class AltitudeCalculator {
  // Calculate altitude from pressure
  double calculateAltitude(double pressureHPa);
  
  // Calculate elevation gain/loss
  double calculateElevationChange({
    required double startAltitude,
    required double endAltitude,
  });
  
  // Smooth altitude readings
  double smoothAltitude(List<double> altitudeReadings);
}
```

### 6. Sensor Data Buffer

Local storage for sensor data before synchronization.

```dart
class SensorDataBuffer {
  // Add data to buffer
  void addData(UnifiedSensorData data);
  
  // Get buffered data
  List<UnifiedSensorData> getBufferedData();
  
  // Clear buffer after successful sync
  void clearBuffer();
  
  // Check buffer capacity
  bool isBufferFull();
  
  // Get oldest data for deletion
  List<UnifiedSensorData> getOldestData(int count);
}
```


### 7. Complications Data Source

Provides health data to watch faces via WearOS Complications API.

```kotlin
class FlowFitComplicationService : ComplicationDataSourceService() {
    
    override fun onComplicationRequest(
        request: ComplicationRequest,
        listener: ComplicationRequestListener
    ) {
        val complicationType = request.complicationType
        
        when (complicationType) {
            ComplicationType.SHORT_TEXT -> {
                // Provide heart rate
                val data = ShortTextComplicationData.Builder(
                    text = PlainComplicationText.Builder("72 BPM").build(),
                    contentDescription = PlainComplicationText
                        .Builder("Heart Rate").build()
                ).build()
                listener.onComplicationData(data)
            }
            ComplicationType.LONG_TEXT -> {
                // Provide activity status
                val data = LongTextComplicationData.Builder(
                    text = PlainComplicationText.Builder("Walking - Moderate").build(),
                    contentDescription = PlainComplicationText
                        .Builder("Activity Status").build()
                ).build()
                listener.onComplicationData(data)
            }
            else -> {
                listener.onComplicationData(null)
            }
        }
    }
    
    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        // Provide preview data for watch face picker
        return when (type) {
            ComplicationType.SHORT_TEXT -> {
                ShortTextComplicationData.Builder(
                    text = PlainComplicationText.Builder("72 BPM").build(),
                    contentDescription = PlainComplicationText
                        .Builder("Heart Rate").build()
                ).build()
            }
            else -> null
        }
    }
}
```

### 8. Native Sensor Managers (Kotlin)

#### WearOS Sensors Manager

```kotlin
class WearOSSensorsManager(
    private val context: Context,
    private val onAccelData: (AccelData) -> Unit,
    private val onGyroData: (GyroData) -> Unit,
    private val onGPSData: (GPSData) -> Unit,
    private val onError: (String, String?) -> Unit
) {
    private var isCollecting = false
    
    fun startAccelerometer(intervalMs: Long): Boolean
    fun startGyroscope(intervalMs: Long): Boolean
    fun startGPS(intervalSeconds: Long): Boolean
    
    fun stopAccelerometer()
    fun stopGyroscope()
    fun stopGPS()
    
    fun stopAll()
}
```

#### Native Sensors Manager

```kotlin
class NativeSensorsManager(
    private val context: Context,
    private val onBarometerData: (BarometerData) -> Unit,
    private val onLightData: (LightData) -> Unit,
    private val onError: (String, String?) -> Unit
) {
    private val sensorManager: SensorManager
    private var barometerSensor: Sensor?
    private var lightSensor: Sensor?
    
    fun startBarometer(intervalMs: Long): Boolean
    fun startAmbientLight(intervalMs: Long): Boolean
    
    fun stopBarometer()
    fun stopAmbientLight()
    
    fun stopAll()
}
```


## Data Models

### UnifiedSensorData

Combines data from all sensor sources with unified timestamp.

```dart
class UnifiedSensorData {
  final DateTime timestamp;
  final HeartRateData? heartRate;
  final AccelerometerData? accelerometer;
  final GyroscopeData? gyroscope;
  final GPSData? gps;
  final BarometerData? barometer;
  final AmbientLightData? ambientLight;
  final ActivityType? detectedActivity;
  final double? activityIntensity;
  
  UnifiedSensorData({
    required this.timestamp,
    this.heartRate,
    this.accelerometer,
    this.gyroscope,
    this.gps,
    this.barometer,
    this.ambientLight,
    this.detectedActivity,
    this.activityIntensity,
  });
  
  Map<String, dynamic> toJson();
  factory UnifiedSensorData.fromJson(Map<String, dynamic> json);
}
```

### AccelerometerData

```dart
class AccelerometerData {
  final double x;  // m/s²
  final double y;  // m/s²
  final double z;  // m/s²
  final DateTime timestamp;
  
  AccelerometerData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });
  
  // Calculate magnitude
  double get magnitude => sqrt(x * x + y * y + z * z);
  
  Map<String, dynamic> toJson();
  factory AccelerometerData.fromJson(Map<String, dynamic> json);
}
```

### GyroscopeData

```dart
class GyroscopeData {
  final double x;  // rad/s
  final double y;  // rad/s
  final double z;  // rad/s
  final DateTime timestamp;
  
  GyroscopeData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });
  
  // Calculate angular velocity magnitude
  double get magnitude => sqrt(x * x + y * y + z * z);
  
  Map<String, dynamic> toJson();
  factory GyroscopeData.fromJson(Map<String, dynamic> json);
}
```

### GPSData

```dart
class GPSData {
  final double latitude;
  final double longitude;
  final double? altitude;  // meters
  final double? accuracy;  // meters
  final double? speed;     // m/s
  final double? bearing;   // degrees
  final DateTime timestamp;
  
  GPSData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.bearing,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson();
  factory GPSData.fromJson(Map<String, dynamic> json);
}
```

