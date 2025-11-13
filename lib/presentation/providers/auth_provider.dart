// lib/presentation/providers/auth_provider.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 사용자 인증 상태 관리 Provider
/// BaseProvider를 상속하여 일관된 에러 처리 적용
class AuthProvider extends BaseProvider {
  String _role = StringConstants.emptyString;
  int? _mmsi;
  bool _isInitialized = false;

  // Getters
  String get role => _role;
  int? get mmsi => _mmsi;
  bool get isInitialized => _isInitialized;

  /// 생성자 - 자동으로 저장된 데이터 로드
  AuthProvider() {
    _initializeUser();
  }

  /// 초기 사용자 데이터 로드
  Future<void> _initializeUser() async {
    await loadUserData();
  }

  /// 사용자 역할 설정 (기존 메서드명 유지)
  Future<void> setRole(String newRole) async {
    await executeAsync(() async {
      final previousRole = _role;
      _role = newRole;

      try {
        final prefs = await SharedPreferences.getInstance();
        final success =
            await prefs.setString(StringConstants.userRoleKey, newRole);

        if (!success) {
          throw Exception(ErrorMessages.roleSaveFailed);
        }

        AppLogger.i('User role updated: $newRole');
        safeNotifyListeners();
      } catch (e) {
        _role = previousRole;
        rethrow;
      }
    }, errorMessage: ErrorMessages.roleSaveError, showLoading: false);
  }

  /// MMSI 설정 (기존 메서드명 유지)
  Future<void> setMmsi(int? newMmsi) async {
    await executeAsync(() async {
      final previousMmsi = _mmsi;
      _mmsi = newMmsi;

      try {
        final prefs = await SharedPreferences.getInstance();
        bool success;

        if (newMmsi != null) {
          success = await prefs.setInt(StringConstants.userMmsiKey, newMmsi);
          AppLogger.i('User MMSI updated: $newMmsi');
        } else {
          success = await prefs.remove(StringConstants.userMmsiKey);
          AppLogger.i('User MMSI removed');
        }

        if (!success) {
          throw Exception(ErrorMessages.mmsiSaveFailed);
        }

        safeNotifyListeners();
      } catch (e) {
        _mmsi = previousMmsi;
        rethrow;
      }
    }, errorMessage: ErrorMessages.mmsiSaveError, showLoading: false);
  }

  /// 저장된 사용자 데이터 로드
  Future<void> loadUserData() async {
    await executeAsync(() async {
      final prefs = await SharedPreferences.getInstance();

      _role = prefs.getString(StringConstants.userRoleKey) ??
          StringConstants.emptyString;
      _mmsi = prefs.getInt(StringConstants.userMmsiKey);
      _isInitialized = true;

      AppLogger.d('User data loaded - Role: $_role, MMSI: $_mmsi');
      safeNotifyListeners();
    }, errorMessage: ErrorMessages.userInfoLoadError, showLoading: false);
  }

  /// 사용자 데이터 초기화 (로그아웃 시 사용)
  Future<void> clearUserData() async {
    await executeAsync(() async {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.remove(StringConstants.userRoleKey),
        prefs.remove(StringConstants.userMmsiKey),
      ]);

      _role = StringConstants.emptyString;
      _mmsi = null;
      _isInitialized = false;

      AppLogger.i('User data cleared');
      safeNotifyListeners();
    }, errorMessage: ErrorMessages.userInfoClearError, showLoading: false);
  }

  /// 사용자 정보 새로고침
  Future<void> refreshUserData() async {
    clearError();
    await loadUserData();
  }

  /// 사용자가 로그인되어 있는지 확인
  bool get isLoggedIn =>
      _role.isNotEmpty && _role != StringConstants.emptyString;

  ///일반 사용자인지 확인 (자기 선박만 볼 수 있음)
  bool get isUser => _role == 'ROLE_USER';

  ///시스템 관리자인지 확인 (모든 선박 볼 수 있음)
  bool get isAdmin => _role == 'ROLE_ADMIN';

  ///발전단지 운영자인지 확인 (모든 선박 볼 수 있음)
  bool get isOperator => _role == 'ROLE_OPERATOR';

  ///모든 선박을 볼 수 있는 권한이 있는지 확인
  /// (시스템 관리자 또는 발전단지 운영자)
  bool get canViewAllVessels => isAdmin || isOperator;

  /// 디버그용 - 현재 상태 출력
  void printUserState() {
    AppLogger.d('=== AuthProvider Debug ===');
    AppLogger.d('Role: $_role');
    AppLogger.d('MMSI: $_mmsi');
    AppLogger.d('IsInitialized: $_isInitialized');
    AppLogger.d('IsLoggedIn: $isLoggedIn');
    AppLogger.d('IsUser: $isUser');
    AppLogger.d('IsAdmin: $isAdmin');
    AppLogger.d('IsOperator: $isOperator');
    AppLogger.d('CanViewAllVessels: $canViewAllVessels');
    AppLogger.d('HasError: $hasError');
    AppLogger.d(
        'ErrorMessage: ${errorMessage.isNotEmpty ? errorMessage : "none"}');
    AppLogger.d('==========================');
  }

  @override
  void dispose() {
    AppLogger.d('AuthProvider disposed');
    super.dispose();
  }
}

// ============================================
// 하위 호환성을 위한 별칭
// ============================================
typedef UserState = AuthProvider;
