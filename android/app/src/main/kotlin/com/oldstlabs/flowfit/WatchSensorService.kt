package com.oldstlabs.flowfit

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import com.google.android.gms.wearable.Wearable
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Service for collecting accelerometer data and transmitting to phone
 * Collects 32 samples at ~32Hz and batches them with heart rate data
 */
class WatchSensorService(
    private val context: Context,
    private val onTransmissionCallback: (() -> Unit)? = null
) {
    companion object {
        private const val TAG = "WatchSensorService"
        private const val BUFFER_SIZE = 32
        private const val MIN_TRANSMISSION_INTERVAL_MS = 1000L
        private const val SENSOR_DATA_PATH = "/sensor_data"
        private const val SAMPLE_RATE_HZ = 32
    }

    private val sensorManager: SensorManager = 
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer: Sensor? = 
        sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    
    private val accelBuffer = mutableListOf<SensorReading>()
    private var lastSendTime: Long = 0
    
    /**
     * Current heart rate value to be included in sensor batches
     */
    var currentHeartRate: Int = 0
    
    private var isTracking = false

    /**
     * Sensor event listener for accelerometer data
     */
    private val accelListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent?) {
            event?.let {
                if (it.sensor.type == Sensor.TYPE_ACCELEROMETER) {
                    handleAccelerometerData(it)
                }
            }
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
            // Log sensor accuracy changes (Requirements 8.1)
            val accuracyStr = when (accuracy) {
                SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> "HIGH"
                SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> "MEDIUM"
                SensorManager.SENSOR_STATUS_ACCURACY_LOW -> "LOW"
                SensorManager.SENSOR_STATUS_UNRELIABLE -> "UNRELIABLE"
                else -> "UNKNOWN($accuracy)"
            }
            Log.i(TAG, "📡 Sensor accuracy changed: $accuracyStr at ${System.currentTimeMillis()}")
        }
    }

    /**
     * Start collecting accelerometer data
     * Throws AccelerometerUnavailableException if sensor is not available
     */
    fun startTracking() {
        val startTime = System.currentTimeMillis()
        
        if (isTracking) {
            Log.w(TAG, "⚠️ Already tracking accelerometer - ignoring start request")
            return
        }

        if (accelerometer == null) {
            // Log sensor error with detailed information (Requirements 8.4, 1.5)
            Log.e(TAG, "❌ SENSOR ERROR: Accelerometer not available on this device at $startTime")
            throw AccelerometerUnavailableException("Accelerometer sensor not found on this device")
        }

        // Register listener at SENSOR_DELAY_GAME (~50Hz, close to our target 32Hz)
        val registered = sensorManager.registerListener(
            accelListener,
            accelerometer,
            SensorManager.SENSOR_DELAY_GAME
        )

        if (registered) {
            isTracking = true
            lastSendTime = startTime
            // Log sensor collection event with timestamp (Requirements 8.1)
            Log.i(TAG, "🚀 Accelerometer tracking STARTED at $startTime: " +
                "target_rate=${SAMPLE_RATE_HZ}Hz, " +
                "buffer_size=$BUFFER_SIZE, " +
                "min_interval=${MIN_TRANSMISSION_INTERVAL_MS}ms")
        } else {
            // Log sensor error with detailed information (Requirements 8.4, 6.5)
            Log.e(TAG, "❌ SENSOR ERROR: Failed to register accelerometer listener at $startTime")
            throw SensorInitializationException("Failed to register accelerometer listener")
        }
    }

    /**
     * Stop collecting accelerometer data
     */
    fun stopTracking() {
        val stopTime = System.currentTimeMillis()
        
        if (!isTracking) {
            Log.d(TAG, "⚠️ Not currently tracking accelerometer - ignoring stop request")
            return
        }

        val bufferedSamples = accelBuffer.size
        sensorManager.unregisterListener(accelListener)
        accelBuffer.clear()
        isTracking = false
        
        // Log sensor collection event with timestamp (Requirements 8.1)
        Log.i(TAG, "🛑 Accelerometer tracking STOPPED at $stopTime: " +
            "discarded_samples=$bufferedSamples")
    }

    /**
     * Check if currently tracking
     */
    fun isTracking(): Boolean = isTracking

    /**
     * Get current buffer size for debugging
     * Requirements: 8.5
     */
    fun getBufferSize(): Int = synchronized(accelBuffer) { accelBuffer.size }

    /**
     * Get time since last transmission in milliseconds for debugging
     * Requirements: 8.5
     */
    fun getTimeSinceLastTransmission(): Long = System.currentTimeMillis() - lastSendTime

    /**
     * Get latest accelerometer reading for debugging
     * Requirements: 8.5
     */
    fun getLatestReading(): SensorReading? = synchronized(accelBuffer) { 
        accelBuffer.lastOrNull() 
    }

    /**
     * Handle incoming accelerometer data
     */
    private fun handleAccelerometerData(event: SensorEvent) {
        val reading = SensorReading(
            accX = event.values[0],
            accY = event.values[1],
            accZ = event.values[2],
            timestamp = System.currentTimeMillis()
        )

        synchronized(accelBuffer) {
            // Only add if buffer not full, otherwise drop samples
            if (accelBuffer.size < BUFFER_SIZE) {
                accelBuffer.add(reading)
                
                // Log sensor collection event with timestamp (Requirements 8.1)
                Log.d(TAG, "📊 Sensor collected at ${reading.timestamp}: " +
                    "X=${String.format("%.3f", reading.accX)}, " +
                    "Y=${String.format("%.3f", reading.accY)}, " +
                    "Z=${String.format("%.3f", reading.accZ)}, " +
                    "buffer=${accelBuffer.size}/$BUFFER_SIZE")
            }

            // Check if we have enough samples and enough time has passed
            if (accelBuffer.size >= BUFFER_SIZE) {
                val currentTime = System.currentTimeMillis()
                val timeSinceLastSend = currentTime - lastSendTime

                if (timeSinceLastSend >= MIN_TRANSMISSION_INTERVAL_MS) {
                    sendBatchToPhone()
                    lastSendTime = currentTime
                }
            }
        }
    }

    /**
     * Send batched sensor data to phone
     */
    private fun sendBatchToPhone() {
        if (accelBuffer.isEmpty()) {
            Log.d(TAG, "Buffer is empty, nothing to send")
            return
        }

        val transmissionStartTime = System.currentTimeMillis()
        
        try {
            // Create batch with exactly 32 samples
            val batch = synchronized(accelBuffer) {
                val samples = accelBuffer.take(BUFFER_SIZE)
                accelBuffer.clear()
                samples
            }

            // Log batch transmission details (Requirements 8.2)
            Log.i(TAG, "📤 Preparing batch transmission at $transmissionStartTime: " +
                "batch_size=${batch.size}, " +
                "bpm=$currentHeartRate, " +
                "sample_rate=${SAMPLE_RATE_HZ}Hz")

            // Create JSON packet
            val packet = SensorBatch(
                type = "sensor_batch",
                timestamp = transmissionStartTime,
                bpm = currentHeartRate,
                sampleRate = SAMPLE_RATE_HZ,
                count = batch.size,
                accelerometer = batch.map { 
                    listOf(it.accX.toDouble(), it.accY.toDouble(), it.accZ.toDouble()) 
                }
            )

            val jsonString = Json.encodeToString(packet)
            val jsonSize = jsonString.toByteArray().size
            Log.d(TAG, "📦 JSON packet created: size=${jsonSize} bytes, samples=${batch.size}")

            // Send to phone via MessageClient
            val nodeClient = Wearable.getNodeClient(context)
            nodeClient.connectedNodes.addOnSuccessListener { nodes ->
                if (nodes.isEmpty()) {
                    // Requirements: Communication errors - Handle phone disconnection
                    Log.w(TAG, "⚠️ PHONE DISCONNECTED: No connected phone nodes found - batch discarded")
                    Log.i(TAG, "📊 Continuing data collection (will discard if buffer full)")
                    return@addOnSuccessListener
                }

                // Send to first connected node (typically only one phone)
                val node = nodes.first()
                Log.d(TAG, "📱 Sending to phone node: ${node.displayName} (${node.id})")
                
                val messageClient = Wearable.getMessageClient(context)
                
                messageClient.sendMessage(
                    node.id,
                    SENSOR_DATA_PATH,
                    jsonString.toByteArray()
                ).addOnSuccessListener {
                    val transmissionTime = System.currentTimeMillis() - transmissionStartTime
                    Log.i(TAG, "✅ Batch transmission SUCCESS: " +
                        "node=${node.displayName}, " +
                        "samples=${batch.size}, " +
                        "bpm=$currentHeartRate, " +
                        "size=${jsonSize}B, " +
                        "time=${transmissionTime}ms")
                    // Notify Flutter about successful transmission
                    onTransmissionCallback?.invoke()
                }.addOnFailureListener { exception ->
                    val transmissionTime = System.currentTimeMillis() - transmissionStartTime
                    // Log sensor error with detailed information (Requirements 8.4)
                    Log.e(TAG, "❌ Batch transmission FAILED: " +
                        "node=${node.displayName}, " +
                        "samples=${batch.size}, " +
                        "bpm=$currentHeartRate, " +
                        "size=${jsonSize}B, " +
                        "time=${transmissionTime}ms, " +
                        "error=${exception.javaClass.simpleName}: ${exception.message}", 
                        exception)
                }
            }.addOnFailureListener { exception ->
                // Log sensor error with detailed information (Requirements 8.4)
                Log.e(TAG, "❌ Failed to get connected nodes: " +
                    "error=${exception.javaClass.simpleName}: ${exception.message}", 
                    exception)
            }

        } catch (e: Exception) {
            // Log sensor error with detailed information (Requirements 8.4)
            Log.e(TAG, "❌ CRITICAL ERROR in batch transmission: " +
                "error=${e.javaClass.simpleName}: ${e.message}, " +
                "buffer_size=${accelBuffer.size}, " +
                "bpm=$currentHeartRate", 
                e)
        }
    }
}

/**
 * Data class for a single accelerometer reading
 */
data class SensorReading(
    val accX: Float,
    val accY: Float,
    val accZ: Float,
    val timestamp: Long
)

/**
 * Data class for sensor batch transmission
 */
@Serializable
data class SensorBatch(
    val type: String,
    val timestamp: Long,
    val bpm: Int,
    val sampleRate: Int,
    val count: Int,
    val accelerometer: List<List<Double>>
)

/**
 * Exception thrown when accelerometer sensor is not available on the device
 * Requirements: 1.5
 */
class AccelerometerUnavailableException(message: String) : Exception(message)

/**
 * Exception thrown when sensor initialization fails
 * Requirements: 6.5
 */
class SensorInitializationException(message: String) : Exception(message)
