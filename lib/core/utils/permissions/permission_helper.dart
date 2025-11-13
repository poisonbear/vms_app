// lib/core/utils/permissions/permission_helper.dart

import 'package:permission_handler/permission_handler.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 일반 권한 헬퍼 (범용)
class PermissionHelper {
  PermissionHelper._();

  /// 위치 권한 확인
  static Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// 위치 권한 요청
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// 위치 권한 확인 및 요청
  static Future<bool> checkAndRequestLocationPermission() async {
    if (await checkLocationPermission()) {
      return true;
    }
    return await requestLocationPermission();
  }

  /// 모든 권한 상태 확인
  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    return {
      Permission.location: await Permission.location.status,
      Permission.notification: await Permission.notification.status,
      Permission.storage: await Permission.storage.status,
    };
  }

  /// 앱 설정 열기
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      AppLogger.e('Failed to open app settings: $e');
    }
  }
}
