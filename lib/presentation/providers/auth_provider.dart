import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 사용자 인증 상태 관리 Provider
/// BaseProvider를 상속하여 일관된 에러 처리 적용
class UserState extends BaseProvider {
  String _role = StringConstants.emptyString;
  int? _mmsi;

  // 초기화 상태 추적
  bool _isInitialized = false;

  // Getters
  String get role => _role;
  int? get mmsi => _mmsi;
  bool get isInitialized => _isInitialized;

  /// 생성자 - 자동으로 저장된 데이터 로드
  UserState() {
    _initializeUser();
  }

  /// 초기 사용자 데이터 로드
  Future<void> _initializeUser() async {
    await loadUserData();
  }

  /// 사용자 역할 설정
  Future<void> setRole(String newRole) async {
    await executeAsync(() async {
      // 먼저 메모리에 값 설정
      final previousRole = _role;
      _role = newRole;

      try {
        // SharedPreferences에 저장
        final prefs = await SharedPreferences.getInstance();
        final success = await prefs.setString(StringConstants.userRoleKey, newRole);

        if (!success) {
          throw Exception('역할 저장 실패');
        }

        AppLogger.i('User role updated: $newRole');
        safeNotifyListeners();
      } catch (e) {
        // 저장 실패 시 이전 값으로 롤백
        _role = previousRole;
        rethrow;
      }
    }, errorMessage: '사용자 역할 저장 중 오류가 발생했습니다', showLoading: false // 백그라운드 작업
        );
  }

  /// MMSI 설정
  Future<void> setMmsi(int? newMmsi) async {
    await executeAsync(() async {
      // 먼저 메모리에 값 설정
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
          throw Exception('MMSI 저장 실패');
        }

        safeNotifyListeners();
      } catch (e) {
        // 저장 실패 시 이전 값으로 롤백
        _mmsi = previousMmsi;
        rethrow;
      }
    }, errorMessage: 'MMSI 저장 중 오류가 발생했습니다', showLoading: false);
  }

  /// 저장된 사용자 데이터 로드
  Future<void> loadUserData() async {
    await executeAsync(() async {
      final prefs = await SharedPreferences.getInstance();

      // 역할 로드
      _role = prefs.getString(StringConstants.userRoleKey) ?? StringConstants.emptyString;

      // MMSI 로드
      _mmsi = prefs.getInt(StringConstants.userMmsiKey);

      _isInitialized = true;

      AppLogger.d('User data loaded - Role: $_role, MMSI: $_mmsi');
      safeNotifyListeners();
    }, errorMessage: '사용자 정보를 불러오는 중 오류가 발생했습니다', showLoading: false);
  }

  /// 사용자 데이터 초기화 (로그아웃 시 사용)
  Future<void> clearUserData() async {
    await executeAsync(() async {
      final prefs = await SharedPreferences.getInstance();

      // SharedPreferences에서 제거
      await Future.wait([
        prefs.remove(StringConstants.userRoleKey),
        prefs.remove(StringConstants.userMmsiKey),
      ]);

      // 메모리에서도 초기화
      _role = StringConstants.emptyString;
      _mmsi = null;
      _isInitialized = false;

      AppLogger.i('User data cleared');
      safeNotifyListeners();
    }, errorMessage: '사용자 정보 초기화 중 오류가 발생했습니다', showLoading: false);
  }

  /// 역할 업데이트 (동기식 - UI 즉시 반영용)
  void updateRoleSync(String newRole) {
    executeSafe(() {
      _role = newRole;
      safeNotifyListeners();
      // 비동기로 저장 시작 (결과 기다리지 않음)
      setRole(newRole);
    });
  }

  /// MMSI 업데이트 (동기식 - UI 즉시 반영용)
  void updateMmsiSync(int? newMmsi) {
    executeSafe(() {
      _mmsi = newMmsi;
      safeNotifyListeners();
      // 비동기로 저장 시작 (결과 기다리지 않음)
      setMmsi(newMmsi);
    });
  }

  /// 사용자가 로그인되어 있는지 확인
  bool get isLoggedIn => _role.isNotEmpty && _role != StringConstants.emptyString;

  /// 사용자가 일반 사용자인지 확인
  bool get isUser => _role == 'ROLE_USER';

  /// 사용자가 관리자인지 확인
  bool get isAdmin => _role == 'ROLE_ADMIN';

  /// 사용자 정보 새로고침
  Future<void> refreshUserData() async {
    clearError();
    await loadUserData();
  }

  /// 디버그용 - 현재 상태 출력
  void printUserState() {
    AppLogger.d('=== UserState Debug ===');
    AppLogger.d('Role: $_role');
    AppLogger.d('MMSI: $_mmsi');
    AppLogger.d('IsInitialized: $_isInitialized');
    AppLogger.d('IsLoggedIn: $isLoggedIn');
    AppLogger.d('HasError: $hasError');
    AppLogger.d('ErrorMessage: ${errorMessage.isNotEmpty ? errorMessage : "none"}');
    AppLogger.d('======================');
  }

  // ============================================
  // 하위 호환성을 위한 메서드 (기존 코드 호환)
  // ============================================

  /// 기존 loadRole 메서드 호환성 유지
  @Deprecated('Use loadUserData instead')
  Future<void> loadRole() => loadUserData();

  @override
  void dispose() {
    AppLogger.d('UserState disposed');
    super.dispose();
  }
}

// ============================================
// 하위 호환성을 위한 별칭 (선택사항)
// 기존 코드에서 UserState를 많이 사용한다면 유지
// ============================================
@Deprecated('Use UserState directly')
typedef AuthProvider = UserState;
