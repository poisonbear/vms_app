import 'package:shared_preferences/shared_preferences.dart';

/// 로컬 저장소 서비스
class StorageService {
  static const String _keyFirebaseToken = 'firebase_token';
  static const String _keyAutoLogin = 'auto_login';
  static const String _keyUsername = 'username';
  static const String _keyUuid = 'uuid';
  static const String _keySessionId = 'sessionId';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserMmsi = 'user_mmsi';

  static SharedPreferences? _prefs;

  /// SharedPreferences 초기화
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Firebase 토큰 저장
  static Future<void> saveFirebaseToken(String token) async {
    await _ensureInitialized();
    await _prefs!.setString(_keyFirebaseToken, token);
  }

  /// Firebase 토큰 가져오기
  static Future<String?> getFirebaseToken() async {
    await _ensureInitialized();
    return _prefs!.getString(_keyFirebaseToken);
  }

  /// 자동 로그인 설정 저장
  static Future<void> saveAutoLogin(bool autoLogin) async {
    await _ensureInitialized();
    await _prefs!.setBool(_keyAutoLogin, autoLogin);
  }

  /// 자동 로그인 설정 가져오기
  static Future<bool> getAutoLogin() async {
    await _ensureInitialized();
    return _prefs!.getBool(_keyAutoLogin) ?? false;
  }

  /// 사용자명 저장
  static Future<void> saveUsername(String username) async {
    await _ensureInitialized();
    await _prefs!.setString(_keyUsername, username);
  }

  /// 사용자명 가져오기
  static Future<String?> getUsername() async {
    await _ensureInitialized();
    return _prefs!.getString(_keyUsername);
  }

  /// UUID 저장
  static Future<void> saveUuid(String uuid) async {
    await _ensureInitialized();
    await _prefs!.setString(_keyUuid, uuid);
  }

  /// UUID 가져오기
  static Future<String?> getUuid() async {
    await _ensureInitialized();
    return _prefs!.getString(_keyUuid);
  }

  /// 세션 ID 저장
  static Future<void> saveSessionId(String sessionId) async {
    await _ensureInitialized();
    await _prefs!.setString(_keySessionId, sessionId);
  }

  /// 세션 ID 가져오기
  static Future<String?> getSessionId() async {
    await _ensureInitialized();
    return _prefs!.getString(_keySessionId);
  }

  /// 사용자 역할 저장
  static Future<void> saveUserRole(String role) async {
    await _ensureInitialized();
    await _prefs!.setString(_keyUserRole, role);
  }

  /// 사용자 역할 가져오기
  static Future<String?> getUserRole() async {
    await _ensureInitialized();
    return _prefs!.getString(_keyUserRole);
  }

  /// 사용자 MMSI 저장
  static Future<void> saveUserMmsi(int mmsi) async {
    await _ensureInitialized();
    await _prefs!.setInt(_keyUserMmsi, mmsi);
  }

  /// 사용자 MMSI 가져오기
  static Future<int?> getUserMmsi() async {
    await _ensureInitialized();
    return _prefs!.getInt(_keyUserMmsi);
  }

  /// 로그아웃 (모든 데이터 삭제)
  static Future<void> clearAll() async {
    await _ensureInitialized();
    await _prefs!.remove(_keyFirebaseToken);
    await _prefs!.remove(_keyAutoLogin);
    await _prefs!.remove(_keyUsername);
    await _prefs!.remove(_keyUuid);
    await _prefs!.remove(_keySessionId);
    await _prefs!.remove(_keyUserRole);
    await _prefs!.remove(_keyUserMmsi);
  }

  /// SharedPreferences가 초기화되었는지 확인
  static Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  /// 저장된 데이터 디버깅 출력
  static Future<void> debugPrintData() async {
    await _ensureInitialized();
    print("저장된 UUID: ${_prefs!.getString(_keyUuid)}");
    print("저장된 sessionId: ${_prefs!.getString(_keySessionId)}");
    print("저장된 username: ${_prefs!.getString(_keyUsername)}");
    print("저장된 role: ${_prefs!.getString(_keyUserRole)}");
    print("저장된 mmsi: ${_prefs!.getInt(_keyUserMmsi)}");
  }
}