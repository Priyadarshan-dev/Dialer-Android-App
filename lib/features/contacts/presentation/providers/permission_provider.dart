import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

final overlayPermissionProvider = StateNotifierProvider<OverlayPermissionNotifier, bool>((ref) {
  return OverlayPermissionNotifier();
});

class OverlayPermissionNotifier extends StateNotifier<bool> {
  OverlayPermissionNotifier() : super(true) {
    checkPermission();
  }

  Future<void> checkPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.systemAlertWindow.status;
      state = status.isGranted;
    }
  }

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.systemAlertWindow.request();
      state = status.isGranted;
    }
  }
}
