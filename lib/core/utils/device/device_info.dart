// lib/core/utils/device/device_info.dart

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 디바이스 정보 유틸리티
class DeviceInfoUtil {
  DeviceInfoUtil._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 디바이스 정보 가져오기
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else {
        return {'platform': 'unknown'};
      }
    } catch (e) {
      AppLogger.e('Failed to get device info: $e');
      return {'platform': 'unknown'};
    }
  }

  /// 플랫폼 확인
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWeb => false; // Flutter Web은 별도 처리 필요

  /// 디바이스 모델
  static Future<String> getModel() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.model;
      }
      return 'Unknown';
    } catch (e) {
      AppLogger.e('Failed to get model: $e');
      return 'Unknown';
    }
  }

  /// OS 버전
  static Future<String> getOSVersion() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.systemVersion;
      }
      return 'Unknown';
    } catch (e) {
      AppLogger.e('Failed to get OS version: $e');
      return 'Unknown';
    }
  }
}

/// 디바이스 정보 헬퍼 (기존 코드 호환성)
class DeviceInfo {
  DeviceInfo._();

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    return await DeviceInfoUtil.getDeviceInfo();
  }
}
