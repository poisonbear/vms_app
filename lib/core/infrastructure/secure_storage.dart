import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';

/// 보안 저장소 관리자
class SecureStorage {
  static const _storage = FlutterSecureStorage();

  // 키 상수
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserMmsi = 'user_mmsi';
  static const String keySessionId = 'session_id';

  /// 값 저장
  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      AppLogger.d('SecureStorage: Written $key');
    } catch (e) {
      AppLogger.e('SecureStorage write error: $e');
      throw const SecurityException('보안 저장소 쓰기 실패');
    }
  }

  /// 값 읽기
  static Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        AppLogger.d('SecureStorage: Read $key');
      }
      return value;
    } catch (e) {
      AppLogger.e('SecureStorage read error: $e');
      return null;
    }
  }

  /// 값 삭제
  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      AppLogger.d('SecureStorage: Deleted $key');
    } catch (e) {
      AppLogger.e('SecureStorage delete error: $e');
    }
  }

  /// 모든 값 삭제
  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.d('SecureStorage: All data cleared');
    } catch (e) {
      AppLogger.e('SecureStorage deleteAll error: $e');
    }
  }

  /// 키 존재 여부 확인
  static Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      AppLogger.e('SecureStorage containsKey error: $e');
      return false;
    }
  }

  /// 토큰 관련 유틸리티
  static Future<void> saveTokens({
    required String authToken,
    String? refreshToken,
  }) async {
    await write(keyAuthToken, authToken);
    if (refreshToken != null) {
      await write(keyRefreshToken, refreshToken);
    }
  }

  static Future<Map<String, String?>> getTokens() async {
    return {
      'authToken': await read(keyAuthToken),
      'refreshToken': await read(keyRefreshToken),
    };
  }

  static Future<void> clearTokens() async {
    await delete(keyAuthToken);
    await delete(keyRefreshToken);
  }

  /// 사용자 정보 관련
  static Future<void> saveUserInfo({
    required String userId,
    int? mmsi,
  }) async {
    await write(keyUserId, userId);
    if (mmsi != null) {
      await write(keyUserMmsi, mmsi.toString());
    }
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    final userId = await read(keyUserId);
    final mmsiStr = await read(keyUserMmsi);

    return {
      'userId': userId,
      'mmsi': mmsiStr != null ? int.tryParse(mmsiStr) : null,
    };
  }

  static Future<void> clearUserInfo() async {
    await delete(keyUserId);
    await delete(keyUserMmsi);
  }

  /// 전체 세션 클리어
  static Future<void> clearSession() async {
    await clearTokens();
    await clearUserInfo();
    await delete(keySessionId);
    AppLogger.i('Session cleared');
  }
}