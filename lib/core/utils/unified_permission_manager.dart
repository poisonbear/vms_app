import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/utils/dialog_utils.dart';

/// 통합 권한 관리 클래스
class UnifiedPermissionManager {
  static bool _openedSettings = false;

  /// 모든 필수 권한 요청
  static Future<void> requestAllPermissions(BuildContext context) async {
    await requestLocationPermission(context);
    await requestNotificationPermission(context);
  }

  /// 위치 권한 요청
  static Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await DialogUtils.showConfirmDialog(
          context: context,
          title: '위치 서비스 필요',
          message: '위치 서비스가 꺼져 있습니다.\n설정에서 위치 서비스를 활성화해 주세요.',
          confirmText: '설정 열기',
          onConfirm: () async {
            await Geolocator.openLocationSettings();
          },
        );
        return false;
      }

      // 권한 상태 확인
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.d('❌ 위치 권한 거부됨');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await DialogUtils.showPermissionDialog(
          context: context,
          permissionType: '위치',
          message: '위치 권한이 영구적으로 거부되었습니다.',
          onOpenSettings: () async {
            _openedSettings = true;
            await openAppSettings();
          },
          onExit: () => exit(0),
        );
        return false;
      }

      AppLogger.d('✅ 위치 권한 허용됨');
      return true;
    } catch (e) {
      AppLogger.e('위치 권한 요청 오류', e);
      return false;
    }
  }

  /// 알림 권한 요청
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.d('✅ 알림 권한 허용됨');
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await DialogUtils.showPermissionDialog(
          context: context,
          permissionType: '알림',
          message: '알림 권한이 거부되었습니다.',
          onOpenSettings: () async {
            _openedSettings = true;
            await openAppSettings();
          },
          onExit: () => exit(0),
        );
        return false;
      }

      return false;
    } catch (e) {
      AppLogger.e('알림 권한 요청 오류', e);
      return false;
    }
  }

  /// 권한 상태 확인
  static Future<Map<String, bool>> checkPermissions() async {
    Map<String, bool> permissions = {};

    // 위치 권한
    LocationPermission locationPermission = await Geolocator.checkPermission();
    permissions['location'] = locationPermission == LocationPermission.whileInUse || 
                              locationPermission == LocationPermission.always;

    // 알림 권한
    NotificationSettings notificationSettings = 
        await FirebaseMessaging.instance.getNotificationSettings();
    permissions['notification'] = 
        notificationSettings.authorizationStatus == AuthorizationStatus.authorized;

    return permissions;
  }
}
