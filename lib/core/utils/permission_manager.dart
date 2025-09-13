import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 권한 관리 기본 클래스
abstract class BasePermissionManager {
  static bool _openedSettings = false;

  static bool get isSettingsOpened => _openedSettings;
  static void resetSettingsFlag() => _openedSettings = false;

  static Future<void> showPermissionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onSettings,
    required VoidCallback onExit,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: onSettings,
              child: const Text('설정 열기'),
            ),
            TextButton(
              onPressed: onExit,
              child: const Text('앱 종료'),
            ),
          ],
        );
      },
    );
  }
}

/// 알림 권한 관리 유틸리티
class NotificationRequestUtil extends BasePermissionManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const String _kPermissionDeniedMessage = '알림 권한이 거부되었습니다.';
  static const String _kPermissionDeniedForeverMessage = '알림 권한이 영구적으로 거부되었습니다.';
  static const String _kPermissionGrantedMessage = '알림 권한이 허용되었습니다.';

  static Future<void> requestPermissionOnStartup() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _logPermissionStatus(settings.authorizationStatus);
    } catch (e) {
      AppLogger.e('알림 권한 요청 오류', e);
    }
  }

  static Future<void> requestPermissionUntilGranted(BuildContext context) async {
    try {
      NotificationSettings settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.d('✅ 이미 알림 권한이 허용되어 있습니다.');
        return;
      }

      bool permissionGranted = false;
      while (!permissionGranted && context.mounted) {
        settings = await _messaging.getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          AppLogger.d('✅ 알림 권한이 허용되었습니다.');
          BasePermissionManager.resetSettingsFlag();
          return;
        }

        bool hasPermission = await _handlePermission(context);
        if (hasPermission) {
          permissionGranted = true;
          BasePermissionManager.resetSettingsFlag();
          AppLogger.d('✅ 알림 권한이 허용되었습니다.');
        } else {
          if (BasePermissionManager.isSettingsOpened) {
            await Future.delayed(AnimationConstants.autoScrollDelay);
            settings = await _messaging.getNotificationSettings();
            if (settings.authorizationStatus == AuthorizationStatus.authorized) {
              permissionGranted = true;
              BasePermissionManager.resetSettingsFlag();
              continue;
            }
          }
          if (context.mounted) {
            await _showRetryPermissionPopup(context);
          }
        }
      }
    } catch (e) {
      AppLogger.e('알림 권한 요청 오류', e);
    }
  }

  static Future<bool> _handlePermission(BuildContext context) async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.d(_kPermissionGrantedMessage);
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (context.mounted) {
          await _showPermissionDeniedPopup(context, _kPermissionDeniedMessage);
        }
        return false;
      } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        if (context.mounted) {
          await _showPermissionDeniedPopup(context, _kPermissionDeniedForeverMessage);
        }
        return false;
      }
      return false;
    } catch (e) {
      AppLogger.e('알림 권한 처리 오류', e);
      return false;
    }
  }

  static Future<void> _showPermissionDeniedPopup(BuildContext context, String message) async {
    if (!context.mounted) return;

    await BasePermissionManager.showPermissionDialog(
      context: context,
      title: '알림 권한 필요',
      message: '$message\n권한을 허용하지 않으면 앱을 사용할 수 없습니다.',
      onSettings: () async {
        BasePermissionManager._openedSettings = true;
        await openAppSettings();
        await Future.delayed(AnimationConstants.autoScrollDelay);

        if (context.mounted) {
          NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            AppLogger.d('알림 권한 허용 확인됨 → 팝업 닫기');
            Navigator.of(context).pop();
            BasePermissionManager.resetSettingsFlag();
          } else {
            AppLogger.d('아직도 권한 거부됨 → 팝업 유지');
          }
        }
      },
      onExit: () => exit(0),
    );
  }

  static Future<void> _showRetryPermissionPopup(BuildContext context) async {
    if (!context.mounted) return;

    NotificationSettings currentSettings = await _messaging.getNotificationSettings();
    if (currentSettings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.d('✅ 이미 알림 권한이 허용됨 - 팝업 표시하지 않음');
      return;
    }

    await BasePermissionManager.showPermissionDialog(
      context: context,
      title: '알림 권한 필요',
      message: '앱을 사용하기 위해 알림 권한이 필요합니다.\n권한을 허용해 주세요.',
      onSettings: () async {
        BasePermissionManager._openedSettings = true;
        await openAppSettings();
        await Future.delayed(AnimationConstants.autoScrollDelay);

        if (context.mounted) {
          NotificationSettings settings = await _messaging.getNotificationSettings();
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            Navigator.of(context).pop();
            BasePermissionManager.resetSettingsFlag();
          }
        }
      },
      onExit: () => exit(0),
    );
  }

  static void _logPermissionStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        AppLogger.d('✅ 알림 권한이 허용되었습니다.');
        break;
      case AuthorizationStatus.denied:
        AppLogger.d('❌ 알림 권한이 거부되었습니다.');
        break;
      case AuthorizationStatus.notDetermined:
        AppLogger.d('⚠️ 알림 권한이 아직 결정되지 않았습니다.');
        break;
      case AuthorizationStatus.provisional:
        AppLogger.d('📌 알림 권한이 임시로 허용되었습니다.');
        break;
    }
  }
}

