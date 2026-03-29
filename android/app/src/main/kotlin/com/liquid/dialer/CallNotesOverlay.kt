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
        val name = intent?.getStringExtra("contactName") ?: ""
        
        Log.d(TAG, "onStartCommand: received phoneNumber: $phoneNumber, name: $name and notes: $notes")
        
        if (notes.isNotEmpty() || name.isNotEmpty()) {
            showOverlay(phoneNumber, notes, name)
        } else {
            Log.d(TAG, "No notes or name to show, stopping service")
            stopSelf()
        }
        
        return START_NOT_STICKY
    }

    private fun showOverlay(phoneNumber: String, notes: String, contactName: String) {
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
                gravity = Gravity.START
            }
            container.addView(contentLayout)

            fun addLabeledRow(label: String, value: String, isBold: Boolean = false, textColor: Int = Color.WHITE) {
                val row = android.widget.LinearLayout(this).apply {
                    orientation = android.widget.LinearLayout.HORIZONTAL
                    setPadding(0, 4, 0, 4)
                }
                
                val labelView = TextView(this).apply {
                    text = "$label "
                    setTextColor(Color.parseColor("#BBBBBB"))
                    textSize = 14f
                    setTypeface(null, android.graphics.Typeface.BOLD)
                }
                
                val valueView = TextView(this).apply {
                    text = value
                    setTextColor(textColor)
                    textSize = 16f
                    if (isBold) setTypeface(null, android.graphics.Typeface.BOLD)
                }
                
                row.addView(labelView)
                row.addView(valueView)
                contentLayout.addView(row)
            }

            // Name Row
            if (contactName.isNotEmpty()) {
                addLabeledRow("Name : ", contactName, isBold = true)
            }

            // Phone Row
            addLabeledRow("Phone : ", phoneNumber, textColor = Color.parseColor("#6366F1"))

            // Divider or spacer if notes exist
            if (notes.isNotEmpty()) {
                val divider = View(this).apply {
                    layoutParams = android.widget.LinearLayout.LayoutParams(
                        android.widget.LinearLayout.LayoutParams.MATCH_PARENT, 2).apply {
                        setMargins(0, 16, 0, 16)
                    }
                    setBackgroundColor(Color.parseColor("#444444"))
                }
                contentLayout.addView(divider)

                // Notes Header
                val notesHeader = TextView(this).apply {
                    text = "Notes :"
                    setTextColor(Color.parseColor("#BBBBBB"))
                    textSize = 12f
                    setTypeface(null, android.graphics.Typeface.BOLD)
                    setPadding(0, 0, 0, 8)
                }
                contentLayout.addView(notesHeader)

                // Notes Content
                val notesText = TextView(this).apply {
                    text = notes
                    setTextColor(Color.WHITE)
                    textSize = 15f
                    setLineSpacing(0f, 1.2f)
                }
                contentLayout.addView(notesText)
            } else if (contactName.isNotEmpty()) {
                // If there's a name but no note, show a "Lead Identified" badge
                val leadBadge = TextView(this).apply {
                    text = "CRM LEAD IDENTIFIED"
                    setTextColor(Color.parseColor("#6366F1"))
                    textSize = 12f
                    setTypeface(null, android.graphics.Typeface.BOLD)
                    setPadding(0, 12, 0, 0)
                }
                contentLayout.addView(leadBadge)
            }

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
