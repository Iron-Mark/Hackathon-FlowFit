package com.oldstlabs.flowfit

import kotlinx.serialization.Serializable

/**
 * Data class representing heart rate measurement with inter-beat intervals
 * 
 * @property hr Heart rate in beats per minute
 * @property ibi List of inter-beat intervals in milliseconds
 */
@Serializable
data class TrackedData(
    var hr: Int = 0,
    var ibi: ArrayList<Int> = ArrayList()
)
