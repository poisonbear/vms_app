import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

/// 권한 요청 결과
enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  maxRetriesReached,
  serviceDisabled
}

/// 권한 관리 서비스 (개선된 버전)
class PermissionService {
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // 재시도 카운터 (권한별로 분리)
  static final Map<String, int> _retryCounters = {};

  /// 알림 권한 요청 (안전한 재시도)
  static Future<PermissionResult> requestNotificationPermissionSafely(
      BuildContext context) async {
    const permissionKey = 'notification';

    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 현재 권한 상태 확인
      NotificationSettings settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _resetRetryCounter(permissionKey);
        return PermissionResult.granted;
      }

      // 최대 재시도 횟수 확인
      if (_getRetryCount(permissionKey) >= _maxRetryAttempts) {
        return PermissionResult.maxRetriesReached;
      }

      _incrementRetryCount(permissionKey);

      // 권한 요청
      final result = await _handleNotificationPermission(context);

      if (result == PermissionResult.granted) {
        _resetRetryCounter(permissionKey);
        return PermissionResult.granted;
      }

      // 거부된 경우 사용자에게 선택권 제공
      if (context.mounted) {
        final userChoice = await _showPermissionChoiceDialog(
          context,
          '알림 권한',
          '알림을 받으려면 권한이 필요합니다.',
        );

        switch (userChoice) {
          case UserChoice.retry:
            await Future.delayed(_retryDelay);
            return requestNotificationPermissionSafely(context);
          case UserChoice.settings:
            await openAppSettings();
            return PermissionResult.denied;
          case UserChoice.skip:
            return PermissionResult.denied;
          case UserChoice.exit:
            return _gracefulExit();
        }
      }

      return PermissionResult.denied;
    } catch (e) {
      debugPrint('Notification permission error: $e');
      return PermissionResult.denied;
    }
  }

  /// 위치 권한 요청 (안전한 재시도)
  static Future<PermissionResult> requestLocationPermissionSafely(
      BuildContext context) async {
    const permissionKey = 'location';

    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          final enableService = await _showLocationServiceDialog(context);
          if (!enableService) {
            return PermissionResult.serviceDisabled;
          }
          // 서비스 활성화 후 재확인
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            return PermissionResult.serviceDisabled;
          }
        }
      }

      // 현재 권한 상태 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _resetRetryCounter(permissionKey);
        return PermissionResult.granted;
      }

      // 최대 재시도 횟수 확인
      if (_getRetryCount(permissionKey) >= _maxRetryAttempts) {
        return PermissionResult.maxRetriesReached;
      }

      _incrementRetryCount(permissionKey);

      // 영구 거부 확인
      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          final userChoice = await _showPermissionChoiceDialog(
            context,
            '위치 권한',
            '위치 권한이 영구적으로 거부되었습니다.\n설정에서 권한을 허용해주세요.',
          );

          if (userChoice == UserChoice.settings) {
            await openAppSettings();
          }
        }
        return PermissionResult.permanentlyDenied;
      }

      // 권한 요청
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _resetRetryCounter(permissionKey);
        return PermissionResult.granted;
      }

      // 거부된 경우 사용자에게 선택권 제공
      if (context.mounted) {
        final userChoice = await _showPermissionChoiceDialog(
          context,
          '위치 권한',
          '앱 사용을 위해 위치 권한이 필요합니다.',
        );

        switch (userChoice) {
          case UserChoice.retry:
            await Future.delayed(_retryDelay);
            return requestLocationPermissionSafely(context);
          case UserChoice.settings:
            await openAppSettings();
            return PermissionResult.denied;
          case UserChoice.skip:
            return PermissionResult.denied;
          case UserChoice.exit:
            return _gracefulExit();
        }
      }

      return PermissionResult.denied;
    } catch (e) {
      debugPrint('Location permission error: $e');
      return PermissionResult.denied;
    }
  }

  /// 알림 권한 처리
  static Future<PermissionResult> _handleNotificationPermission(
      BuildContext context) async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return PermissionResult.granted;
      case AuthorizationStatus.denied:
        return PermissionResult.denied;
      case AuthorizationStatus.notDetermined:
        return PermissionResult.denied;
      default:
        return PermissionResult.denied;
    }
  }

  /// 사용자 선택 다이얼로그
  static Future<UserChoice> _showPermissionChoiceDialog(
      BuildContext context,
      String permissionName,
      String message,
      ) async {
    if (!context.mounted) return UserChoice.exit;

    return await showDialog<UserChoice>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionName 필요'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(UserChoice.skip),
              child: const Text('건너뛰기'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(UserChoice.settings),
              child: const Text('설정 열기'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(UserChoice.retry),
              child: const Text('다시 시도'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(UserChoice.exit),
              child: const Text('앱 종료'),
            ),
          ],
        );
      },
    ) ?? UserChoice.exit;
  }

  /// 위치 서비스 활성화 다이얼로그
  static Future<bool> _showLocationServiceDialog(BuildContext context) async {
    if (!context.mounted) return false;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 서비스 필요'),
          content: const Text('위치 서비스가 비활성화되어 있습니다.\n설정에서 위치 서비스를 활성화해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.of(context).pop(true);
              },
              child: const Text('설정 열기'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// 안전한 앱 종료 (exit(0) 대신 사용)
  static PermissionResult _gracefulExit() {
    // iOS에서는 앱 종료가 권장되지 않음
    if (Platform.isIOS) {
      return PermissionResult.denied;
    }

    // Android에서는 앱을 백그라운드로 이동
    SystemNavigator.pop();
    return PermissionResult.denied;
  }

  /// 재시도 카운터 관리
  static int _getRetryCount(String permissionKey) {
    return _retryCounters[permissionKey] ?? 0;
  }

  static void _incrementRetryCount(String permissionKey) {
    _retryCounters[permissionKey] = (_retryCounters[permissionKey] ?? 0) + 1;
  }

  static void _resetRetryCounter(String permissionKey) {
    _retryCounters[permissionKey] = 0;
  }

  /// 모든 재시도 카운터 리셋
  static void resetAllCounters() {
    _retryCounters.clear();
  }

  /// 권한 상태 체크 (디버깅용)
  static Future<Map<String, dynamic>> getPermissionStatus() async {
    final notification = await FirebaseMessaging.instance.getNotificationSettings();
    final location = await Geolocator.checkPermission();
    final locationService = await Geolocator.isLocationServiceEnabled();

    return {
      'notification': notification.authorizationStatus.toString(),
      'location': location.toString(),
      'locationService': locationService,
      'retryCounters': Map<String, int>.from(_retryCounters),
    };
  }
}

/// 사용자 선택 옵션
enum UserChoice { retry, settings, skip, exit }