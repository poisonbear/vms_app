// lib/presentation/screens/main/utils/permission_utils.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 위치 권한 요청 유틸리티
class PointRequestUtil {
  static Future<bool> requestPermissionUntilGranted(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('위치 권한이 필요합니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('위치 권한 필요'),
              content: const Text('앱 설정에서 위치 권한을 허용해주세요.'),
              actions: [
                TextButton(
                  child: const Text('확인'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Geolocator.openAppSettings();
                  },
                ),
              ],
            );
          },
        );
      }
      return false;
    }
    
    AppLogger.d('✅ 위치 권한 획득 완료');
    return true;
  }
}

/// 알림 권한 요청 유틸리티
class NotificationRequestUtil {
  static Future<bool> requestPermissionUntilGranted(BuildContext context) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.d('✅ 알림 권한 허용됨');
      return true;
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      AppLogger.d('⚠️ 임시 알림 권한 허용됨');
      return true;
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 권한이 거부되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      AppLogger.d('❌ 알림 권한 거부됨');
      return false;
    }
  }
}
