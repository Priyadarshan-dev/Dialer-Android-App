import 'package:shared_preferences/shared_preferences.dart';

/// Service to sync call notes to SharedPreferences
/// This allows the Android Call Screening Service to access notes across processes
class SharedPreferencesService {
  static const String _noteKeyPrefix = 'notes_';
  static const String _nameKeyPrefix = 'name_';

  /// Save all contacts to SharedPreferences to sync Caller ID for everyone
  static Future<void> syncAllContactsToSharedPrefs(List<dynamic> contacts) async {
    try {
      print('[DEBUG] SharedPreferencesService: Syncing all ${contacts.length} contacts...');
      final prefs = await SharedPreferences.getInstance();
      
      for (var contact in contacts) {
        if (contact.phoneNumbers.isNotEmpty) {
          final phone = contact.phoneNumbers.first;
          final normalized = _normalizePhoneNumber(phone);
          if (normalized.isNotEmpty) {
            await prefs.setString('$_noteKeyPrefix$normalized', contact.notes ?? ''); 
            await prefs.setString('$_nameKeyPrefix$normalized', contact.displayName);
          }
        }
      }
      print('[DEBUG] SharedPreferencesService: All contacts synced.');
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error syncing all: $e');
    }
  }

  /// Save note to SharedPreferences for Android Call Screening Service
  static Future<void> saveNoteToSharedPrefs(String phoneNumber, String notes, {String? contactName}) async {
    try {
      print('[DEBUG] SharedPreferencesService: Saving note for $phoneNumber');
      
      final prefs = await SharedPreferences.getInstance();
      final normalized = _normalizePhoneNumber(phoneNumber);
      
      if (normalized.isEmpty) {
        print('[DEBUG] SharedPreferencesService: Normalized number is empty, skipping save');
        return;
      }
      
      final key = '$_noteKeyPrefix$normalized';
      final nameKey = '$_nameKeyPrefix$normalized';
      
      // Save to SharedPreferences
      await prefs.setString(key, notes);
      if (contactName != null) {
        await prefs.setString(nameKey, contactName);
      }
      
      print('[DEBUG] SharedPreferencesService: Saved data for $normalized');
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error saving note: $e');
    }
  }

  /// Get note from SharedPreferences
  static Future<String?> getNoteFromSharedPrefs(String phoneNumber) async {
    try {
      print('[DEBUG] SharedPreferencesService: Retrieving note for $phoneNumber');
      
      final prefs = await SharedPreferences.getInstance();
      final normalized = _normalizePhoneNumber(phoneNumber);
      
      if (normalized.isEmpty) {
        print('[DEBUG] SharedPreferencesService: Normalized number is empty');
        return null;
      }
      
      final key = '$_noteKeyPrefix$normalized';
      final note = prefs.getString(key);
      
      print('[DEBUG] SharedPreferencesService: Retrieved note for $normalized: $note');
      return note;
      
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error retrieving note: $e');
      return null;
    }
  }

  /// Delete note from SharedPreferences
  static Future<void> deleteNoteFromSharedPrefs(String phoneNumber) async {
    try {
      print('[DEBUG] SharedPreferencesService: Deleting note for $phoneNumber');
      
      final prefs = await SharedPreferences.getInstance();
      final normalized = _normalizePhoneNumber(phoneNumber);
      
      if (normalized.isEmpty) {
        print('[DEBUG] SharedPreferencesService: Normalized number is empty, skipping delete');
        return;
      }
      
      final key = '$_noteKeyPrefix$normalized';
      final nameKey = '$_nameKeyPrefix$normalized';
      await prefs.remove(key);
      await prefs.remove(nameKey);
      
      print('[DEBUG] SharedPreferencesService: Deleted note for $normalized');
      
      // List remaining notes for debugging
      _debugListAllNotes(prefs);
      
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error deleting note: $e');
      rethrow;
    }
  }

  /// Clear all notes from SharedPreferences
  static Future<void> clearAllNotes() async {
    try {
      print('[DEBUG] SharedPreferencesService: Clearing all notes...');
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_noteKeyPrefix)).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      print('[DEBUG] SharedPreferencesService: Cleared all notes (${keys.length} entries deleted)');
      
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error clearing notes: $e');
      rethrow;
    }
  }

  /// Normalize phone number to match Kotlin normalization
  /// This MUST match the normalization in LiquidDialerCallScreeningService.kt
  ///
  /// Rules:
  /// 1. Remove all non-digit characters except leading +
  /// 2. If no leading +, remove leading zeros
  /// 3. For international numbers, keep digits after the +
  ///
  /// Examples:
  /// +91 99652 05472 → 919965205472
  /// 9965205472 → 9965205472
  /// +1-555-123-4567 → 15551234567
  /// Normalize phone number to match Kotlin normalization (Last 10 Digits)
  static String _normalizePhoneNumber(String number) {
    if (number.isEmpty) return '';

    try {
      // Step 1: Remove all non-digit characters
      var sanitized = number.replaceAll(RegExp(r'\D'), '');

      // Step 2: Take only the last 10 digits (Standard local part for India/US)
      if (sanitized.length > 10) {
        sanitized = sanitized.substring(sanitized.length - 10);
      }

      return sanitized;
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error normalizing: $e');
      return number;
    }
  }

  /// Debug helper to list all saved notes in SharedPreferences
  static void _debugListAllNotes(SharedPreferences prefs) {
    final keys = prefs.getKeys().where((key) => key.startsWith(_noteKeyPrefix)).toList();
    print('[DEBUG] SharedPreferencesService: === All saved notes ===');
    
    if (keys.isEmpty) {
      print('[DEBUG] SharedPreferencesService: No notes saved yet');
    } else {
      print('[DEBUG] SharedPreferencesService: Total notes: ${keys.length}');
      for (final key in keys) {
        final value = prefs.getString(key);
        print('[DEBUG] SharedPreferencesService: $key = "$value"');
      }
    }
    
    print('[DEBUG] SharedPreferencesService: === End of notes ===');
  }
}