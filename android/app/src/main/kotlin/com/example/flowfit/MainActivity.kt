package com.example.flowfit

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import android.view.MotionEvent
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.EventChannel
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.Wearable
import com.samsung.wearable_rotary.WearableRotaryPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.json.JSONArray
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }
    
    private val CHANNEL = "com.flowfit.watch/data"
    private val EVENT_CHANNEL = "com.flowfit.watch/heartrate"
    private val TRANSMISSION_EVENT_CHANNEL = "com.flowfit.watch/transmission"
    private val PERMISSION_REQUEST_CODE = 1001
    
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var heartRateEventSink: EventChannel.EventSink? = null
    private var transmissionEventSink: EventChannel.EventSink? = null
    private var healthTrackingManager: HealthTrackingManager? = null
    private var watchToPhoneSyncManager: WatchToPhoneSyncManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(Dispatchers.Main)
    
    private var lastHeartRateData: Map<String, Any?>? = null

    // Foreground Wearable message listener — receives watch messages when app is in foreground.
    // This is more reliable than WearableListenerService on devices with aggressive battery saving.
    private val wearableMessageListener = MessageClient.OnMessageReceivedListener { event ->
        Log.i(TAG, "📨 Direct Wearable message received: path=${event.path}")
        val jsonData = String(event.data, Charsets.UTF_8)
        try {
            when (event.path) {
                "/heart_rate" -> {
                    Log.i(TAG, "💓 HR data (direct): $jsonData")
                    val map = parseJsonToMap(jsonData)
                    mainHandler.post { PhoneDataListenerService.eventSink?.success(map) }
                }
                "/sensor_data" -> {
                    Log.i(TAG, "📊 Sensor batch (direct): ${jsonData.take(80)}...")
                    val map = parseJsonToMap(jsonData)
                    mainHandler.post { PhoneDataListenerService.sensorBatchEventSink?.success(map) }
                }
                else -> Log.d(TAG, "Unhandled direct message path: ${event.path}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling direct Wearable message", e)
        }
    }

    // Wake lock to keep tracking when screen is off
    private var wakeLock: PowerManager.WakeLock? = null
    private var isTrackingActive = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Make background transparent for round screens (VGV best practice)
        intent.putExtra("background_mode", "transparent")
        super.onCreate(savedInstanceState)
        
        // Keep screen on during tracking (will be managed by start/stop)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        // Initialize wake lock
        initializeWakeLock()
        
        // Initialize health tracking manager
        initializeHealthTracking()
    }
    
    /**
     * Initialize wake lock to keep CPU running when screen is off
     * This ensures heart rate tracking continues even when screen turns off
     */
    private fun initializeWakeLock() {
        try {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "FlowFit::HeartRateTracking"
            ).apply {
                // Set reference counted to false so we can manually control it
                setReferenceCounted(false)
            }
            Log.i(TAG, "Wake lock initialized")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize wake lock", e)
        }
    }
    
    /**
     * Acquire wake lock to keep tracking active
     */
    private fun acquireWakeLock() {
        try {
            if (wakeLock?.isHeld == false) {
                wakeLock?.acquire(10*60*1000L /*10 minutes*/)
                Log.i(TAG, "Wake lock acquired - tracking will continue with screen off")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire wake lock", e)
        }
    }
    
    /**
     * Release wake lock when tracking stops
     */
    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                Log.i(TAG, "Wake lock released")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release wake lock", e)
        }
    }
    
    private fun initializeHealthTracking() {
        // CRITICAL: Use applicationContext instead of 'this' (activity context)
        // This ensures the HealthTrackingService survives activity lifecycle changes
        healthTrackingManager = HealthTrackingManager(
            context = applicationContext,  // KEY CHANGE: Use Application context
            onHeartRateData = { data ->
                // Convert to map for Flutter
                val dataMap = mapOf(
                    "bpm" to data.bpm,
                    "ibiValues" to data.ibiValues,
                    "timestamp" to data.timestamp,
                    "status" to data.status
                )
                
                // Store last reading
                lastHeartRateData = dataMap
                
                // Send to Flutter via event channel
                mainHandler.post {
                    heartRateEventSink?.success(dataMap)
                }
            },
            onError = { code, message ->
                Log.e(TAG, "Health tracking error: $code - $message")
                mainHandler.post {
                    heartRateEventSink?.error(code, message, null)
                }
            },
            onTransmission = {
                // Notify Flutter about sensor batch transmission
                mainHandler.post {
                    transmissionEventSink?.success(mapOf(
                        "timestamp" to System.currentTimeMillis()
                    ))
                }
            }
        )
        
        // Initialize watch-to-phone sync manager (also use application context)
        watchToPhoneSyncManager = WatchToPhoneSyncManager(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Ensure plugins are registered explicitly here to avoid runtime registration errors
        // (Sometimes plugins fail to register when AAR metadata causes issues at build time.)
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (e: Exception) {
            Log.w(TAG, "GeneratedPluginRegistrant.registerWith failed, continuing: ${'$'}e")
        }
                // Geofence method and event channels for native background integration
                MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.flowfit.geofence/native").setMethodCallHandler { call, result ->
                    when (call.method) {
                        "registerGeofence" -> {
                            // Arguments: id, latitude, longitude, radius
                            val id = call.argument<String>("id")
                            val lat = call.argument<Double>("lat")
                            val lon = call.argument<Double>("lon")
                            val radius = call.argument<Double>("radius")
                            // TODO: Register platform geofence — stubbed for now
                            Log.i(TAG, "Geofence register called: $id @ $lat,$lon ($radius m)")
                            result.success(true)
                        }
                        "unregisterGeofence" -> {
                            val id = call.argument<String>("id")
                            // TODO: unregister platform geofence — stubbed
                            Log.i(TAG, "Geofence unregister called: $id")
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                }

                EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.flowfit.geofence/events").setStreamHandler(
                    object : EventChannel.StreamHandler {
                        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                            // Store event sink to send geofence enter/exit notifications from native side
                            // TODO: wire with actual geofence manager
                            Log.i(TAG, "Geofence event sink registered")
                        }

                        override fun onCancel(arguments: Any?) {
                            Log.i(TAG, "Geofence event sink cancelled")
                        }
                    }
                )
        
        // Samsung Health Sensor method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> requestPermission(result)
                "checkPermission" -> checkPermission(result)
                "connectWatch" -> connectWatch(result)
                "disconnectWatch" -> disconnectWatch(result)
                "isWatchConnected" -> isWatchConnected(result)
                "startHeartRate" -> startHeartRate(result)
                "stopHeartRate" -> stopHeartRate(result)
                "getCurrentHeartRate" -> getCurrentHeartRate(result)
                "getTestModeData" -> getTestModeData(result)
                else -> result.notImplemented()
            }
        }
        
        // Watch-to-Phone sync method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.flowfit.watch/sync").setMethodCallHandler { call, result ->
            when (call.method) {
                "sendHeartRateToPhone" -> sendHeartRateToPhone(call, result)
                "sendBatchToPhone" -> sendBatchToPhone(result)
                "checkPhoneConnection" -> checkPhoneConnection(result)
                "getConnectedNodesCount" -> getConnectedNodesCount(result)
                else -> result.notImplemented()
            }
        }
        
        // Heart rate event channel for streaming data (watch side)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    heartRateEventSink = events
                }
                
                override fun onCancel(arguments: Any?) {
                    heartRateEventSink = null
                }
            }
        )
        
        // Transmission event channel for sensor batch transmission notifications
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, TRANSMISSION_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    transmissionEventSink = events
                    Log.i(TAG, "Transmission event sink registered")
                }
                
                override fun onCancel(arguments: Any?) {
                    transmissionEventSink = null
                    Log.i(TAG, "Transmission event sink cancelled")
                }
            }
        )
        
        // Phone data listener method channel (phone side - control listening)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.flowfit.phone/data").setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    // The PhoneDataListenerService is already running as a background service
                    // Just confirm it's ready to receive data
                    Log.i(TAG, "Phone data listener start requested")
                    result.success(true)
                }
                "stopListening" -> {
                    Log.i(TAG, "Phone data listener stop requested")
                    result.success(null)
                }
                "isWatchConnected" -> {
                    // Check if we have any connected nodes via WatchToPhoneSyncManager
                    scope.launch {
                        try {
                            val count = watchToPhoneSyncManager?.getConnectedNodesCount() ?: 0
                            val connected = count > 0
                            mainHandler.post {
                                result.success(connected)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error checking watch connection", e)
                            mainHandler.post {
                                result.success(false)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Phone data listener event channel (phone side - receives from watch)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.flowfit.phone/heartrate").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    PhoneDataListenerService.eventSink = events
                    Log.i(TAG, "Phone data listener event sink registered")
                }
                
                override fun onCancel(arguments: Any?) {
                    PhoneDataListenerService.eventSink = null
                    Log.i(TAG, "Phone data listener event sink cancelled")
                }
            }
        )
        
        // Sensor batch event channel (phone side - receives accelerometer + HR batches from watch)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.flowfit.phone/sensor_data").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    PhoneDataListenerService.sensorBatchEventSink = events
                    Log.i(TAG, "Sensor batch event sink registered")
                }
                
                override fun onCancel(arguments: Any?) {
                    PhoneDataListenerService.sensorBatchEventSink = null
                    Log.i(TAG, "Sensor batch event sink cancelled")
                }
            }
        )
    }

    /**
     * Request body sensor and activity recognition permissions from the user
     * Uses health.READ_HEART_RATE for Android 15+ (BAKLAVA), BODY_SENSORS for older versions
     * Also requests ACTIVITY_RECOGNITION for accelerometer access
     * Requirements: 7.1, 7.3
     */
    private fun requestPermission(result: MethodChannel.Result) {
        try {
            // Determine which permissions to request based on Android version
            val bodySensorPermission = if (android.os.Build.VERSION.SDK_INT >= 35) { // Android 15 (BAKLAVA)
                "android.permission.health.READ_HEART_RATE"
            } else {
                Manifest.permission.BODY_SENSORS
            }
            
            val activityPermission = Manifest.permission.ACTIVITY_RECOGNITION
            
            // Check if both permissions are already granted
            val bodySensorGranted = ContextCompat.checkSelfPermission(this, bodySensorPermission) == PackageManager.PERMISSION_GRANTED
            val activityGranted = ContextCompat.checkSelfPermission(this, activityPermission) == PackageManager.PERMISSION_GRANTED
            
            if (bodySensorGranted && activityGranted) {
                // Both permissions already granted
                result.success(true)
            } else {
                // Build list of permissions to request
                val permissionsToRequest = mutableListOf<String>()
                if (!bodySensorGranted) {
                    permissionsToRequest.add(bodySensorPermission)
                }
                if (!activityGranted) {
                    permissionsToRequest.add(activityPermission)
                }
                
                // Store the result to respond after permission dialog
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(
                    this,
                    permissionsToRequest.toTypedArray(),
                    PERMISSION_REQUEST_CODE
                )
            }
        } catch (e: Exception) {
            result.error(
                "PERMISSION_ERROR",
                "Failed to request sensor permissions",
                e.message
            )
        }
    }

    /**
     * Check the current body sensor and activity recognition permission status
     * Checks health.READ_HEART_RATE for Android 15+, BODY_SENSORS for older versions
     * Also checks ACTIVITY_RECOGNITION for accelerometer access
     * Returns "granted" only if both permissions are granted
     * Requirements: 7.1, 7.3
     */
    private fun checkPermission(result: MethodChannel.Result) {
        try {
            // Determine which permission to check based on Android version
            val bodySensorPermission = if (android.os.Build.VERSION.SDK_INT >= 35) { // Android 15 (BAKLAVA)
                "android.permission.health.READ_HEART_RATE"
            } else {
                Manifest.permission.BODY_SENSORS
            }
            
            val activityPermission = Manifest.permission.ACTIVITY_RECOGNITION
            
            // Check both permissions
            val bodySensorStatus = ContextCompat.checkSelfPermission(this, bodySensorPermission)
            val activityStatus = ContextCompat.checkSelfPermission(this, activityPermission)
            
            // Return "granted" only if both are granted
            val status = if (bodySensorStatus == PackageManager.PERMISSION_GRANTED && 
                            activityStatus == PackageManager.PERMISSION_GRANTED) {
                "granted"
            } else if (bodySensorStatus == PackageManager.PERMISSION_DENIED || 
                      activityStatus == PackageManager.PERMISSION_DENIED) {
                // Check if we should show rationale for either permission
                val shouldShowBodySensorRationale = ActivityCompat.shouldShowRequestPermissionRationale(this, bodySensorPermission)
                val shouldShowActivityRationale = ActivityCompat.shouldShowRequestPermissionRationale(this, activityPermission)
                
                if (shouldShowBodySensorRationale || shouldShowActivityRationale) {
                    "denied"
                } else {
                    // User permanently denied or hasn't been asked yet
                    "denied"
                }
            } else {
                "notDetermined"
            }
            
            result.success(status)
        } catch (e: Exception) {
            result.error(
                "PERMISSION_ERROR",
                "Failed to check sensor permissions",
                e.message
            )
        }
    }

    /**
     * Handle permission request result
     * Returns true only if all requested permissions are granted
     * Requirements: 7.1, 7.3
     */
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            // Check if all permissions were granted
            val allGranted = grantResults.isNotEmpty() && 
                           grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            
            Log.i(TAG, "Permission request result: $allGranted (${grantResults.size} permissions)")
            pendingPermissionResult?.success(allGranted)
            pendingPermissionResult = null
        }
    }

    /**
     * Connect to Samsung Health services
     */
    private fun connectWatch(result: MethodChannel.Result) {
        val manager = healthTrackingManager
        if (manager == null) {
            result.error(
                "INITIALIZATION_ERROR",
                "Health tracking manager not initialized",
                null
            )
            return
        }
        
        try {
            // Use callback-based connection to wait for ConnectionListener
            manager.connect { success, error ->
                mainHandler.post {
                    if (success) {
                        result.success(true)
                    } else {
                        result.error(
                            "CONNECTION_FAILED",
                            error ?: "Unknown connection error",
                            null
                        )
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error connecting to watch", e)
            result.error(
                "CONNECTION_FAILED",
                "Failed to connect: ${e.message}",
                null
            )
        }
    }

    /**
     * Disconnect from Samsung Health services
     */
    private fun disconnectWatch(result: MethodChannel.Result) {
        try {
            healthTrackingManager?.disconnect()
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error disconnecting from watch", e)
            result.error(
                "DISCONNECT_ERROR",
                "Failed to disconnect: ${e.message}",
                null
            )
        }
    }

    /**
     * Check if currently connected to Samsung Health services
     */
    private fun isWatchConnected(result: MethodChannel.Result) {
        val connected = healthTrackingManager?.isConnected() ?: false
        result.success(connected)
    }

    /**
     * Start heart rate tracking
     * Acquires wake lock to keep tracking active even when screen is off
     */
    private fun startHeartRate(result: MethodChannel.Result) {
        val manager = healthTrackingManager
        if (manager == null) {
            result.error(
                "INITIALIZATION_ERROR",
                "Health tracking manager not initialized",
                null
            )
            return
        }
        
        if (!manager.isConnected()) {
            result.error(
                "NOT_CONNECTED",
                "Not connected to Health Tracking Service",
                null
            )
            return
        }
        
        try {
            val started = manager.startTracking()
            if (started) {
                isTrackingActive = true
                // Acquire wake lock to keep tracking when screen is off
                acquireWakeLock()
                Log.i(TAG, "Heart rate tracking started with wake lock")
            }
            result.success(started)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting heart rate tracking", e)
            result.error(
                "TRACKING_ERROR",
                "Failed to start tracking: ${e.message}",
                null
            )
        }
    }

    /**
     * Stop heart rate tracking
     * Releases wake lock to save battery
     */
    private fun stopHeartRate(result: MethodChannel.Result) {
        try {
            healthTrackingManager?.stopTracking()
            isTrackingActive = false
            // Release wake lock when tracking stops
            releaseWakeLock()
            Log.i(TAG, "Heart rate tracking stopped, wake lock released")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping heart rate tracking", e)
            result.error(
                "TRACKING_ERROR",
                "Failed to stop tracking: ${e.message}",
                null
            )
        }
    }

    /**
     * Get the current/last heart rate reading
     */
    private fun getCurrentHeartRate(result: MethodChannel.Result) {
        result.success(lastHeartRateData)
    }

    /**
     * Get test mode data for debugging
     * Requirements: 8.5
     */
    private fun getTestModeData(result: MethodChannel.Result) {
        val manager = healthTrackingManager
        if (manager == null) {
            result.error(
                "INITIALIZATION_ERROR",
                "Health tracking manager not initialized",
                null
            )
            return
        }
        
        try {
            // Access the sensor service through reflection or add a getter
            // For now, we'll create a simple data structure
            val testData = mutableMapOf<String, Any?>()
            
            // Get heart rate data
            testData["heartRate"] = lastHeartRateData?.get("bpm")
            testData["heartRateStatus"] = lastHeartRateData?.get("status")
            
            // Get accelerometer data from the sensor service
            // We need to expose this through the HealthTrackingManager
            val sensorServiceField = manager.javaClass.getDeclaredField("sensorService")
            sensorServiceField.isAccessible = true
            val sensorService = sensorServiceField.get(manager) as? WatchSensorService
            
            if (sensorService != null) {
                val latestReading = sensorService.getLatestReading()
                testData["accelerometerX"] = latestReading?.accX
                testData["accelerometerY"] = latestReading?.accY
                testData["accelerometerZ"] = latestReading?.accZ
                testData["bufferSize"] = sensorService.getBufferSize()
                testData["timeSinceLastTransmission"] = sensorService.getTimeSinceLastTransmission()
                testData["isTracking"] = sensorService.isTracking()
            } else {
                testData["accelerometerX"] = null
                testData["accelerometerY"] = null
                testData["accelerometerZ"] = null
                testData["bufferSize"] = 0
                testData["timeSinceLastTransmission"] = 0
                testData["isTracking"] = false
            }
            
            result.success(testData)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting test mode data", e)
            result.error(
                "TEST_MODE_ERROR",
                "Failed to get test mode data: ${e.message}",
                null
            )
        }
    }

    // Support for rotary input (rotating bezel on Galaxy Watch)
    override fun onGenericMotionEvent(event: MotionEvent?): Boolean {
        return when {
            WearableRotaryPlugin.onGenericMotionEvent(event) -> true
            else -> super.onGenericMotionEvent(event)
        }
    }
    
    /**
     * Send heart rate data to phone
     */
    private fun sendHeartRateToPhone(call: MethodCall, result: MethodChannel.Result) {
        val syncManager = watchToPhoneSyncManager
        if (syncManager == null) {
            result.error(
                "SYNC_ERROR",
                "Sync manager not initialized",
                null
            )
            return
        }

        val jsonData = call.argument<String>("data")
        if (jsonData == null) {
            result.error(
                "INVALID_DATA",
                "No data provided",
                null
            )
            return
        }

        syncManager.sendHeartRateToPhone(jsonData) { success ->
            mainHandler.post {
                result.success(success)
            }
        }
    }

    /**
     * Send batch data to phone
     * Retrieves all collected TrackedData and sends as JSON array
     */
    private fun sendBatchToPhone(result: MethodChannel.Result) {
        val manager = healthTrackingManager
        if (manager == null) {
            result.error(
                "MANAGER_ERROR",
                "Health tracking manager not initialized",
                null
            )
            return
        }
        
        val syncManager = watchToPhoneSyncManager
        if (syncManager == null) {
            result.error(
                "SYNC_ERROR",
                "Sync manager not initialized",
                null
            )
            return
        }

        scope.launch {
            try {
                // Get all valid HR data
                val data = manager.getValidHrData()
                
                if (data.isEmpty()) {
                    Log.w(TAG, "No data to send")
                    mainHandler.post {
                        result.success(false)
                    }
                    return@launch
                }
                
                // Serialize to JSON
                val json = Json.encodeToString(data)
                Log.i(TAG, "Sending batch of ${data.size} measurements to phone")
                
                // Send via sync manager
                syncManager.sendBatchToPhone(json) { success ->
                    mainHandler.post {
                        if (success) {
                            Log.i(TAG, "Batch sent successfully")
                        } else {
                            Log.e(TAG, "Failed to send batch")
                        }
                        result.success(success)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error sending batch", e)
                mainHandler.post {
                    result.error("BATCH_ERROR", e.message, null)
                }
            }
        }
    }

    /**
     * Check if phone is connected
     */
    private fun checkPhoneConnection(result: MethodChannel.Result) {
        val syncManager = watchToPhoneSyncManager
        if (syncManager == null) {
            result.success(false)
            return
        }

        scope.launch {
            try {
                val connected = syncManager.checkPhoneConnection()
                mainHandler.post {
                    result.success(connected)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking phone connection", e)
                mainHandler.post {
                    result.success(false)
                }
            }
        }
    }

    /**
     * Get connected nodes count
     */
    private fun getConnectedNodesCount(result: MethodChannel.Result) {
        val syncManager = watchToPhoneSyncManager
        if (syncManager == null) {
            result.success(0)
            return
        }

        scope.launch {
            try {
                val count = syncManager.getConnectedNodesCount()
                mainHandler.post {
                    result.success(count)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error getting connected nodes count", e)
                mainHandler.post {
                    result.success(0)
                }
            }
        }
    }

    /**
     * Helper to parse a JSON string into a Map for Flutter EventChannel.
     * Mirrors the parsing in PhoneDataListenerService.
     */
    private fun parseJsonToMap(jsonString: String): Map<String, Any?> {
        val obj = JSONObject(jsonString)
        return obj.toFlatMap()
    }

    private fun JSONObject.toFlatMap(): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        keys().forEach { key ->
            map[key] = when (val v = get(key)) {
                is JSONObject -> v.toFlatMap()
                is JSONArray  -> v.toFlatList()
                JSONObject.NULL -> null
                else -> v
            }
        }
        return map
    }

    private fun JSONArray.toFlatList(): List<Any?> {
        val list = mutableListOf<Any?>()
        for (i in 0 until length()) {
            list.add(when (val v = get(i)) {
                is JSONObject -> v.toFlatMap()
                is JSONArray  -> v.toFlatList()
                JSONObject.NULL -> null
                else -> v
            })
        }
        return list
    }

    /**
     * Handle onPause lifecycle event
     * Keep tracking active but log the state.
     * Also unregister foreground Wearable listener.
     */
    override fun onPause() {
        try {
            Wearable.getMessageClient(this).removeListener(wearableMessageListener)
            Log.i(TAG, "Foreground Wearable listener unregistered")
        } catch (e: Exception) {
            Log.w(TAG, "Could not unregister Wearable listener: ${e.message}")
        }
        super.onPause()
        if (isTrackingActive) {
            Log.i(TAG, "Activity paused but tracking continues with wake lock")
        }
    }

    /**
     * Handle onResume lifecycle event
     * Refresh wake lock if tracking is active.
     * Also register foreground Wearable listener so watch messages are received reliably.
     */
    override fun onResume() {
        super.onResume()
        try {
            Wearable.getMessageClient(this).addListener(wearableMessageListener)
            Log.i(TAG, "✅ Foreground Wearable listener registered — will receive watch messages directly")
        } catch (e: Exception) {
            Log.w(TAG, "Could not register Wearable listener: ${e.message}")
        }
        if (isTrackingActive) {
            acquireWakeLock()
            Log.i(TAG, "Activity resumed, wake lock refreshed")
        }
    }
    
    /**
     * Handle onDestroy lifecycle event
     * Complete cleanup of resources
     */
    override fun onDestroy() {
        super.onDestroy()
        // Release wake lock
        releaseWakeLock()
        // Clean up health tracking
        healthTrackingManager?.disconnect()
        healthTrackingManager = null
        // Clean up sync manager
        watchToPhoneSyncManager = null
        // Clean up event sink
        heartRateEventSink = null
        Log.i(TAG, "Activity destroyed, all resources cleaned up")
    }
}