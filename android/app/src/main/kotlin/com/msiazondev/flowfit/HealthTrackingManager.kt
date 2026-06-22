package com.msiazondev.flowfit

import android.content.Context
import android.util.Log
import com.samsung.android.service.health.tracking.ConnectionListener
import com.samsung.android.service.health.tracking.HealthTracker
import com.samsung.android.service.health.tracking.HealthTrackerException
import com.samsung.android.service.health.tracking.HealthTrackingService
import com.samsung.android.service.health.tracking.data.DataPoint
import com.samsung.android.service.health.tracking.data.HealthTrackerType
import com.samsung.android.service.health.tracking.data.ValueKey

/**
 * Simplified Manager for Samsung Health Tracking Service
 * Handles heart rate tracking and data streaming
 */
class HealthTrackingManager(
    private val context: Context,
    private val onHeartRateData: (HeartRateData) -> Unit,
    private val onError: (String, String?) -> Unit,
    private val onTransmission: (() -> Unit)? = null
) {
    companion object {
        private const val TAG = "HealthTrackingManager"
        
        // Heart rate status codes
        private const val HR_STATUS_VALID = 1
        private const val IBI_STATUS_VALID = 0
        
        // Maximum number of data points to store
        private const val MAX_DATA_POINTS = 40
    }

    private var healthTrackingService: HealthTrackingService? = null
    private var heartRateTracker: HealthTracker? = null
    private var isTracking = false

    private var isServiceConnected = false
    private var connectionCallback: ((Boolean, String?) -> Unit)? = null
    
    // Batch data collection
    private val validHrData = ArrayList<TrackedData>()
    
    // Accelerometer sensor service for activity classification
    private val sensorService: WatchSensorService = WatchSensorService(context, onTransmission)

    /**
     * Connection listener for Samsung Health Tracking Service
     * Implements the proper ConnectionListener interface as per Samsung SDK requirements
     */
    private val connectionListener = object : ConnectionListener {
        override fun onConnectionSuccess() {
            Log.i(TAG, "✅ Health Tracking Service connected successfully")
            isServiceConnected = true
            
            // Check capabilities AFTER connection succeeds
            val hasCapability = hasHeartRateCapability()
            if (hasCapability) {
                Log.i(TAG, "✅ Heart rate tracking is supported")
                connectionCallback?.invoke(true, null)
            } else {
                Log.e(TAG, "❌ Heart rate tracking is not supported on this device")
                connectionCallback?.invoke(false, "Heart rate tracking not available")
            }
            connectionCallback = null
        }

        override fun onConnectionEnded() {
            Log.i(TAG, "Health Tracking Service connection ended")
            isServiceConnected = false
            
            // FIX 3: Notify callback if waiting
            connectionCallback?.invoke(false, "Connection ended")
            connectionCallback = null
            
            healthTrackingService = null
        }

        override fun onConnectionFailed(error: HealthTrackerException?) {
            val errorMsg = error?.message ?: "Unknown connection error"
            Log.e(TAG, "❌ Health Tracking Service connection failed: $errorMsg")
            isServiceConnected = false
            connectionCallback?.invoke(false, errorMsg)
            connectionCallback = null
            healthTrackingService = null
        }
    }

    /**
     * Connect to Samsung Health Tracking Service
     * Uses callback pattern to wait for ConnectionListener callbacks
     */
    fun connect(callback: (Boolean, String?) -> Unit) {
        try {
            val appContext = context.applicationContext
            
            Log.i(TAG, "🔄 Attempting to connect to Health Tracking Service")
            Log.i(TAG, "📱 Using context type: ${appContext.javaClass.simpleName}")
            
            // FIX 1: Check if already connected
            if (isServiceConnected && healthTrackingService != null) {
                Log.i(TAG, "✅ Already connected to Health Tracking Service")
                // Verify connection is still valid
                try {
                    val hasCapability = hasHeartRateCapability()
                    if (hasCapability) {
                        Log.i(TAG, "✅ Connection validated, returning success")
                        callback(true, null)
                        return
                    } else {
                        Log.w(TAG, "⚠️ Connection exists but capabilities check failed, reconnecting...")
                        // Fall through to reconnect
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "⚠️ Connection exists but validation failed: ${e.message}, reconnecting...")
                    // Fall through to reconnect
                }
            }
            
            // FIX 2: Disconnect any existing service first
            if (healthTrackingService != null) {
                Log.w(TAG, "⚠️ Existing service found, disconnecting first...")
                try {
                    stopTracking() // Stop any active tracking
                    healthTrackingService?.disconnectService()
                } catch (e: Exception) {
                    Log.w(TAG, "Error disconnecting existing service: ${e.message}")
                }
                healthTrackingService = null
            }
            
            // Reset connection state
            isServiceConnected = false
            connectionCallback = callback
            
            // Create new HealthTrackingService instance
            healthTrackingService = HealthTrackingService(connectionListener, appContext)
            
            // CRITICAL: Must explicitly call connectService() to trigger connection
            Log.i(TAG, "📡 Calling connectService() to initiate binding...")
            healthTrackingService?.connectService()
            
            Log.i(TAG, "⏳ Waiting for connection callback...")
            // Connection result will be delivered via connectionListener callbacks
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception during connection", e)
            Log.e(TAG, "❌ Exception details: ${e.javaClass.simpleName} - ${e.message}")
            callback(false, e.message)
        }
    }

    /**
     * Check if device supports heart rate tracking
     */
    private fun hasHeartRateCapability(): Boolean {
        val service = healthTrackingService ?: return false
        
        return try {
            val supportedTypes = service.trackingCapability.supportHealthTrackerTypes
            val isSupported = supportedTypes.contains(HealthTrackerType.HEART_RATE_CONTINUOUS)
            Log.d(TAG, "Heart rate continuous tracking supported: $isSupported")
            isSupported
        } catch (e: Exception) {
            Log.e(TAG, "Error checking capabilities", e)
            false
        }
    }

    /**
     * Disconnect from Samsung Health Tracking Service
     */
    fun disconnect() {
        Log.i(TAG, "Disconnecting from Health Tracking Service")
        
        try {
            stopTracking()
            healthTrackingService?.disconnectService()
            healthTrackingService = null
        } catch (e: Exception) {
            Log.e(TAG, "Error during disconnect", e)
        }
    }

    /**
     * Check if currently connected
     */
    fun isConnected(): Boolean {
        return healthTrackingService != null
    }

    /**
     * Start heart rate tracking
     */
    fun startTracking(): Boolean {
        if (isTracking) {
            Log.w(TAG, "Already tracking heart rate")
            return true
        }

        val service = healthTrackingService
        if (service == null) {
            Log.e(TAG, "Cannot start tracking: not connected to service")
            onError("SERVICE_UNAVAILABLE", "Not connected to Health Tracking Service")
            return false
        }

        return try {
            Log.i(TAG, "Starting heart rate tracking")
            
            // Get heart rate tracker
            heartRateTracker = service.getHealthTracker(HealthTrackerType.HEART_RATE_CONTINUOUS)
            
            // Set up event listener
            heartRateTracker?.setEventListener(trackerEventListener)
            
            isTracking = true
            Log.i(TAG, "Heart rate tracking started successfully")
            
            // Start accelerometer tracking after heart rate starts successfully
            // Requirements: 1.5 - Handle accelerometer unavailable
            try {
                sensorService.startTracking()
                Log.i(TAG, "Accelerometer tracking started successfully")
            } catch (e: AccelerometerUnavailableException) {
                Log.w(TAG, "Accelerometer not available on this device: ${e.message}")
                // Continue with heart rate only - don't fail the entire operation
                onError("ACCELEROMETER_UNAVAILABLE", "Accelerometer sensor not available. Continuing with heart rate only.")
            } catch (e: SensorInitializationException) {
                Log.e(TAG, "Failed to initialize accelerometer: ${e.message}", e)
                // Continue with heart rate only - don't fail the entire operation
                // Requirements: 6.5 - Handle sensor initialization failures
                onError("SENSOR_INITIALIZATION_FAILED", "Failed to initialize accelerometer. Continuing with heart rate only.")
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error starting accelerometer tracking: ${e.message}", e)
                // Continue with heart rate only - don't fail the entire operation
                onError("ACCELEROMETER_ERROR", "Accelerometer error: ${e.message}. Continuing with heart rate only.")
            }
            
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start heart rate tracking", e)
            onError("TRACKING_FAILED", e.message)
            false
        }
    }

    /**
     * Stop heart rate tracking
     */
    fun stopTracking() {
        if (!isTracking) {
            Log.d(TAG, "Not currently tracking")
            return
        }

        try {
            Log.i(TAG, "Stopping heart rate tracking")
            heartRateTracker?.unsetEventListener()
            heartRateTracker = null
            isTracking = false
            Log.i(TAG, "Heart rate tracking stopped")
            
            // Stop accelerometer tracking when heart rate stops
            try {
                sensorService.stopTracking()
                Log.i(TAG, "Accelerometer tracking stopped")
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping accelerometer tracking", e)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping heart rate tracking", e)
        }
    }

    /**
     * Event listener for heart rate data
     */
    private val trackerEventListener = object : HealthTracker.TrackerEventListener {
        override fun onDataReceived(dataPoints: MutableList<DataPoint>) {
            for (dataPoint in dataPoints) {
                try {
                    processDataPoint(dataPoint)
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing data point", e)
                }
            }
        }

        override fun onFlushCompleted() {
            Log.d(TAG, "Tracker flush completed")
        }

        override fun onError(trackerError: HealthTracker.TrackerError?) {
            val errorMsg = trackerError?.toString() ?: "Unknown tracker error"
            Log.e(TAG, "Tracker error: $errorMsg")
            onError("TRACKER_ERROR", errorMsg)
        }
    }

    /**
     * Process a single data point from the tracker
     */
    private fun processDataPoint(dataPoint: DataPoint) {
        // Extract heart rate
        val hrValue = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE) as? Int
        val hrStatus = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE_STATUS) as? Int
        
        // Extract IBI (inter-beat interval) data
        val ibiList = getValidIbiList(dataPoint)
        
        // Validate HR status and store in batch collection
        if (isHRValid(hrStatus) && hrValue != null) {
            val trackedData = TrackedData(
                hr = hrValue,
                ibi = ArrayList(ibiList)
            )
            
            // Add to batch collection
            synchronized(validHrData) {
                validHrData.add(trackedData)
                trimDataList()
            }
            
            // Update sensor service with latest heart rate value
            sensorService.currentHeartRate = hrValue
            
            Log.d(TAG, "Valid HR data stored: $hrValue bpm, ${ibiList.size} IBI values (total: ${validHrData.size})")
        }
        
        // Also send to Flutter for real-time display (regardless of validity for monitoring)
        val heartRateData = HeartRateData(
            bpm = if (isHRValid(hrStatus)) hrValue else null,
            ibiValues = ibiList,
            timestamp = System.currentTimeMillis(),
            status = if (isHRValid(hrStatus)) "active" else "inactive"
        )
        
        onHeartRateData(heartRateData)
    }
    
    /**
     * Validate heart rate status
     * @param status Heart rate status code from sensor
     * @return true if status indicates valid measurement
     */
    private fun isHRValid(status: Int?): Boolean {
        return status == HR_STATUS_VALID
    }
    
    /**
     * Trim data list to maintain maximum size
     * Removes oldest entries when size exceeds MAX_DATA_POINTS
     */
    private fun trimDataList() {
        while (validHrData.size > MAX_DATA_POINTS) {
            validHrData.removeAt(0)
        }
    }
    
    /**
     * Get all valid heart rate data collected
     * @return ArrayList of TrackedData measurements
     */
    fun getValidHrData(): ArrayList<TrackedData> {
        synchronized(validHrData) {
            return ArrayList(validHrData)
        }
    }
    
    /**
     * Clear all collected data
     */
    fun clearValidHrData() {
        synchronized(validHrData) {
            validHrData.clear()
        }
    }

    /**
     * Extract valid IBI values from data point
     */
    private fun getValidIbiList(dataPoint: DataPoint): List<Int> {
        return try {
            val ibiValues = dataPoint.getValue(ValueKey.HeartRateSet.IBI_LIST) as? IntArray
            val ibiStatuses = dataPoint.getValue(ValueKey.HeartRateSet.IBI_STATUS_LIST) as? IntArray
            
            if (ibiValues == null || ibiStatuses == null) {
                return emptyList()
            }
            
            val validIbiList = mutableListOf<Int>()
            for (i in ibiValues.indices) {
                if (i < ibiStatuses.size && 
                    ibiStatuses[i] == IBI_STATUS_VALID && 
                    ibiValues[i] != 0) {
                    validIbiList.add(ibiValues[i])
                }
            }
            
            validIbiList
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting IBI values", e)
            emptyList()
        }
    }
}

/**
 * Data class for heart rate information
 */
data class HeartRateData(
    val bpm: Int?,
    val ibiValues: List<Int>,
    val timestamp: Long,
    val status: String
)
