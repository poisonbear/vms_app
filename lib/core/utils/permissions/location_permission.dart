// lib/core/utils/permissions/location_permission.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 위치 권한 유틸리티
class LocationPermissionUtil {
  LocationPermissionUtil._();

  /// 위치 권한 체크
  static Future<bool> check() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      AppLogger.e('위치 권한 확인 실패: $e');
      return false;
    }
  }

  /// 위치 권한 요청
  static Future<bool> request() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      AppLogger.e('위치 권한 요청 실패: $e');
      return false;
    }
  }

  /// 위치 권한 요청 (UI 포함 - 승인될 때까지 반복)
  static Future<bool> requestWithDialog(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        AppLogger.d('이미 위치 권한이 허용되어 있습니다.');
        return true;
      }

      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        AppLogger.d('위치 권한 획득 완료');
        return true;
      } else {
        if (permission == LocationPermission.deniedForever) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          AppLogger.d('위치 권한 영구적으로 거부됨');
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('위치 권한이 필요합니다'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          AppLogger.d('위치 권한 거부됨');
        }
        return false;
      }
    } catch (e) {
      AppLogger.e('위치 권한 요청 오류: $e');
      return false;
    }
  }

  /// 위치 서비스 활성화 체크
  static Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      AppLogger.e('위치 서비스 확인 실패: $e');
      return false;
    }
  }

  /// 설정 화면 열기
  static Future<void> openSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      AppLogger.e('설정 화면 열기 실패: $e');
    }
  }
}

/// 위치 권한 요청 유틸리티 (기존 코드 호환성)
class PointRequestUtil {
  PointRequestUtil._();

  /// 위치 권한 요청 (승인될 때까지 반복)
  static Future<bool> requestPermissionUntilGranted(
      BuildContext context) async {
    return await LocationPermissionUtil.requestWithDialog(context);
  }

  /// 위치 권한 체크
  static Future<bool> checkPermission() async {
    return await LocationPermissionUtil.check();
  }
}
