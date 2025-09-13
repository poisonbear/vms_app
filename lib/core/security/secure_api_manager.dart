import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/constants/api_endpoints.dart';
import 'package:vms_app/core/constants/env_keys.dart';
import 'dart:convert';

/// 보안 API 관리자 (확장 버전)
class SecureApiManager {
  // FlutterSecureStorage 인스턴스
  late final FlutterSecureStorage _storage;
  
  // 싱글톤 인스턴스
  static SecureApiManager? _instance;
  
  factory SecureApiManager() {
    _instance ??= SecureApiManager._internal();
    return _instance!;
  }
  
  SecureApiManager._internal() {
    _storage = const FlutterSecureStorage();
  }

  /// 보안 엔드포인트 초기화 (.env에서 읽어옴)
  Future<void> initializeSecureEndpoints() async {
    try {
      AppLogger.d('Initializing secure endpoints from .env...');
      
      // .env에서 엔드포인트 읽어와서 SecureStorage에 저장
      final endpoints = <String, String>{
        'login_api': ApiEndpoints.authLogin,
        'role_api': ApiEndpoints.authRole,
        'terms_api': ApiEndpoints.termsList,
        'vessel_list_api': ApiEndpoints.vesselList,
        'vessel_route_api': ApiEndpoints.vesselRoute,
        'weather_api': ApiEndpoints.weatherInfo,
        'navigation_api': ApiEndpoints.navigationHistory,
        'member_info_api': ApiEndpoints.memberInfo,
        'update_member_api': ApiEndpoints.updateMember,
        'register_api': ApiEndpoints.authRegister,
      };
      
      // 각 엔드포인트를 SecureStorage에 저장
      for (var entry in endpoints.entries) {
        if (entry.value.isNotEmpty) {
          await _storage.write(key: entry.key, value: entry.value);
          AppLogger.d('Saved ${entry.key}');
        }
      }

      // Firebase 설정 저장 (있는 경우)
      final firebaseProjectId = dotenv.env[EnvKeys.firebaseProjectId];
      if (firebaseProjectId != null && firebaseProjectId.isNotEmpty) {
        await _storage.write(key: 'firebase_project_id', value: firebaseProjectId);
      }

      AppLogger.d('✅ Secure endpoints initialized from .env');
    } catch (e) {
      AppLogger.e('Failed to initialize secure endpoints', e);
    }
  }

  /// 보안 엔드포인트 가져오기
  Future<String> getSecureEndpoint(String key) async {
    try {
      // SecureStorage에서 먼저 확인
      final value = await _storage.read(key: key);
      if (value != null && value.isNotEmpty) {
        return value;
      }
      
      // SecureStorage에 없으면 ApiEndpoints에서 직접 가져오기
      return _getEndpointFromApiEndpoints(key);
    } catch (e) {
      AppLogger.e('Error getting secure endpoint: $e');
      return _getEndpointFromApiEndpoints(key);
    }
  }

  /// ApiEndpoints에서 엔드포인트 가져오기 (폴백)
  String _getEndpointFromApiEndpoints(String key) {
    switch (key) {
      case 'login_api':
        return ApiEndpoints.authLogin;
      case 'role_api':
        return ApiEndpoints.authRole;
      case 'terms_api':
        return ApiEndpoints.termsList;
      case 'vessel_list_api':
        return ApiEndpoints.vesselList;
      case 'vessel_route_api':
        return ApiEndpoints.vesselRoute;
      case 'weather_api':
        return ApiEndpoints.weatherInfo;
      case 'navigation_api':
        return ApiEndpoints.navigationHistory;
      case 'member_info_api':
        return ApiEndpoints.memberInfo;
      case 'update_member_api':
        return ApiEndpoints.updateMember;
      case 'register_api':
        return ApiEndpoints.authRegister;
      default:
        return '';
    }
  }

  /// 토큰 저장
  Future<void> saveToken(String token, {String? refreshToken}) async {
    try {
      await _storage.write(key: 'access_token', value: token);
      if (refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: refreshToken);
      }
      AppLogger.d('Token saved securely');
    } catch (e) {
      AppLogger.e('Failed to save token', e);
    }
  }

  /// 토큰 읽기
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'access_token');
    } catch (e) {
      AppLogger.e('Failed to read token', e);
      return null;
    }
  }

  /// 리프레시 토큰 읽기
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: 'refresh_token');
    } catch (e) {
      AppLogger.e('Failed to read refresh token', e);
      return null;
    }
  }

  /// 사용자 정보 저장 (JSON)
  Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    try {
      final jsonString = jsonEncode(userInfo);
      await _storage.write(key: 'user_info', value: jsonString);
      AppLogger.d('User info saved securely');
    } catch (e) {
      AppLogger.e('Failed to save user info', e);
    }
  }

  /// 사용자 정보 읽기
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final jsonString = await _storage.read(key: 'user_info');
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      AppLogger.e('Failed to read user info', e);
      return null;
    }
  }

  /// 모든 보안 데이터 삭제
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.d('All secure data cleared');
    } catch (e) {
      AppLogger.e('Failed to clear secure data', e);
    }
  }

  /// 키 존재 여부 확인
  Future<bool> hasKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      AppLogger.e('Failed to check key existence', e);
      return false;
    }
  }

  /// 특정 키 삭제
  Future<void> deleteKey(String key) async {
    try {
      await _storage.delete(key: key);
      AppLogger.d('Key deleted: $key');
    } catch (e) {
      AppLogger.e('Failed to delete key: $key', e);
    }
  }

  /// 모든 저장된 키 목록 가져오기 (디버그용)
  Future<Map<String, String>> getAllKeys() async {
    try {
      final keys = <String, String>{};
      
      // 알려진 키들 확인
      final knownKeys = [
        'access_token', 'refresh_token', 'user_info',
        'login_api', 'role_api', 'terms_api',
        'vessel_list_api', 'vessel_route_api', 'weather_api',
        'navigation_api', 'member_info_api', 'update_member_api',
        'register_api', 'firebase_project_id'
      ];
      
      for (final key in knownKeys) {
        final value = await _storage.read(key: key);
        if (value != null) {
          // 민감한 정보는 마스킹
          if (key.contains('token') || key.contains('api')) {
            keys[key] = '***${value.length > 10 ? value.substring(value.length - 4) : ""}';
          } else if (key == 'user_info') {
            keys[key] = '[User Data]';
          } else {
            keys[key] = value.length > 20 ? '${value.substring(0, 20)}...' : value;
          }
        }
      }
      
      return keys;
    } catch (e) {
      AppLogger.e('Failed to get all keys', e);
      return {};
    }
  }

  /// 민감한 데이터 마스킹
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars * 2) {
      return '*' * data.length;
    }
    final start = data.substring(0, visibleChars);
    final end = data.substring(data.length - visibleChars);
    final masked = '*' * (data.length - visibleChars * 2);
    return '$start$masked$end';
  }
}
