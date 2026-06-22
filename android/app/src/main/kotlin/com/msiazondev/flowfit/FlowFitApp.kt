package com.msiazondev.flowfit

import android.app.Application
import android.util.Log

/**
 * Custom Application class for FlowFit
 * Provides application-level initialization and context
 */
class FlowFitApp : Application() {
    companion object {
        private const val TAG = "FlowFitApp"
        
        /**
         * Global application instance
         * Useful for accessing application context from anywhere
         */
        lateinit var instance: FlowFitApp
            private set
    }
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        
        Log.i(TAG, "✅ FlowFit Application initialized")
        Log.i(TAG, "📱 Application context available: ${applicationContext.javaClass.simpleName}")
    }
}
