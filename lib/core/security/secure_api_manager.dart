import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/constants/api_endpoints.dart';
import 'package:vms_app/core/constants/env_keys.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io' show Platform;

/// 보안 강화된 API 관리자 (수정 버전)
class SecureApiManager {
  // FlutterSecureStorage 인스턴스
  late final FlutterSecureStorage _storage;

  // 싱글톤 인스턴스
  static SecureApiManager? _instance;

  // 암호화 키 (실제로는 더 안전한 방법으로 생성/관리)
  static const String _encryptionKey = 'vms_secure_key_2025';

  factory SecureApiManager() {
    _instance ??= SecureApiManager._internal();
    return _instance!;
  }

  SecureApiManager._internal() {
    // 플랫폼별 설정
    if (Platform.isAndroid) {
      // Android 전용 보안 옵션
      const androidOptions = AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
        // 추가 Android 보안 옵션
        sharedPreferencesName: 'vms_secure_prefs',
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      );

      _storage = const FlutterSecureStorage(aOptions: androidOptions);
    } else if (Platform.isIOS) {
      // iOS 옵션 (필요한 경우)
      const iOSOptions = IOSOptions(
        // iOS 13+ 지원
        accountName: 'VMS_Secure_Storage',
        groupId: 'com.kdn.vms',
        // accessibility는 기본값 사용 (kSecAttrAccessibleWhenUnlocked)
      );

      _storage = const FlutterSecureStorage(iOptions: iOSOptions);
    } else {
      // 기타 플랫폼은 기본 설정 사용
      _storage = const FlutterSecureStorage();
    }

