import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vms_app/core/utils/utils.dart';
import 'package:vms_app/core/constants/constants.dart';

class MainPermissionHandler {
  static Future<void> requestPermissionsSequentially(
      BuildContext context) async {
    // 위치 권한 확인
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always) {
      AppLogger.d('이미 위치 권한이 허용되어 있습니다.');
    } else {
      await Future.delayed(AppDurations.seconds2);
      if (!context.mounted) return;
      await PointRequestUtil.requestPermissionUntilGranted(context);
    }

    // 알림 권한 확인
    NotificationSettings notifSettings =
        await FirebaseMessaging.instance.getNotificationSettings();
    if (notifSettings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.d('이미 알림 권한이 허용되어 있습니다.');
    } else {
      await Future.delayed(AppDurations.seconds2);
      if (!context.mounted) return;
      await NotificationRequestUtil.requestPermissionUntilGranted(context);
    }
  }
}
