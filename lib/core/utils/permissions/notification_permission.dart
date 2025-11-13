// lib/core/utils/permissions/notification_permission.dart

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 알림 권한 유틸리티
class NotificationPermissionUtil {
  NotificationPermissionUtil._();

  /// 알림 권한 체크
  static Future<bool> check() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      AppLogger.e('알림 권한 확인 실패: $e');
      return false;
    }
  }

  /// 알림 권한 요청
  static Future<bool> request() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      AppLogger.e('알림 권한 요청 실패: $e');
      return false;
    }
  }

  /// 알림 권한 요청 (UI 포함)
  static Future<bool> requestWithDialog(BuildContext context) async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        AppLogger.d('알림 권한 획득 완료');
        return true;
      } else {
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('알림 권한이 필요합니다'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        AppLogger.d('알림 권한 거부됨');
        return false;
      }
    } catch (e) {
      AppLogger.e('알림 권한 요청 오류: $e');
      return false;
    }
  }

  /// 설정 화면 열기
  static Future<void> openSettings() async {
    // Firebase Messaging은 설정 화면 열기를 직접 지원하지 않음
    AppLogger.w('알림 설정 화면은 시스템 설정에서 직접 열어야 합니다');
  }
}

/// 알림 권한 요청 유틸리티 (기존 코드 호환성)
class NotificationRequestUtil {
  NotificationRequestUtil._();

  /// 알림 권한 요청 (승인될 때까지)
  static Future<bool> requestPermissionUntilGranted(
      BuildContext context) async {
    return await NotificationPermissionUtil.requestWithDialog(context);
  }

  /// 알림 권한 체크
  static Future<bool> checkPermission() async {
    return await NotificationPermissionUtil.check();
  }
}