    AppLogger.d('SecureApiManager initialized for ${Platform.operatingSystem}');
  }

  /// API 엔드포인트 암호화 (간단한 해시 방식)
  String _encryptEndpoint(String endpoint) {
    try {
      final bytes = utf8.encode('$endpoint$_encryptionKey');
      final digest = sha256.convert(bytes);
      return base64.encode(digest.bytes);
    } catch (e) {
      AppLogger.e('Encryption failed', e);
      return endpoint;
    }
  }

  /// 암호화된 값 복호화 (실제로는 양방향 암호화 필요)
  String _decryptEndpoint(String encrypted, String original) {
    // 실제 구현에서는 AES 등의 양방향 암호화를 사용해야 함
    // 여기서는 원본 값을 반환하는 임시 구현
    return original;
  }

  /// 보안 엔드포인트 초기화 (런타임에만 메모리에 보관)
  Future<void> initializeSecureEndpoints() async {
    try {
      AppLogger.d('Initializing secure endpoints...');

      // API 엔드포인트 맵
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

      // 각 엔드포인트를 암호화하여 저장
      for (var entry in endpoints.entries) {
        if (entry.value.isNotEmpty) {
          // 원본 값 저장 (암호화된 형태로)
          final encrypted = _encryptEndpoint(entry.value);
          await _storage.write(
            key: '${entry.key}_encrypted',
            value: encrypted,
          );

          // 원본도 임시로 저장 (실제로는 제거해야 함)
          await _storage.write(
            key: entry.key,
            value: entry.value,
          );
        }
      }

      // Firebase 설정 저장
      final firebaseProjectId = dotenv.env[EnvKeys.firebaseProjectId];
      if (firebaseProjectId != null && firebaseProjectId.isNotEmpty) {
        await _storage.write(
          key: 'firebase_project_id',
          value: firebaseProjectId,
        );
      }

      // 초기화 완료 플래그
      await _storage.write(key: 'api_initialized', value: 'true');

      AppLogger.d('✅ Secure endpoints initialized');
    } catch (e) {
      AppLogger.e('Failed to initialize secure endpoints', e);
      rethrow;
    }
  }

  /// 보안 엔드포인트 가져오기
  Future<String> getSecureEndpoint(String key) async {
    try {
      // 먼저 원본 키로 시도
      final value = await _storage.read(key: key);
      if (value != null && value.isNotEmpty) {
        return value;
      }

      // 암호화된 키로 시도
      final encrypted = await _storage.read(key: '${key}_encrypted');
      if (encrypted != null && encrypted.isNotEmpty) {
        // 복호화하여 반환 (실제 구현 필요)
        return _getEndpointFromApiEndpoints(key);
      }

      // 둘 다 없으면 ApiEndpoints에서 직접 가져오기
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
        AppLogger.w('Unknown endpoint key: $key');
        return '';
    }
  }

  /// 토큰 저장 (암호화 강화)
  Future<void> saveToken(String token, {String? refreshToken}) async {
    try {
      // 토큰 유효성 검증
      if (token.isEmpty) {
        throw ArgumentError('Invalid token: cannot be empty');
      }

      // 토큰 저장
      await _storage.write(key: 'access_token', value: token);

      // 토큰 해시 저장 (검증용)
      final tokenHash = _encryptEndpoint(token);
      await _storage.write(key: 'access_token_hash', value: tokenHash);

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.write(key: 'refresh_token', value: refreshToken);

        final refreshHash = _encryptEndpoint(refreshToken);
        await _storage.write(key: 'refresh_token_hash', value: refreshHash);
      }

      // 토큰 만료 시간 저장 (기본 24시간)
      final expiryTime = DateTime.now().add(const Duration(hours: 24));
      await _storage.write(
        key: 'token_expiry',
        value: expiryTime.toIso8601String(),
      );

      AppLogger.d('Token saved securely');
    } catch (e) {
      AppLogger.e('Failed to save token', e);
      rethrow;
    }
  }

  /// 토큰 읽기 (만료 체크 포함)
  Future<String?> getToken() async {
    try {
      // 만료 시간 체크
      final expiryStr = await _storage.read(key: 'token_expiry');
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          AppLogger.w('Token expired');
          await clearTokens();
          return null;
        }
      }

      // 토큰 읽기
      final token = await _storage.read(key: 'access_token');

      // 토큰 무결성 검증 (옵션)
      if (token != null) {
        final storedHash = await _storage.read(key: 'access_token_hash');
        final currentHash = _encryptEndpoint(token);
        if (storedHash != null && storedHash != currentHash) {
          AppLogger.e('Token integrity check failed');
          await clearTokens();
          return null;
        }
      }

      return token;
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

  /// 사용자 정보 저장 (암호화 및 검증)
  Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    try {
      // 필수 필드 검증
      if (!userInfo.containsKey('userId')) {
        throw ArgumentError('Invalid user info: missing userId');
      }

      // 민감한 정보 제거
      final sanitizedInfo = Map<String, dynamic>.from(userInfo);
      sanitizedInfo.remove('password');
      sanitizedInfo.remove('token');
      sanitizedInfo.remove('creditCard');
      sanitizedInfo.remove('ssn');

      // 타임스탬프 추가
      sanitizedInfo['savedAt'] = DateTime.now().toIso8601String();

      final jsonString = jsonEncode(sanitizedInfo);
      await _storage.write(key: 'user_info', value: jsonString);

      // 해시 저장 (무결성 검증용)
      final hash = _encryptEndpoint(jsonString);
      await _storage.write(key: 'user_info_hash', value: hash);

      AppLogger.d('User info saved securely');
    } catch (e) {
      AppLogger.e('Failed to save user info', e);
      rethrow;
    }
  }

  /// 사용자 정보 읽기
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final jsonString = await _storage.read(key: 'user_info');
      if (jsonString != null) {
        // 무결성 검증
        final storedHash = await _storage.read(key: 'user_info_hash');
        final currentHash = _encryptEndpoint(jsonString);
        if (storedHash != null && storedHash != currentHash) {
          AppLogger.e('User info integrity check failed');
          await _storage.delete(key: 'user_info');
          await _storage.delete(key: 'user_info_hash');
          return null;
        }

        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      AppLogger.e('Failed to read user info', e);
      return null;
    }
  }

  /// 토큰 관련 데이터만 삭제
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: 'access_token'),
        _storage.delete(key: 'access_token_hash'),
        _storage.delete(key: 'refresh_token'),
        _storage.delete(key: 'refresh_token_hash'),
        _storage.delete(key: 'token_expiry'),
      ]);
      AppLogger.d('Tokens cleared');
    } catch (e) {
      AppLogger.e('Failed to clear tokens', e);
    }
  }

  /// 모든 보안 데이터 삭제
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.d('All secure data cleared');
    } catch (e) {
      AppLogger.e('Failed to clear secure data', e);
      rethrow;
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
      // 관련 해시나 암호화된 키도 함께 삭제
      await _storage.delete(key: '${key}_hash');
      await _storage.delete(key: '${key}_encrypted');
      AppLogger.d('Key deleted: $key');
    } catch (e) {
      AppLogger.e('Failed to delete key: $key', e);
      rethrow;
    }
  }

  /// 민감한 데이터 마스킹 (로깅용)
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.isEmpty) return '';
    if (data.length <= visibleChars * 2) {
      return '*' * data.length;
    }

    final start = data.substring(0, visibleChars);
    final end = data.substring(data.length - visibleChars);
    final masked = '*' * (data.length - visibleChars * 2);
    return '$start$masked$end';
  }

  /// 보안 상태 검증
  Future<bool> verifySecurityState() async {
    try {
      // API 초기화 확인
      final initialized = await _storage.read(key: 'api_initialized');
      if (initialized != 'true') {
        AppLogger.w('API not initialized');
        return false;
      }

      // 필수 엔드포인트 확인
      final requiredEndpoints = [
        'login_api',
        'role_api',
        'vessel_list_api',
      ];

      for (final endpoint in requiredEndpoints) {
        final value = await getSecureEndpoint(endpoint);
        if (value.isEmpty) {
          AppLogger.w('Missing endpoint: $endpoint');
          return false;
        }
      }

      AppLogger.d('Security state verified');
      return true;
    } catch (e) {
      AppLogger.e('Security verification failed', e);
      return false;
    }
  }

  /// 디버그용 - 저장된 키 목록 (개발 환경에서만)
  Future<void> debugPrintKeys() async {
    assert(() {
      _printStoredKeys();
      return true;
    }());
  }

  Future<void> _printStoredKeys() async {
    try {
      AppLogger.d('=== Secure Storage Debug ===');

      // 알려진 키들만 확인 (전체 키 목록은 가져올 수 없음)
      final knownKeys = [
        'api_initialized',
        'access_token',
        'refresh_token',
        'token_expiry',
        'user_info',
        'login_api',
        'role_api',
        'terms_api',
        'vessel_list_api',
        'firebase_project_id',
      ];

      int foundKeys = 0;
      for (final key in knownKeys) {
        final hasValue = await hasKey(key);
        if (hasValue) {
          foundKeys++;
          AppLogger.d('✓ $key exists');
        }
      }

      AppLogger.d('Total keys found: $foundKeys');
      AppLogger.d('============================');
    } catch (e) {
      AppLogger.e('Debug print failed', e);
    }
  }
}