// lib/core/services/security/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 민감한 데이터를 안전하게 저장하는 서비스
///
/// ✅ 기존 SharedPreferences 데이터를 자동으로 마이그레이션합니다.
/// ✅ 현재 프로젝트 구조: login_screen에서 직접 SecureStorage 사용
class SecureStorageService {
  static SecureStorageService? _instance;
  late final FlutterSecureStorage _storage;

  // 저장소 키 상수
  static const String _savedPasswordKey = 'secure_saved_password';
  static const String _savedIdKey = 'secure_saved_id';
  static const String _migrationCompleteKey = 'migration_to_secure_storage_complete';

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

  // ============================================
  // 마이그레이션 (중요!)
  // ============================================

  /// ✅ SharedPreferences에서 SecureStorage로 데이터 마이그레이션
  ///
  /// 앱 시작 시 한 번만 실행됩니다.
  ///
  /// 중요: 현재 프로젝트는 이전에 평문으로 저장하지 않았으므로,
  /// 이 마이그레이션은 향후를 대비한 것입니다.
  /// login_screen.dart에서 이미 SecureStorage를 사용하고 있습니다.
  Future<bool> migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 이미 마이그레이션 완료되었는지 확인
      final migrationComplete = prefs.getBool(_migrationCompleteKey) ?? false;
      if (migrationComplete) {
        AppLogger.d('마이그레이션 이미 완료됨');
        return true;
      }

      AppLogger.i('=== 보안 마이그레이션 확인 시작 ===');

      // ✅ 수정: 실제 프로젝트에서 사용했던 키 확인
      // 'saved_id'와 'saved_pw'는 실제로 존재하지 않을 수 있음
      final oldId = prefs.getString('saved_id');
      final oldPw = prefs.getString('saved_pw');

      if (oldId != null && oldPw != null) {
        // SecureStorage로 이전
        await _storage.write(key: _savedIdKey, value: oldId);
        await _storage.write(key: _savedPasswordKey, value: oldPw);

        AppLogger.i('✅ 로그인 정보가 SecureStorage로 이전되었습니다');

        // 기존 SharedPreferences 데이터 삭제
        await prefs.remove('saved_id');
        await prefs.remove('saved_pw');

        AppLogger.i('✅ 기존 평문 데이터 삭제 완료');
      } else {
        // ✅ 평문 데이터가 없는 경우 (정상 상황)
        AppLogger.i('✅ 마이그레이션할 레거시 데이터 없음 (정상)');
        AppLogger.i('   현재 프로젝트는 이미 SecureStorage를 사용 중입니다');
      }

      // 마이그레이션 완료 플래그 설정
      await prefs.setBool(_migrationCompleteKey, true);

      AppLogger.i('=== 보안 마이그레이션 완료 ===');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('마이그레이션 실패', e, stackTrace);
      // ✅ 마이그레이션 실패해도 앱 계속 실행
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

  // ============================================
  // 디버깅 및 유틸리티
  // ============================================

  /// ✅ SecureStorage에 저장된 데이터 확인 (디버깅용)
  /// 프로덕션에서는 사용하지 말 것!
  Future<bool> hasStoredCredentials() async {
    try {
      final id = await _storage.read(key: _savedIdKey);
      final pw = await _storage.read(key: _savedPasswordKey);
      return id != null && pw != null;
    } catch (e) {
      return false;
    }
  }
}