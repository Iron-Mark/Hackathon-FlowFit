package com.oldstlabs.flowfit

import android.content.Context
import android.util.Log
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

/**
 * Manager for syncing data from watch to phone using Wearable Data Layer API
 */
class WatchToPhoneSyncManager(private val context: Context) {
    companion object {
        private const val TAG = "WatchToPhoneSync"
        private const val MESSAGE_PATH = "/heart_rate"
        private const val BATCH_PATH = "/heart_rate_batch"
        private const val CAPABILITY_NAME = "flowfit_phone_app"
    }

    private val messageClient: MessageClient by lazy {
        Wearable.getMessageClient(context)
    }

    private val capabilityClient: CapabilityClient by lazy {
        Wearable.getCapabilityClient(context)
    }

    private val nodeClient: NodeClient by lazy {
        Wearable.getNodeClient(context)
    }

    private val scope = CoroutineScope(Dispatchers.IO)

    /**
     * Send heart rate data to phone
     */
    fun sendHeartRateToPhone(jsonData: String, callback: (Boolean) -> Unit) {
        scope.launch {
            try {
                Log.i(TAG, "=== Sending heart rate data ===")
                Log.i(TAG, "Data: ${jsonData.take(100)}...")
                
                // Get connected nodes
                val nodes = getConnectedNodes()
                Log.i(TAG, "Found ${nodes.size} connected nodes")
                
                if (nodes.isEmpty()) {
                    Log.w(TAG, "No connected nodes - phone may not be paired")
                    callback(false)
                    return@launch
                }

                // Try sending to all nodes
                var success = false
                for (node in nodes) {
                    try {
                        Log.i(TAG, "Attempting send to node: ${node.id} (${node.displayName})")
                        
                        val result = messageClient
                            .sendMessage(node.id, MESSAGE_PATH, jsonData.toByteArray())
                            .await()

                        Log.i(TAG, "✓ Message sent successfully to ${node.displayName}: $result")
                        success = true
                        break // Success, no need to try other nodes
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to send to ${node.displayName}: ${e.message}")
                    }
                }

                callback(success)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send heart rate data", e)
                callback(false)
            }
        }
    }

    /**
     * Send batch of heart rate data to phone
     */
    fun sendBatchToPhone(jsonData: String, callback: (Boolean) -> Unit) {
        scope.launch {
            try {
                Log.i(TAG, "Sending batch data to phone")
                
                val nodes = getConnectedNodes()
                
                if (nodes.isEmpty()) {
                    Log.w(TAG, "No connected nodes found")
                    callback(false)
                    return@launch
                }

                val nodeId = nodes.first().id
                Log.i(TAG, "Sending batch to node: $nodeId")

                val result = messageClient
                    .sendMessage(nodeId, BATCH_PATH, jsonData.toByteArray())
                    .await()

                Log.i(TAG, "Batch sent successfully: $result")
                callback(true)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send batch data", e)
                callback(false)
            }
        }
    }

    /**
     * Check if phone is connected
     */
    suspend fun checkPhoneConnection(): Boolean {
        return try {
            Log.i(TAG, "=== Checking phone connection ===")
            
            val nodes = getConnectedNodes()
            val connected = nodes.isNotEmpty()
            
            if (connected) {
                nodes.forEach { node ->
                    Log.i(TAG, "✓ Connected node: ${node.displayName} (${node.id})")
                }
            } else {
                Log.w(TAG, "✗ No connected nodes found")
            }
            
            connected
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check phone connection", e)
            false
        }
    }

    /**
     * Get count of connected nodes
     */
    suspend fun getConnectedNodesCount(): Int {
        return try {
            val nodes = getConnectedNodes()
            Log.i(TAG, "Connected nodes count: ${nodes.size}")
            nodes.size
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get connected nodes count", e)
            0
        }
    }

    /**
     * Get list of connected nodes (phones)
     * First tries capability-based discovery, then falls back to all connected nodes
     */
    private suspend fun getConnectedNodes(): List<Node> {
        return try {
            // First, try to find nodes with our capability
            Log.i(TAG, "Attempting capability-based node discovery...")
            val capableNodes = getCapableNodes()
            
            if (capableNodes.isNotEmpty()) {
                Log.i(TAG, "Found ${capableNodes.size} capable nodes:")
                capableNodes.forEach { node ->
                    Log.i(TAG, "  ✓ ${node.displayName} (ID: ${node.id}, Nearby: ${node.isNearby})")
                }
                return capableNodes.toList()
            }
            
            // Fallback: get all connected nodes
            Log.i(TAG, "No capable nodes found, falling back to all connected nodes...")
            val connectedNodes = nodeClient.connectedNodes.await()
            
            if (connectedNodes.isEmpty()) {
                Log.w(TAG, "No connected nodes - ensure phone is paired and has FlowFit installed")
                Log.w(TAG, "Troubleshooting:")
                Log.w(TAG, "  1. Check Bluetooth connection between watch and phone")
                Log.w(TAG, "  2. Ensure FlowFit is installed on phone")
                Log.w(TAG, "  3. Verify phone app has wear.xml capability declaration")
            } else {
                Log.i(TAG, "Connected nodes:")
                connectedNodes.forEach { node ->
                    Log.i(TAG, "  - ${node.displayName} (ID: ${node.id}, Nearby: ${node.isNearby})")
                }
            }
            
            connectedNodes
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get connected nodes", e)
            emptyList()
        }
    }

    /**
     * Get nodes with specific capability (phones with FlowFit installed)
     */
    private suspend fun getCapableNodes(): Set<Node> {
        return try {
            val capabilityInfo = capabilityClient
                .getCapability(CAPABILITY_NAME, CapabilityClient.FILTER_REACHABLE)
                .await()
            
            val nodes = capabilityInfo.nodes
            Log.i(TAG, "Capability '$CAPABILITY_NAME' found on ${nodes.size} nodes")
            nodes
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get capable nodes: ${e.message}", e)
            emptySet()
        }
    }
    
    /**
     * Find phone node with capability (preferred method)
     */
    suspend fun findPhoneNode(): Node? {
        return try {
            val capableNodes = getCapableNodes()
            capableNodes.firstOrNull()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to find phone node", e)
            null
        }
    }
}
