import '../datasources/auth_datasource.dart';
import '../models/auth_model.dart';
import '../cubit/auth_cubit.dart';

/// 인증 관련 데이터 저장소
class AuthRepository {
  const AuthRepository({
    required AuthDatasource datasource,
  }) : _datasource = datasource;

  final AuthDatasource _datasource;

  /// 로그인
  Future<LoginResult> login(LoginRequest request) {
    return _datasource.login(request);
  }

  /// 자동 로그인
  Future<LoginResult> autoLogin({
    required String token,
    required String fcmToken,
  }) {
    return _datasource.autoLogin(token: token, fcmToken: fcmToken);
  }

  /// 회원가입
  Future<RegisterResult> register(RegisterRequest request) {
    return _datasource.register(request);
  }

  /// 아이디 중복 확인
  Future<bool> checkUserIdAvailability(String userId) {
    return _datasource.checkUserIdAvailability(userId);
  }

  /// 이용약관 목록 조회
  Future<List<TermsModel>> getTermsList() {
    return _datasource.getTermsList();
  }

  /// 로그아웃
  Future<void> logout() {
    return _datasource.logout();
  }
}