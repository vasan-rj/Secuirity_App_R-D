package com.example.client_prototype

import io.flutter.embedding.android.FlutterActivity
import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.widget.Toast
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity()

{
    private val CHANNEL = "kiosk_mode_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableKiosk" -> {
                    enableKioskMode()
                    result.success("Kiosk Mode Enabled")
                }
                "disableKiosk" -> {
                    disableKioskMode()
                    result.success("Kiosk Mode Disabled")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enableKioskMode() {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(this, AdminReceiver::class.java)

        if (dpm.isDeviceOwnerApp(packageName)) {
            dpm.setLockTaskPackages(componentName, arrayOf(packageName))
            startLockTask()
            Toast.makeText(this, "Kiosk Mode Enabled", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(this, "App is not Device Owner!", Toast.LENGTH_LONG).show()
        }
    }

    private fun disableKioskMode() {
        stopLockTask()
        Toast.makeText(this, "Kiosk Mode Disabled", Toast.LENGTH_SHORT).show()
    }
}
