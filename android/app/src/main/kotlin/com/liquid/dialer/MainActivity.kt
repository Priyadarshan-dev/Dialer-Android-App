package com.liquid.dialer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CallScreeningConstants.METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    CallScreeningConstants.SYNC_CALL_DIRECTORY_METHOD -> {
                        Log.d(TAG, "Syncing call directory (Android)...")
                        result.success(true)
                    }
                    "isCallerIdRoleHeld" -> {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                            val roleManager = getSystemService(android.content.Context.ROLE_SERVICE) as android.app.role.RoleManager
                            result.success(roleManager.isRoleHeld(android.app.role.RoleManager.ROLE_CALL_SCREENING))
                        } else {
                            result.success(true) // Older versions don't have this role, handled via other means if needed
                        }
                    }
                    "isOverlayPermissionGranted" -> {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                            result.success(android.provider.Settings.canDrawOverlays(this))
                        } else {
                            result.success(true)
                        }
                    }
                    "requestCallerIdRole" -> {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                            val roleManager = getSystemService(android.content.Context.ROLE_SERVICE) as android.app.role.RoleManager
                            val intent = roleManager.createRequestRoleIntent(android.app.role.RoleManager.ROLE_CALL_SCREENING)
                            startActivityForResult(intent, 123)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "requestOverlayPermission" -> {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                            if (!android.provider.Settings.canDrawOverlays(this)) {
                                val intent = android.content.Intent(
                                    android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    android.net.Uri.parse("package:$packageName")
                                )
                                startActivityForResult(intent, 124)
                                result.success(true)
                            } else {
                                result.success(true) // Already granted
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
