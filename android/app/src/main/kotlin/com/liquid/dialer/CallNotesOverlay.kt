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
            
            val windowParams = WindowManager.LayoutParams().apply {
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
                setColor(Color.parseColor("#121212")) // Deep Obsidian
                cornerRadius = 64f // Smoother corners for premium feel
                setStroke(3, Color.parseColor("#6366F1")) // Indigo Border
                setAlpha(248)
            }
            container.background = background
            container.elevation = 32f
            container.setPadding(40, 40, 40, 40)

            val mainLayout = android.widget.LinearLayout(this).apply {
                orientation = android.widget.LinearLayout.VERTICAL
            }
            container.addView(mainLayout)

            // 1. Header Row (Avatar + Name)
            val headerRow = android.widget.LinearLayout(this).apply {
                orientation = android.widget.LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(0, 0, 0, 16)
            }
            mainLayout.addView(headerRow)

            // Avatar (Initial)
            val initial = if (contactName.isNotEmpty()) contactName[0].toString().uppercase() else "?"
            val avatar = TextView(this).apply {
                text = initial
                setTextColor(Color.WHITE)
                textSize = 20f
                setTypeface(null, android.graphics.Typeface.BOLD)
                gravity = Gravity.CENTER
                val avatarBg = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#6366F1")) // Indigo Avatar
                }
                background = avatarBg
                layoutParams = FrameLayout.LayoutParams(110, 110).apply {
                    marginEnd = 24
                }
            }
            headerRow.addView(avatar)

            // Name & Phone Column
            val nameColumn = android.widget.LinearLayout(this).apply {
                orientation = android.widget.LinearLayout.VERTICAL
            }
            headerRow.addView(nameColumn)

            val nameText = TextView(this).apply {
                text = if (contactName.isNotEmpty()) contactName else "Unknown Lead"
                setTextColor(Color.WHITE)
                textSize = 22f
                setTypeface(null, android.graphics.Typeface.BOLD)
                ellipsize = android.text.TextUtils.TruncateAt.END
                maxLines = 1
            }
            nameColumn.addView(nameText)

            val phoneText = TextView(this).apply {
                text = phoneNumber
                setTextColor(Color.parseColor("#94A3B8")) // Muted blue-grey
                textSize = 14f
            }
            nameColumn.addView(phoneText)

            // 2. Note Section (Distinct Box)
            if (notes.isNotEmpty()) {
                val noteBox = android.widget.LinearLayout(this).apply {
                    orientation = android.widget.LinearLayout.VERTICAL
                    setPadding(32, 24, 32, 24)
                    val noteBg = GradientDrawable().apply {
                        setColor(Color.parseColor("#1E1E1E"))
                        cornerRadius = 24f
                    }
                    background = noteBg
                    layoutParams = android.widget.LinearLayout.LayoutParams(
                        android.widget.LinearLayout.LayoutParams.MATCH_PARENT, 
                        android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply {
                        topMargin = 16
                    }
                }
                mainLayout.addView(noteBox)

                val noteLabel = TextView(this).apply {
                    text = "LATEST CRM NOTE"
                    setTextColor(Color.parseColor("#6366F1"))
                    textSize = 10f
                    setTypeface(null, android.graphics.Typeface.BOLD)
                    letterSpacing = 0.1f
                    setPadding(0, 0, 0, 8)
                }
                noteBox.addView(noteLabel)

                val noteText = TextView(this).apply {
                    text = notes
                    setTextColor(Color.WHITE)
                    textSize = 15f
                    setLineSpacing(0f, 1.2f)
                }
                noteBox.addView(noteText)
            } else {
                // If no notes, show identified badge
                val badge = TextView(this).apply {
                    text = "✓ CRM IDENTIFIED"
                    setTextColor(Color.parseColor("#10B981")) // Emerald Green
                    textSize = 11f
                    setTypeface(null, android.graphics.Typeface.BOLD)
                    setPadding(0, 16, 0, 0)
                    gravity = Gravity.CENTER
                }
                mainLayout.addView(badge)
            }

            // Close Button (Fixed positioning)
            val closeButton = TextView(this).apply {
                text = "✕"
                setTextColor(Color.parseColor("#475569"))
                textSize = 18f
                gravity = Gravity.CENTER
                setOnClickListener { dismissOverlay() }
            }
            val closeParams = FrameLayout.LayoutParams(80, 80).apply {
                gravity = Gravity.TOP or Gravity.END
                topMargin = 10
                rightMargin = 10
            }
            container.addView(closeButton, closeParams)

            overlayView = container // Add container directly instead of wrapping in root
            windowManager?.addView(overlayView, windowParams)
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
