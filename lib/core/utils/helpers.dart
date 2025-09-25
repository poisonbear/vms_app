import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 일반 헬퍼 함수들
class Helpers {
  Helpers._();

  /// 디바운스 함수
  static Function debounce(Function func, Duration delay) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, () => func());
    };
  }

  /// 스로틀 함수
  static Function throttle(Function func, Duration delay) {
    bool isThrottled = false;
    return () {
      if (!isThrottled) {
        func();
        isThrottled = true;
        Timer(delay, () => isThrottled = false);
      }
    };
  }

  /// 안전한 Future 실행
  static Future<T?> safeFuture<T>(Future<T> Function() function) async {
    try {
      return await function();
    } catch (e) {
      AppLogger.e('Safe future execution failed: $e');
      return null;
    }
  }

  /// 재시도 로직
  static Future<T?> retry<T>({
    required Future<T> Function() function,
    int retries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        return await function();
      } catch (e) {
        if (i == retries - 1) rethrow;
        await Future.delayed(delay * (i + 1));
      }
    }
    return null;
  }
}

/// JSON 파서 유틸리티
class JsonParser {
  JsonParser._();

  static String? parseString(dynamic value, [String? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  static String parseStringNonNull(dynamic value, [String defaultValue = '']) {
    return parseString(value, defaultValue) ?? defaultValue;
  }

  static int? parseInt(dynamic value, [int? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return defaultValue;
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static int parseIntNonNull(dynamic value, [int defaultValue = 0]) {
    return parseInt(value, defaultValue) ?? defaultValue;
  }

  static double? parseDouble(dynamic value, [double? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return defaultValue;
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static double parseDoubleNonNull(dynamic value, [double defaultValue = 0.0]) {
    return parseDouble(value, defaultValue) ?? defaultValue;
  }

  static bool? parseBool(dynamic value, [bool? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return defaultValue;
  }

  static bool parseBoolNonNull(dynamic value, [bool defaultValue = false]) {
    return parseBool(value, defaultValue) ?? defaultValue;
  }

  static List<T>? parseList<T>(
      dynamic value,
      T Function(dynamic) parser, [
        List<T>? defaultValue,
      ]) {
    if (value == null) return defaultValue;
    if (value is! List) return defaultValue;

    try {
      return value.map(parser).toList();
    } catch (e) {
      AppLogger.e('Failed to parse list: $e');
      return defaultValue;
    }
  }

  static List<T> parseListNonNull<T>(
      dynamic value,
      T Function(dynamic) parser, [
        List<T>? defaultValue,
      ]) {
    return parseList(value, parser, defaultValue) ?? defaultValue ?? [];
  }

  static Map<String, dynamic>? parseMap(dynamic value, [Map<String, dynamic>? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        AppLogger.e('Failed to parse map: $e');
        return defaultValue;
      }
    }
    return defaultValue;
  }

  static Map<String, dynamic> parseMapNonNull(dynamic value, [Map<String, dynamic>? defaultValue]) {
    return parseMap(value, defaultValue) ?? defaultValue ?? {};
  }

  static DateTime? parseDateTime(dynamic value, [DateTime? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        AppLogger.e('Failed to parse DateTime: $e');
        return defaultValue;
      }
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return defaultValue;
  }

  static DateTime parseDateTimeNonNull(dynamic value, [DateTime? defaultValue]) {
    return parseDateTime(value, defaultValue) ?? defaultValue ?? DateTime.now();
  }
}

/// 디바이스 정보 헬퍼
class DeviceHelper {
  DeviceHelper._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      AppLogger.e('Failed to get device ID: $e');
      return 'unknown';
    }
  }

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'id': androidInfo.id,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
          'id': iosInfo.identifierForVendor ?? 'unknown',
        };
      }
      return {'platform': 'unknown'};
    } catch (e) {
      AppLogger.e('Failed to get device info: $e');
      return {'platform': 'unknown'};
    }
  }
}

/// 권한 헬퍼
class PermissionHelper {
  PermissionHelper._();

  static Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> checkAndRequestLocationPermission() async {
    if (await checkLocationPermission()) {
      return true;
    }
    return await requestLocationPermission();
  }

  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    return {
      Permission.location: await Permission.location.status,
      Permission.notification: await Permission.notification.status,
      Permission.storage: await Permission.storage.status,
    };
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

/// 네비게이션 헬퍼
class NavigationHelper {
  NavigationHelper._();

  static void navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  static void navigateReplace(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  static void navigateAndRemoveUntil(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => screen),
          (route) => false,
    );
  }

  static void pop(BuildContext context, [dynamic result]) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  static void popToFirst(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// 위치 권한 유틸리티
class PointRequestUtil {
  static Future<bool> requestPermissionUntilGranted(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('위치 권한이 필요합니다'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('설정에서 위치 권한을 활성화해주세요'),
            duration: Duration(seconds: 3),
          ),
        );
        return false;
      }

      AppLogger.d('✅ 위치 권한 획득 완료');
      return true;
    } catch (e) {
      AppLogger.e('위치 권한 요청 오류: $e');
      return false;
    }
  }

  static Future<bool> checkPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }
}

/// 알림 권한 유틸리티
class NotificationRequestUtil {
  static Future<bool> requestPermissionUntilGranted(BuildContext context) async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        AppLogger.d('✅ 알림 권한 획득 완료');
        return true;
      } else {
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알림 권한이 필요합니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        AppLogger.d('❌ 알림 권한 거부됨');
        return false;
      }
    } catch (e) {
      AppLogger.e('알림 권한 요청 오류: $e');
      return false;
    }
  }

  static Future<bool> checkPermission() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }
}

/// 통합 권한 관리자
class PermissionManager {
  static Future<Map<String, bool>> requestAllPermissions(BuildContext context) async {
    final results = <String, bool>{};

    results['location'] = await PointRequestUtil.requestPermissionUntilGranted(context);
    results['notification'] = await NotificationRequestUtil.requestPermissionUntilGranted(context);
    results['camera'] = await _requestPermission(Permission.camera);

    if (await Permission.storage.isDenied) {
      results['storage'] = await _requestPermission(Permission.storage);
    } else {
      results['storage'] = true;
    }

    return results;
  }

  static Future<bool> _requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      return status.isGranted;
    } catch (e) {
      AppLogger.e('Permission request error: $e');
      return false;
    }
  }

  static Future<Map<String, bool>> checkAllPermissions() async {
    final results = <String, bool>{};

    results['location'] = await PointRequestUtil.checkPermission();
    results['notification'] = await NotificationRequestUtil.checkPermission();
    results['camera'] = await Permission.camera.isGranted;
    results['storage'] = await Permission.storage.isGranted;

    return results;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}