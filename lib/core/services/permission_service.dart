import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.audio.request();
      if (status.isGranted) return true;

      // Fallback for Android < 13
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }

  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.audio.isGranted) return true;
      if (await Permission.storage.isGranted) return true;
      return false;
    }
    return true;
  }

  static Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }
}
