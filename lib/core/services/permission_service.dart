import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

/// 권한 관리 서비스
class PermissionService {
  /// 알림 권한 요청 (계속 시도)
  static Future<void> requestNotificationPermissionUntilGranted(
      BuildContext context) async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 현재 권한 상태 확인
    NotificationSettings settings = await messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ 이미 알림 권한이 허용되어 있습니다.");
      return;
    }

    bool permissionGranted = false;
    bool openedSettings = false;

    while (!permissionGranted) {
      // 매번 루프 시작할 때 권한 상태 재확인
      settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print("✅ 알림 권한이 허용되었습니다.");
        return;
      }

      bool hasPermission = await _handleNotificationPermission(context);
      if (hasPermission) {
        permissionGranted = true;
        openedSettings = false;
        print("✅ 알림 권한이 허용되었습니다.");
      } else {
        // 설정앱에서 돌아온 후 권한 상태 확인
        if (openedSettings) {
          settings = await messaging.getNotificationSettings();
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            permissionGranted = true;
            openedSettings = false;
            continue;
          }
        }

        await _showRetryNotificationPermissionPopup(context);
      }
    }
  }

  /// 위치 권한 요청 (계속 시도)
  static Future<void> requestLocationPermissionUntilGranted(
      BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      print("✅ 이미 위치 권한이 허용되어 있습니다.");
      return;
    }

    bool permissionGranted = false;
    bool openedSettings = false;

    while (!permissionGranted) {
      // 설정 앱 다녀온 경우 먼저 확인
      if (openedSettings) {
        await Future.delayed(const Duration(seconds: 2));
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          print("✅ 위치 권한 허용됨 (설정 복귀 후)");
          permissionGranted = true;
          openedSettings = false;
          return;
        }
      }

      bool hasPermission = await _handleLocationPermission(context);
      if (hasPermission) {
        permissionGranted = true;
        openedSettings = false;
        print("✅ 위치 권한 허용됨 (직접 요청)");
        return;
      } else {
        permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          print("❗ 위치 권한 없음 - 거부 팝업 재표시");
          await _showPermissionDeniedPopup(
              context, '위치 권한이 거부되었습니다.');
          continue;
        }
      }
    }
  }

  /// 알림 권한 처리
  static Future<bool> _handleNotificationPermission(BuildContext context) async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ 알림 권한이 허용되었습니다.');
      return true;
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      await _showPermissionDeniedPopup(context, '알림 권한이 거부되었습니다.');
      return false;
    } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      await _showPermissionDeniedPopup(context, '알림 권한이 영구적으로 거부되었습니다.');
      return false;
    }

    return false;
  }

  /// 위치 권한 처리
  static Future<bool> _handleLocationPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showEnableLocationPopup(context);
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await _showPermissionDeniedPopup(context, '위치 권한이 거부되었습니다.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showPermissionDeniedPopup(context, '위치 권한이 영구적으로 거부되었습니다.');
      return false;
    }

    print('✅ 위치 권한이 허용되었습니다.');
    return true;
  }

  /// 위치 서비스 활성화 팝업
  static Future<void> _showEnableLocationPopup(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 서비스 필요'),
          content: const Text('위치 서비스가 꺼져 있습니다.\n설정에서 위치 서비스를 활성화해 주세요.'),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.of(context).pop();
              },
              child: const Text('설정 열기'),
            ),
            TextButton(
              onPressed: () {
                exit(0);
              },
              child: const Text('앱 종료'),
            ),
          ],
        );
      },
    );
  }

  /// 권한 거부 팝업
  static Future<void> _showPermissionDeniedPopup(
      BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('권한 필요'),
          content: Text('$message\n권한을 허용하지 않으면 앱을 사용할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () async {
                await openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('설정 열기'),
            ),
            TextButton(
              onPressed: () {
                exit(0);
              },
              child: const Text('앱 종료'),
            ),
          ],
        );
      },
    );
  }

  /// 알림 권한 재요청 팝업
  static Future<void> _showRetryNotificationPermissionPopup(
      BuildContext context) async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 시작하기 전에 권한 다시 확인
    NotificationSettings currentSettings = await messaging.getNotificationSettings();
    if (currentSettings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ 이미 알림 권한이 허용됨 - 팝업 표시하지 않음");
      return;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('알림 권한 필요'),
          content: const Text('앱을 사용하기 위해 알림 권한이 필요합니다.\n권한을 허용해 주세요.'),
          actions: [
            TextButton(
              onPressed: () async {
                await openAppSettings();
                await Future.delayed(const Duration(seconds: 2));

                NotificationSettings settings = await messaging.getNotificationSettings();
                if (settings.authorizationStatus == AuthorizationStatus.authorized) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('다시 시도'),
            ),
            TextButton(
              onPressed: () {
                exit(0);
              },
              child: const Text('앱 종료'),
            ),
          ],
        );
      },
    );
  }
}