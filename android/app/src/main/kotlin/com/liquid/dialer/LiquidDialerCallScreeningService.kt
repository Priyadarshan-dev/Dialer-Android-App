package com.liquid.dialer

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log

class LiquidDialerCallScreeningService : CallScreeningService() {
    private val TAG = "CallScreeningService"
    private val NOTE_KEY_PREFIX = "flutter.notes_"

    override fun onScreenCall(callDetails: Call.Details) {
        Log.d(TAG, "===== onScreenCall triggered =====")
        
        val handle = callDetails.handle
        if (handle == null || handle.scheme != "tel") {
            Log.d(TAG, "Invalid handle or scheme, using default response")
            respondWithDefault(callDetails)
            return
        }

        val phoneNumber = handle.schemeSpecificPart
        Log.d(TAG, "Incoming call from: $phoneNumber")

        val normalizedNumber = normalizePhoneNumber(phoneNumber)
        Log.d(TAG, "Normalized: $normalizedNumber")

        // Query notes from SharedPreferences
        val notes = queryNotesFromSharedPrefs(normalizedNumber)
        val prefs = this.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val name = prefs.getString("flutter.name_$normalizedNumber", null)
        Log.d(TAG, "Retrieved notes: $notes, name: $name")

        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)

        if (!notes.isNullOrEmpty()) {
            Log.d(TAG, "Found notes for display: $notes")
            Log.d(TAG, "Starting overlay service with notes")
            val overlayIntent = Intent(this, CallNotesOverlay::class.java).apply {
                putExtra("phoneNumber", phoneNumber)
                putExtra("notes", notes)
                putExtra("contactName", name)
            }
            startService(overlayIntent)
        } else {
            Log.d(TAG, "No notes found for this number")
        }
        
        Log.d(TAG, "Call response sent")
        respondToCall(callDetails, response.build())
    }

    private fun respondWithDefault(callDetails: Call.Details) {
        Log.d(TAG, "Sending default response")
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()
        respondToCall(callDetails, response)
    }

    /**
     * Query notes from SharedPreferences using normalized phone number
     * Key format: notes_{normalized_number}
     * Example: notes_919965205472
     */
    private fun queryNotesFromSharedPrefs(normalizedNumber: String): String? {
        return try {
            Log.d(TAG, "--- Querying SharedPreferences ---")
            
            val prefs = this.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val key = "$NOTE_KEY_PREFIX$normalizedNumber"
            
            Log.d(TAG, "Looking for key: $key")
            
            // Debug: List all "notes_" keys in SharedPreferences
            val allEntries = prefs.all
            val notesKeys = allEntries.keys.filter { it.startsWith(NOTE_KEY_PREFIX) }
            Log.d(TAG, "Total 'notes_' keys in SharedPreferences: ${notesKeys.size}")
            for (k in notesKeys) {
                Log.d(TAG, "  Key found: $k = ${allEntries[k]}")
            }
            
            // Query for the specific key
            val result = prefs.getString(key, null)
            Log.d(TAG, "Query result for '$key': $result")
            
            result
            
        } catch (e: Exception) {
            Log.e(TAG, "Error querying SharedPrefs: ${e.message}", e)
            null
        }
    }

    /**
     * Normalize phone number to match Flutter/Dart normalization
     * Rules:
     * 1. Remove all non-digit characters except leading +
     * 2. If no leading +, remove leading zeros
     * 3. For international numbers, keep digits after the +
     *
     * Examples:
     * +91 99652 05472 → 919965205472
     * 9965205472 → 9965205472
     * +1-555-123-4567 → 15551234567
     */
    private fun normalizePhoneNumber(phoneNumber: String): String {
        if (phoneNumber.isEmpty()) {
            return ""
        }

        val isInternational = phoneNumber.startsWith("+")
        
        // Step 1: Remove all non-digit characters except leading '+'
        var sanitized = phoneNumber.replace(Regex("(?!^\\+)\\D"), "")
        Log.d(TAG, "After removing non-digits: $sanitized")
        
        // Step 2: Remove leading zeros if it's not an international format
        if (!sanitized.startsWith("+")) {
            sanitized = sanitized.replaceFirst(Regex("^0+"), "")
            Log.d(TAG, "After removing leading zeros: $sanitized")
        }
        
        // Step 3: For international numbers, keep the digits after the '+'
        if (sanitized.startsWith("+")) {
            sanitized = sanitized.substring(1)
            Log.d(TAG, "After removing +: $sanitized")
        }
        
        Log.d(TAG, "Final normalization: '$phoneNumber' → '$sanitized'")
        return sanitized
    }
}