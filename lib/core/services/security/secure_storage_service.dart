// lib/core/services/security/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 민감한 데이터를 안전하게 저장하는 서비스
class SecureStorageService {
  static SecureStorageService? _instance;
  late final FlutterSecureStorage _storage;

  // 저장소 키 상수
  static const String _savedPasswordKey = 'secure_saved_password';
  static const String _savedIdKey = 'secure_saved_id';
  static const String _firebaseTokenKey = 'secure_firebase_token';
  static const String _uuidKey = 'secure_uuid';
  static const String _migrationCompleteKey =
      'migration_to_secure_storage_complete';

  SecureStorageService._() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }

  factory SecureStorageService() {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  /// 앱 시작 시 한 번만 실행됩니다.
  /// 기존 사용자의 데이터를 안전하게 이전합니다.
  Future<bool> migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final migrationComplete = prefs.getBool(_migrationCompleteKey) ?? false;
      if (migrationComplete) {
        AppLogger.d('마이그레이션 이미 완료됨');
        return true;
      }

      AppLogger.i('=== 데이터 마이그레이션 시작 ===');

      // 기존 데이터 읽기
      final oldId = prefs.getString('saved_id');
      final oldPw = prefs.getString('saved_pw');
      final oldFirebaseToken = prefs.getString('firebase_token');
      final oldUuid = prefs.getString('uuid');

      // SecureStorage로 이전
      if (oldId != null && oldPw != null) {
        await _storage.write(key: _savedIdKey, value: oldId);
        await _storage.write(key: _savedPasswordKey, value: oldPw);
        AppLogger.i('로그인 정보가 SecureStorage로 이전되었습니다');
      }

      if (oldFirebaseToken != null) {
        await _storage.write(key: _firebaseTokenKey, value: oldFirebaseToken);
        AppLogger.i('Firebase 토큰이 SecureStorage로 이전되었습니다');
      }

      if (oldUuid != null) {
        await _storage.write(key: _uuidKey, value: oldUuid);
        AppLogger.i('UUID가 SecureStorage로 이전되었습니다');
      }

      // 기존 SharedPreferences 데이터 삭제
      await Future.wait([
        prefs.remove('saved_id'),
        prefs.remove('saved_pw'),
        prefs.remove('firebase_token'),
        prefs.remove('uuid'),
      ]);

      AppLogger.i('기존 평문 데이터 삭제 완료');

      await prefs.setBool(_migrationCompleteKey, true);

      AppLogger.i('=== 데이터 마이그레이션 완료 ===');
      return true;
    } catch (e) {
      AppLogger.e('마이그레이션 실패', e);
      return false;
    }
  }

  // ============================================
  // 비밀번호 관리
  // ============================================

  /// 비밀번호 저장
  Future<bool> savePassword(String password) async {
    try {
      await _storage.write(key: _savedPasswordKey, value: password);
      AppLogger.i('비밀번호가 안전하게 저장되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('비밀번호 저장 실패', e);
      return false;
    }
  }

  /// 비밀번호 로드
  Future<String?> loadPassword() async {
    try {
      return await _storage.read(key: _savedPasswordKey);
    } catch (e) {
      AppLogger.e('비밀번호 로드 실패', e);
      return null;
    }
  }

  /// 비밀번호 삭제
  Future<bool> deletePassword() async {
    try {
      await _storage.delete(key: _savedPasswordKey);
      AppLogger.i('저장된 비밀번호가 삭제되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('비밀번호 삭제 실패', e);
      return false;
    }
  }

  // ============================================
  // ID 관리
  // ============================================

  /// ID 저장
  Future<bool> saveId(String id) async {
    try {
      await _storage.write(key: _savedIdKey, value: id);
      AppLogger.i('ID가 안전하게 저장되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('ID 저장 실패', e);
      return false;
    }
  }

  /// ID 로드
  Future<String?> loadId() async {
    try {
      return await _storage.read(key: _savedIdKey);
    } catch (e) {
      AppLogger.e('ID 로드 실패', e);
      return null;
    }
  }

  /// ID 삭제
  Future<bool> deleteId() async {
    try {
      await _storage.delete(key: _savedIdKey);
      AppLogger.i('저장된 ID가 삭제되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('ID 삭제 실패', e);
      return false;
    }
  }

  // ============================================
  // Firebase 토큰 관리 (새로 추가)
  // ============================================

  /// Firebase 토큰 저장
  Future<bool> saveFirebaseToken(String token) async {
    try {
      await _storage.write(key: _firebaseTokenKey, value: token);
      AppLogger.i('Firebase 토큰이 안전하게 저장되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('Firebase 토큰 저장 실패', e);
      return false;
    }
  }

  /// Firebase 토큰 로드
  Future<String?> loadFirebaseToken() async {
    try {
      return await _storage.read(key: _firebaseTokenKey);
    } catch (e) {
      AppLogger.e('Firebase 토큰 로드 실패', e);
      return null;
    }
  }

  /// Firebase 토큰 삭제
  Future<bool> deleteFirebaseToken() async {
    try {
      await _storage.delete(key: _firebaseTokenKey);
      AppLogger.i('Firebase 토큰이 삭제되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('Firebase 토큰 삭제 실패', e);
      return false;
    }
  }

  // ============================================
  // UUID 관리 (새로 추가)
  // ============================================

  /// UUID 저장
  Future<bool> saveUuid(String uuid) async {
    try {
      await _storage.write(key: _uuidKey, value: uuid);
      AppLogger.i('UUID가 안전하게 저장되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('UUID 저장 실패', e);
      return false;
    }
  }

  /// UUID 로드
  Future<String?> loadUuid() async {
    try {
      return await _storage.read(key: _uuidKey);
    } catch (e) {
      AppLogger.e('UUID 로드 실패', e);
      return null;
    }
  }

  /// UUID 삭제
  Future<bool> deleteUuid() async {
    try {
      await _storage.delete(key: _uuidKey);
      AppLogger.i('UUID가 삭제되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('UUID 삭제 실패', e);
      return false;
    }
  }

  // ============================================
  // 편의 메서드
  // ============================================

  /// 로그인 정보 일괄 저장
  Future<bool> saveCredentials({
    required String id,
    required String password,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _savedIdKey, value: id),
        _storage.write(key: _savedPasswordKey, value: password),
      ]);
      AppLogger.i('로그인 정보가 안전하게 저장되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('로그인 정보 저장 실패', e);
      return false;
    }
  }

  /// 로그인 정보 일괄 로드
  Future<Map<String, String?>> loadCredentials() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _savedIdKey),
        _storage.read(key: _savedPasswordKey),
      ]);

      return {
        'id': results[0],
        'password': results[1],
      };
    } catch (e) {
      AppLogger.e('로그인 정보 로드 실패', e);
      return {'id': null, 'password': null};
    }
  }

  /// 로그인 정보 일괄 삭제
  Future<bool> deleteCredentials() async {
    try {
      await Future.wait([
        _storage.delete(key: _savedIdKey),
        _storage.delete(key: _savedPasswordKey),
      ]);
      AppLogger.i('로그인 정보가 삭제되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('로그인 정보 삭제 실패', e);
      return false;
    }
  }

  ///세션 정보 일괄 저장 (토큰 + UUID)
  Future<bool> saveSessionData({
    required String firebaseToken,
    required String uuid,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _firebaseTokenKey, value: firebaseToken),
        _storage.write(key: _uuidKey, value: uuid),
      ]);
      AppLogger.i('세션 정보가 안전하게 저장되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('세션 정보 저장 실패', e);
      return false;
    }
  }

  ///세션 정보 일괄 로드 (토큰 + UUID)
  Future<Map<String, String?>> loadSessionData() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _firebaseTokenKey),
        _storage.read(key: _uuidKey),
      ]);

      return {
        'firebaseToken': results[0],
        'uuid': results[1],
      };
    } catch (e) {
      AppLogger.e('세션 정보 로드 실패', e);
      return {'firebaseToken': null, 'uuid': null};
    }
  }

  ///세션 정보 일괄 삭제 (토큰 + UUID)
  Future<bool> deleteSessionData() async {
    try {
      await Future.wait([
        _storage.delete(key: _firebaseTokenKey),
        _storage.delete(key: _uuidKey),
      ]);
      AppLogger.i('세션 정보가 삭제되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('세션 정보 삭제 실패', e);
      return false;
    }
  }

  /// 모든 보안 데이터 삭제 (로그아웃 시 사용)
  Future<bool> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.i('모든 보안 데이터가 삭제되었습니다');
      return true;
    } catch (e) {
      AppLogger.e('보안 데이터 삭제 실패', e);
      return false;
    }
  }
}
