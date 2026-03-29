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
                
                // Use 90% of screen width for a more spacious card
                width = (resources.displayMetrics.widthPixels * 0.9).toInt()
                height = WindowManager.LayoutParams.WRAP_CONTENT
                gravity = Gravity.CENTER
                x = 0
                y = 0
            }

            // Create container
            val container = FrameLayout(this)
            val cardBg = GradientDrawable().apply {
                setColor(Color.parseColor("#121212")) // Deep Obsidian
                cornerRadius = 80f 
                setStroke(4, Color.parseColor("#6366F1")) // Indigo Border
                setAlpha(252)
            }
            container.background = cardBg
            container.elevation = 40f
            container.setPadding(60, 60, 60, 60)

            val mainLayout = android.widget.LinearLayout(this).apply {
                orientation = android.widget.LinearLayout.VERTICAL
            }
            container.addView(mainLayout)

            // Header Container (to allow Badge in top right)
            val headerContainer = FrameLayout(this).apply {
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            mainLayout.addView(headerContainer)

            // 1. Header Row (Avatar + Name)
            val headerRow = android.widget.LinearLayout(this).apply {
                orientation = android.widget.LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(0, 0, 80, 24) // Room for badge/X
            }
            headerContainer.addView(headerRow)

            // Avatar (Initial)
            val initial = if (contactName.isNotEmpty()) contactName[0].toString().uppercase() else "?"
            val avatar = TextView(this).apply {
                text = initial
                setTextColor(Color.WHITE)
                textSize = 22f
                setTypeface(null, android.graphics.Typeface.BOLD)
                gravity = Gravity.CENTER
                val avatarBg = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#6366F1")) 
                    setStroke(2, Color.WHITE) // White ring for polish
                }
                background = avatarBg
                layoutParams = FrameLayout.LayoutParams(120, 120).apply {
                    marginEnd = 32
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
                textSize = 24f
                setTypeface(null, android.graphics.Typeface.BOLD)
                ellipsize = android.text.TextUtils.TruncateAt.END
                maxLines = 1
            }
            nameColumn.addView(nameText)

            val phoneText = TextView(this).apply {
                text = phoneNumber
                setTextColor(Color.parseColor("#6366F1")) // Accent phone color
                textSize = 15f
                setTypeface(null, android.graphics.Typeface.BOLD)
            }
            nameColumn.addView(phoneText)

            // CRM Badge (Top Right)
            val badge = TextView(this).apply {
                text = "CRM LEAD"
                setTextColor(Color.WHITE)
                textSize = 9f
                setTypeface(null, android.graphics.Typeface.BOLD)
                setPadding(16, 4, 16, 4)
                val badgeBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#2D2D3F")) // Subtle indigo-grey
                    cornerRadius = 100f
                }
                background = badgeBg
            }
            val badgeParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.TOP or Gravity.END
                topMargin = 0
                rightMargin = 20
            }
            headerContainer.addView(badge, badgeParams)

            // 2. Note Section (Distinct Box)
            val noteBox = android.widget.LinearLayout(this).apply {
                orientation = android.widget.LinearLayout.VERTICAL
                setPadding(40, 32, 40, 32)
                val noteBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#1C1C1E")) // Slightly lighter obsidian
                    cornerRadius = 40f
                }
                background = noteBg
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    android.widget.LinearLayout.LayoutParams.MATCH_PARENT, 
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = 8
                }
            }
            mainLayout.addView(noteBox)

            // "LATEST NOTE" Pill
            val noteLabel = TextView(this).apply {
                text = "LATEST NOTE"
                setTextColor(Color.WHITE)
                textSize = 10f
                setTypeface(null, android.graphics.Typeface.BOLD)
                setPadding(16, 4, 16, 4)
                val labelBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#6366F1")) // Indigo pill
                    cornerRadius = 100f
                }
                background = labelBg
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    bottomMargin = 16
                }
            }
            noteBox.addView(noteLabel)

            val noteText = TextView(this).apply {
                text = if (notes.isNotEmpty()) notes else "Caller identified as CRM Lead."
                setTextColor(Color.WHITE)
                textSize = 16f
                setLineSpacing(0f, 1.3f) // Better readability for multiline
            }
            noteBox.addView(noteText)

            // Close Button (Premium style)
            val closeButton = TextView(this).apply {
                text = "✕"
                setTextColor(Color.WHITE)
                textSize = 16f
                gravity = Gravity.CENTER
                setOnClickListener { dismissOverlay() }
                setPadding(10, 10, 10, 10)
            }
            val closeParams = FrameLayout.LayoutParams(70, 70).apply {
                gravity = Gravity.BOTTOM or Gravity.END
                bottomMargin = 10
                rightMargin = 10
            }
            container.addView(closeButton, closeParams)

            overlayView = container
            windowManager?.addView(overlayView, windowParams)
            Log.d(TAG, "Super Premium Overlay added successfully")

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