/// 위치 권한 관리 유틸리티
class PointRequestUtil extends BasePermissionManager {
  static final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  static const String _kPermissionDeniedMessage = '위치 권한이 거부되었습니다.';
  static const String _kPermissionDeniedForeverMessage = '위치 권한이 영구적으로 거부되었습니다.';
  static const String _kPermissionGrantedMessage = '위치 권한이 허용되었습니다.';

  static Future<void> requestPermissionUntilGranted(BuildContext context) async {
    try {
      LocationPermission permission = await _geolocatorPlatform.checkPermission();
      if (_isPermissionGranted(permission)) {
        AppLogger.d('✅ 이미 위치 권한이 허용되어 있습니다.');
        return;
      }

      bool permissionGranted = false;
      while (!permissionGranted && context.mounted) {
        if (BasePermissionManager.isSettingsOpened) {
          await Future.delayed(AnimationConstants.autoScrollDelay);
          permission = await _geolocatorPlatform.checkPermission();
          if (_isPermissionGranted(permission)) {
            AppLogger.d('✅ 위치 권한 허용됨 (설정 복귀 후)');
            BasePermissionManager.resetSettingsFlag();
            return;
          }
        }

        bool hasPermission = await _handlePermission(context);
        if (hasPermission) {
          permissionGranted = true;
          BasePermissionManager.resetSettingsFlag();
          AppLogger.d('✅ 위치 권한 허용됨 (직접 요청)');
          return;
        } else {
          permission = await _geolocatorPlatform.checkPermission();
          if (!_isPermissionGranted(permission) && context.mounted) {
            AppLogger.d('❗ 위치 권한 없음 - 거부 팝업 재표시');
            await _showPermissionDeniedPopup(context, _kPermissionDeniedMessage);
            continue;
          }
        }
      }
    } catch (e) {
      AppLogger.e('위치 권한 요청 오류', e);
    }
  }

  static bool _isPermissionGranted(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<bool> _handlePermission(BuildContext context) async {
    try {
      bool serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          await _showEnableLocationPopup(context);
        }
        return false;
      }

      LocationPermission permission = await _geolocatorPlatform.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocatorPlatform.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            await _showPermissionDeniedPopup(context, _kPermissionDeniedMessage);
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          await _showPermissionDeniedPopup(context, _kPermissionDeniedForeverMessage);
        }
        return false;
      }

      AppLogger.d(_kPermissionGrantedMessage);
      return true;
    } catch (e) {
      AppLogger.e('위치 권한 처리 오류', e);
      return false;
    }
  }

  static Future<void> _showEnableLocationPopup(BuildContext context) async {
    if (!context.mounted) return;

    await BasePermissionManager.showPermissionDialog(
      context: context,
      title: '위치 서비스 필요',
      message: '위치 서비스가 꺼져 있습니다.\n설정에서 위치 서비스를 활성화해 주세요.',
      onSettings: () async {
        await Geolocator.openLocationSettings();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      onExit: () => exit(0),
    );
  }

  static Future<void> _showPermissionDeniedPopup(BuildContext context, String message) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setState) {
            return AlertDialog(
              title: const Text('위치 권한 필요'),
              content: Text('$message\n권한을 허용하지 않으면 앱을 사용할 수 없습니다.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    BasePermissionManager._openedSettings = true;
                    await Geolocator.openAppSettings();

                    bool granted = false;
                    for (int i = 0; i < 5; i++) {
                      await Future.delayed(const Duration(seconds: 1));
                      final permission = await _geolocatorPlatform.checkPermission();
                      if (_isPermissionGranted(permission)) {
                        granted = true;
                        break;
                      }
                    }

                    if (granted && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      BasePermissionManager.resetSettingsFlag();
                    } else {
                      AppLogger.d('❌ 여전히 권한 없음 - 팝업 유지됨');
                    }
                  },
                  child: const Text('설정 열기'),
                ),
                TextButton(
                  onPressed: () => exit(0),
                  child: const Text('앱 종료'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 위치 서비스 - 단일 위치 조회
class LocationService {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.d('위치 서비스가 비활성화되어 있습니다.');
        return null;
      }

      LocationPermission permission = await _geolocatorPlatform.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocatorPlatform.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.d('위치 권한이 거부되었습니다.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.d('위치 권한이 영구적으로 거부되었습니다.');
        return null;
      }

      return await _geolocatorPlatform.getCurrentPosition();
    } catch (e) {
      AppLogger.e('현재 위치 조회 오류', e);
      return null;
    }
  }
}

/// 실시간 위치 업데이트 서비스
class UpdatePoint {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _positionStreamSubscription;

  /// 실시간 위치 업데이트를 위한 Stream 반환
  Stream<Position> toggleListening() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    return _geolocatorPlatform.getPositionStream(locationSettings: locationSettings);
  }

  /// 리소스 정리
  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    AppLogger.d("UpdatePoint disposed");
  }
}