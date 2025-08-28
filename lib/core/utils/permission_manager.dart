import 'dart:async';
import 'package:vms_app/core/constants/constants.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationRequestUtil {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _kNotificationServicesDisabledMessage =
      '알림 서비스가 비활성화되어 있습니다.';
  static const String _kPermissionDeniedMessage = '알림 권한이 거부되었습니다.';
  static const String _kPermissionDeniedForeverMessage =
      '알림 권한이 영구적으로 거부되었습니다.';
  static const String _kPermissionGrantedMessage = '알림 권한이 허용되었습니다.';
  static bool _openedSettings = false; //알림 상태 플래그

  static Future<void> requestPermissionOnStartup() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ 알림 권한이 허용되었습니다.');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ 알림 권한이 거부되었습니다.');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.notDetermined) {
      print('⚠️ 알림 권한이 아직 결정되지 않았습니다.');
    }
  }

  //알림 권한
  static Future<void> requestPermissionUntilGranted(
      BuildContext context) async {
    // 먼저 현재 권한 상태 확인
    NotificationSettings settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ 이미 알림 권한이 허용되어 있습니다.');
      return; // 이미 권한이 있으면 바로 반환
    }

    bool permissionGranted = false;
    while (!permissionGranted) {
      // 매번 루프 시작할 때 권한 상태 재확인
      settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ 알림 권한이 허용되었습니다.');
        return; // 권한이 있으면 즉시 반환
      }

      bool hasPermission = await _handlePermission(context);
      if (hasPermission) {
        permissionGranted = true;
        _openedSettings = false;
        print('✅ 알림 권한이 허용되었습니다.');
      } else {
        // 설정앱에서 돌아온 후 권한 상태 확인
        if (_openedSettings) {
          settings = await _messaging.getNotificationSettings();
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            permissionGranted = true;
            _openedSettings = false;
            continue;
          }
        }

        await _showRetryPermissionPopup(context);
      }
    }
  }

  static Future<bool> _handlePermission(BuildContext context) async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print(_kPermissionGrantedMessage);
      return true;
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      await _showPermissionDeniedPopup(context, _kPermissionDeniedMessage);
      return false;
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.notDetermined) {
      await _showPermissionDeniedPopup(
          context, _kPermissionDeniedForeverMessage);
      return false;
    }

    return false;
  }

// ✅ 권한 거부 팝업
  static Future<void> _showPermissionDeniedPopup(
      BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('알림 권한 필요'),
          content: Text('$message\n권한을 허용하지 않으면 앱을 사용할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () async {
                _openedSettings = true;
                await openAppSettings();
                await Future.delayed(
                    AnimationConstants.autoScrollDelay); // 설정 앱에서 돌아올 시간

                NotificationSettings settings =
                    await FirebaseMessaging.instance.requestPermission();
                if (settings.authorizationStatus ==
                    AuthorizationStatus.authorized) {
                  print('알림 권한 허용 확인됨 → 팝업 닫기');
                  Navigator.of(context).pop();
                  _openedSettings = false;
                } else {
                  print('아직도 권한 거부됨 → 팝업 유지');
                }
              },
              child: const Text('설정 열기'),
            ),
            TextButton(
              onPressed: () {
                exit(0); // 앱 종료
              },
              child: const Text('앱 종료'),
            ),
          ],
        );
      },
    );
  }

// ✅ 권한 재요청 팝업
  static Future<void> _showRetryPermissionPopup(BuildContext context) async {
    // 시작하기 전에 권한 다시 확인
    NotificationSettings currentSettings =
        await _messaging.getNotificationSettings();
    if (currentSettings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ 이미 알림 권한이 허용됨 - 팝업 표시하지 않음');
      return; // 이미 권한이 있으면 팝업 표시하지 않음
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
                _openedSettings = true;
                await openAppSettings();
                await Future.delayed(AnimationConstants.autoScrollDelay);

                // getNotificationSettings() 사용하여 권한만 확인
                NotificationSettings settings =
                    await _messaging.getNotificationSettings();
                if (settings.authorizationStatus ==
                    AuthorizationStatus.authorized) {
                  Navigator.of(context).pop(); // ✅ 팝업 닫기
                  _openedSettings = false; // ✅ 플래그 리셋
                }
              },
              child: const Text('다시 시도'),
            ),
            TextButton(
              onPressed: () {
                exit(0); // 앱 종료
              },
              child: const Text('앱 종료'),
            ),
          ],
        );
      },
    );
  }
}

