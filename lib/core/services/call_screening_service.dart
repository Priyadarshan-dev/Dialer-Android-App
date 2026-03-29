import 'package:flutter/services.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';

/// Simplified CallScreeningService.
/// On Android, the native side now reads directly from SharedPreferences.
/// The Flutter side only needs to handle the sync request if needed.
class CallScreeningService {
  static const MethodChannel _channel = MethodChannel(AppConstants.callScreeningChannel);

  /// Initializes the Method Channel handlers for Android Call Screening.
  static Future<void> initializeCallScreening() async {
    _channel.setMethodCallHandler((call) async {
      // The native side now handles getCallNotes internally via SharedPreferences.
      // We keep this here in case we want to trigger a full re-sync from native.
      if (call.method == AppConstants.getCallNotesMethod) {
          // No longer needed to query Hive from here.
          return null;
      }
      return null;
    });
  }

  /// Triggers a sync/reload notification on the native side if necessary.
  static Future<void> syncCallDirectory() async {
    try {
      await _channel.invokeMethod(AppConstants.syncCallDirectoryMethod);
    } on PlatformException catch (e) {
      print('[DEBUG] CallScreeningService: Sync notification failed: ${e.message}');
    }
  }

  /// Check if the app is the default Caller ID & Spam app
  static Future<bool> isCallerIdRoleHeld() async {
    try {
      return await _channel.invokeMethod<bool>('isCallerIdRoleHeld') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if the app has overlay permission
  static Future<bool> isOverlayPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isOverlayPermissionGranted') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request to set as default Caller ID app
  static Future<void> requestCallerIdRole() async {
    try {
      await _channel.invokeMethod('requestCallerIdRole');
    } catch (e) {
      print('[DEBUG] Error requesting Caller ID role: $e');
    }
  }

  /// Request Overlay permission
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      print('[DEBUG] Error requesting Overlay permission: $e');
    }
  }
}
