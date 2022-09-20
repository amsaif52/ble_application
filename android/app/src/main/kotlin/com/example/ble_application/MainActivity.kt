package com.example.ble_application
import com.umair.beacons_plugin.BeaconsPlugin
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

    override fun onPause() {
        super.onPause()
        BeaconsPlugin.startBackgroundService(this)
    }
    override fun onResume() {
        super.onResume()
        BeaconsPlugin.startBackgroundService(this)
    }
}