//////////////////////////
//// 위치 권한 설정 ////////
/////////////////////////

enum _PositionItemType {
  log,
  position,
}

class _PositionItem {
  _PositionItem(this.type, this.displayValue);

  final _PositionItemType type;
  final String displayValue;
}

// 위치 정보 권한 설정
class PointRequestUtil {
  static final GeolocatorPlatform _geolocatorPlatform =
      GeolocatorPlatform.instance;
  static const String _kLocationServicesDisabledMessage =
      '위치 서비스가 비활성화되어 있습니다.';
  static const String _kPermissionDeniedMessage = '위치 권한이 거부되었습니다.';
  static const String _kPermissionDeniedForeverMessage =
      '위치 권한이 영구적으로 거부되었습니다.';
  static const String _kPermissionGrantedMessage = '위치 권한이 허용되었습니다.';

  static bool _openedSettings = false; // 위치 설정 플래그 추가

  static Future<void> requestPermissionUntilGranted(
      BuildContext context) async {
    LocationPermission permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      print('✅ 이미 위치 권한이 허용되어 있습니다.');
      return;
    }

    bool permissionGranted = false;
    while (!permissionGranted) {
      // 🔄 설정 앱 다녀온 경우 먼저 확인
      if (_openedSettings) {
        await Future.delayed(AnimationConstants.autoScrollDelay);
        permission = await _geolocatorPlatform.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          print('✅ 위치 권한 허용됨 (설정 복귀 후)');
          permissionGranted = true;
          _openedSettings = false;
          return;
        }
      }

      // 🔄 권한 직접 요청 시도
      bool hasPermission = await _handlePermission(context);
      if (hasPermission) {
        permissionGranted = true;
        _openedSettings = false;
        print('✅ 위치 권한 허용됨 (직접 요청)');
        return;
      } else {
        // 🔄 권한 여전히 없을 경우 → 안내 반복
        permission = await _geolocatorPlatform.checkPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          print('❗ 위치 권한 없음 - 거부 팝업 재표시');
          await _showPermissionDeniedPopup(context, _kPermissionDeniedMessage);
          continue;
        }
      }
    }
  }

  static Future<bool> _handlePermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showEnableLocationPopup(context);
      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        await _showPermissionDeniedPopup(context, _kPermissionDeniedMessage);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showPermissionDeniedPopup(
          context, _kPermissionDeniedForeverMessage);
      return false;
    }

    print(_kPermissionGrantedMessage);
    return true;
  }

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

  // ✅ 위치 권한 요청 팝업
  static Future<void> _showPermissionDeniedPopup(
      BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('위치 권한 필요'),
              content: Text('$message\n권한을 허용하지 않으면 앱을 사용할 수 없습니다.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    _openedSettings = true;
                    await Geolocator.openAppSettings();

                    bool granted = false;
                    for (int i = 0; i < 5; i++) {
                      await Future.delayed(const Duration(seconds: 1));
                      final permission =
                          await _geolocatorPlatform.checkPermission();
                      if (permission == LocationPermission.whileInUse ||
                          permission == LocationPermission.always) {
                        granted = true;
                        break;
                      }
                    }

                    if (granted) {
                      Navigator.of(context).pop();
                    } else {
                      print('❌ 여전히 권한 없음 - 팝업 유지됨');
                    }
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
      },
    );
  }

  // ✅ 위치 권한 재요청 팝업
  static Future<void> _showRetryPermissionPopup(BuildContext context) async {
    LocationPermission currentPermission =
        await _geolocatorPlatform.checkPermission();
    if (currentPermission == LocationPermission.whileInUse ||
        currentPermission == LocationPermission.always) {
      print('✅ 이미 위치 권한이 허용됨 - 팝업 표시하지 않음');
      return;
    }

    return;
  }
}

// 현재 본인위치 찾기 - 단일
class LocationService {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await _geolocatorPlatform.getCurrentPosition();
  }
}

// 현재 본인위치 찾기 - 실시간
class UpdatePoint {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<_PositionItem> _positionItems = <_PositionItem>[];

  /// 📍 실시간 위치 업데이트를 위한 Stream 반환
  Stream<Position> toggleListening() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    return _geolocatorPlatform.getPositionStream(
        locationSettings: locationSettings);
  }
}
