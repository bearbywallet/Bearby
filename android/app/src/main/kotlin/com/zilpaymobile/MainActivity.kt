package com.zilpaymobile

import android.os.Bundle
import ble.LedgerBlePlugin
import hid.HidPlugin
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.util.Log

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val TAG = "MainActivity"
        
        init {
            try {
                Log.d(TAG, "Loading rust_lib_zilpay...")
                System.loadLibrary("rust_lib_zilpay")
                Log.d(TAG, "Library loaded successfully!")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load library: ${e.message}")
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        flutterEngine.plugins.add(HidPlugin())
        flutterEngine.plugins.add(LedgerBlePlugin())
    }
}
