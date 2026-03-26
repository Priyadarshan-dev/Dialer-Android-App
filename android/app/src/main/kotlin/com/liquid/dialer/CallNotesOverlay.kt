package com.liquid.dialer

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import android.graphics.drawable.GradientDrawable

class CallNotesOverlay : Service() {
    private val TAG = "CallNotesOverlay"
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private val dismissRunnable = Runnable { dismissOverlay() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val phoneNumber = intent?.getStringExtra("phoneNumber") ?: ""
        val notes = intent?.getStringExtra("notes") ?: ""
        
        Log.d(TAG, "onStartCommand: received phoneNumber: $phoneNumber and notes: $notes")
        
        if (notes.isNotEmpty()) {
            showOverlay(phoneNumber, notes)
        } else {
            Log.d(TAG, "No notes to show, stopping service")
            stopSelf()
        }
        
        return START_NOT_STICKY
    }

    private fun showOverlay(phoneNumber: String, notes: String) {
        try {
            windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            
            val layoutParams = WindowManager.LayoutParams().apply {
                type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }
                format = PixelFormat.TRANSLUCENT
                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                
                width = 700 // pixels as requested
                height = WindowManager.LayoutParams.WRAP_CONTENT
                gravity = Gravity.CENTER
                x = 0
                y = 0
            }

            // Create container
            val container = FrameLayout(this)
            val background = GradientDrawable().apply {
                setColor(Color.parseColor("#2A2A2A"))
                cornerRadius = 24f
                setAlpha(242) // 0.95f * 255
            }
            container.background = background
            container.elevation = 16f
            container.setPadding(48, 48, 48, 48)

            // Inflate or programmatically create the UI
            // Since we don't have XML layouts ready, let's create it programmatically for simplicity and robustness
            
            val contentLayout = android.widget.LinearLayout(this).apply {
                orientation = android.widget.LinearLayout.VERTICAL
                gravity = Gravity.CENTER // Center content within container
            }
            container.addView(contentLayout)

            // Phone Number
            val phoneText = TextView(this).apply {
                text = phoneNumber
                setTextColor(Color.WHITE)
                textSize = 18f
                setTypeface(null, android.graphics.Typeface.BOLD)
                setPadding(0, 0, 0, 16)
                gravity = Gravity.CENTER_HORIZONTAL
            }
            contentLayout.addView(phoneText)

            // Saved Notes static label
            val labelText = TextView(this).apply {
                text = "SAVED NOTES:"
                setTextColor(Color.parseColor("#BBBBBB"))
                textSize = 12f
                setTypeface(null, android.graphics.Typeface.BOLD)
                setPadding(0, 0, 0, 8)
                gravity = Gravity.CENTER_HORIZONTAL
            }
            contentLayout.addView(labelText)

            // Notes
            val notesText = TextView(this).apply {
                text = notes
                setTextColor(Color.WHITE)
                textSize = 15f
                maxLines = 6
                ellipsize = android.text.TextUtils.TruncateAt.END
                gravity = Gravity.CENTER_HORIZONTAL
                textAlignment = View.TEXT_ALIGNMENT_CENTER
            }
            contentLayout.addView(notesText)

            // Close Button (X)
            val closeButton = TextView(this).apply {
                text = "✕"
                setTextColor(Color.WHITE)
                textSize = 20f
                gravity = Gravity.CENTER
                setOnClickListener {
                    Log.d(TAG, "Close button clicked")
                    dismissOverlay()
                }
            }
            val closeParams = FrameLayout.LayoutParams(96, 96).apply {
                gravity = Gravity.TOP or Gravity.END
            }
            container.addView(closeButton, closeParams)

            overlayView = container // Add container directly instead of wrapping in root
            windowManager?.addView(overlayView, layoutParams)
            Log.d(TAG, "Overlay added to WindowManager successfully")

           

        } catch (e: Exception) {
            Log.e(TAG, "Error showing overlay: ${e.message}", e)
            stopSelf()
        }
    }

    private fun dismissOverlay() {
        try {
            overlayView?.let {
                windowManager?.removeView(it)
                overlayView = null
                Log.d(TAG, "Overlay dismissed")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error dismissing overlay: ${e.message}")
        } finally {
            stopSelf()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(dismissRunnable)
        dismissOverlay()
    }
}
