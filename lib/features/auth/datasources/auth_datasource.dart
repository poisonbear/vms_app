import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/error/exceptions.dart';
import '../models/auth_model.dart';
import '../cubit/auth_cubit.dart';

/// 인증 데이터 소스 (개선된 버전)
class AuthDatasource {
  const AuthDatasource({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // 설정 상수들
  static const String _defaultEmailDomain = '@kdn.vms.com';
  static const Duration _operationTimeout = Duration(seconds: 30);

  /// 로그인
  Future<LoginResult> login(LoginRequest request) async {
    try {
      // 이메일 형식 변환
      final email = _buildEmail(request.userId);

      // Firebase 인증
      final userCredential = await _performFirebaseSignIn(email, request.password);
      final firebaseToken = await _getFirebaseToken(userCredential.user);

      if (firebaseToken == null) {
        throw const AuthException('Firebase 토큰을 가져올 수 없습니다.');
      }

      // 토큰 저장
      await StorageService.saveFirebaseToken(firebaseToken);

      // 서버 로그인 요청
      final serverResponse = await _performServerLogin(request, userCredential.user?.uid);

      if (serverResponse['success'] == true) {
        final user = await _processSuccessfulLogin(serverResponse, userCredential.user?.uid);
        return LoginResult(isSuccess: true, user: user, username: user.username);
      } else {
        throw AuthException(serverResponse['message'] ?? '로그인에 실패했습니다.');
      }

    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _mapNetworkError(e);
    } catch (e) {
      logger.e("Unexpected login error", error: e);
      throw AuthException('로그인 중 예기치 못한 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 자동 로그인
  Future<LoginResult> autoLogin({
    required String token,
    required String fcmToken,
  }) async {
    try {
      final serverResponse = await _performAutoLogin(token, fcmToken);

      if (serverResponse['success'] == true) {
        final username = serverResponse['username']?.toString();

        if (username?.isNotEmpty == true) {
          await StorageService.saveUsername(username!);
          final userRole = await _getUserRole(username);

          final user = UserModel(
            username: username,
            role: userRole.role,
            mmsi: userRole.mmsi,
          );

          return LoginResult(isSuccess: true, user: user, username: username);
        } else {
          throw const AuthException('사용자 정보를 가져올 수 없습니다.');
        }
      } else {
        await StorageService.saveAutoLogin(false);
        throw AuthException(serverResponse['message'] ?? '자동 로그인에 실패했습니다.');
      }

    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _mapNetworkError(e);
    } catch (e) {
      logger.e("Auto login error", error: e);
      throw AuthException('자동 로그인 중 예기치 못한 오류가 발생했습니다.');
    }
  }

  /// 회원가입
  Future<RegisterResult> register(RegisterRequest request) async {
    try {
      // 이메일 형식 변환
      final email = _buildEmail(request.userId);

      // Firebase 사용자 생성
      final userCredential = await _performFirebaseRegistration(email, request.password);

      // 서버 회원가입 요청
      final serverResponse = await _performServerRegistration(request, userCredential.user!.uid);

      if (serverResponse['success'] == true) {
        return const RegisterResult(isSuccess: true);
      } else {
        // Firebase 사용자 삭제 (서버 등록 실패 시)
        await userCredential.user?.delete();
        throw AuthException(serverResponse['message'] ?? '회원가입에 실패했습니다.');
      }

    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _mapNetworkError(e);
    } catch (e) {
      logger.e("Registration error", error: e);
      throw AuthException('회원가입 중 예기치 못한 오류가 발생했습니다.');
    }
  }

  /// 아이디 중복 확인
  Future<bool> checkUserIdAvailability(String userId) async {
    try {
      final apiUrl = _getApiUrl('kdn_usm_select_membership_search_key');
      final response = await _apiClient.dio.post(
        apiUrl,
        data: {'user_id': userId},
        options: Options(receiveTimeout: _operationTimeout),
      );

      // 응답 타입별 처리
      if (response.data is int) {
        return response.data == 0; // 0이면 사용 가능
      } else if (response.data is Map<String, dynamic>) {
        return response.data['available'] == true;
      }

      return false;
    } on DioException catch (e) {
      throw _mapNetworkError(e);
    } catch (e) {
      logger.e("Check user ID availability error", error: e);
      throw AuthException('아이디 중복 확인 중 오류가 발생했습니다.');
    }
  }

  /// 이용약관 목록 조회
  Future<List<TermsModel>> getTermsList() async {
    try {
      final apiUrl = _getApiUrl('kdn_usm_select_cmd_key');
      final response = await _apiClient.dio.get(
        apiUrl,
        options: Options(receiveTimeout: _operationTimeout),
      );

      if (response.data is List) {
        return (response.data as List)
            .map<TermsModel>((json) => TermsModel.fromJson(json))
            .toList();
      } else if (response.data is Map<String, dynamic> && response.data['data'] is List) {
        return (response.data['data'] as List)
            .map<TermsModel>((json) => TermsModel.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _mapNetworkError(e);
    } catch (e) {
      logger.e("Get terms list error", error: e);
      throw AuthException('이용약관을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      await Future.wait([
        StorageService.clearAll(),
        FirebaseAuth.instance.signOut(),
      ]);
    } catch (e) {
      logger.e("Logout error", error: e);
      // 로그아웃은 실패해도 계속 진행
    }
  }

  // ==================== Private Methods ====================

  /// 이메일 주소 생성
  String _buildEmail(String userId) {
    return userId.contains('@') ? userId : '$userId$_defaultEmailDomain';
  }

  /// API URL 가져오기
  String _getApiUrl(String key) {
    final url = dotenv.env[key];
    if (url == null || url.isEmpty) {
      throw AuthException('API 설정을 찾을 수 없습니다: $key');
    }
    return url;
  }

  /// Firebase 로그인 수행
  Future<UserCredential> _performFirebaseSignIn(String email, String password) async {
    try {
      return await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_operationTimeout);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Firebase 인증 중 오류가 발생했습니다.');
    }
  }

  /// Firebase 회원가입 수행
  Future<UserCredential> _performFirebaseRegistration(String email, String password) async {
    try {
      return await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(_operationTimeout);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Firebase 계정 생성 중 오류가 발생했습니다.');
    }
  }

  /// Firebase 토큰 가져오기
  Future<String?> _getFirebaseToken(User? user) async {
    if (user == null) return null;

    try {
      return await user.getIdToken().timeout(_operationTimeout);
    } catch (e) {
      logger.e("Get Firebase token error", error: e);
      return null;
    }
  }

  /// 서버 로그인 수행
  Future<Map<String, dynamic>> _performServerLogin(LoginRequest request, String? uuid) async {
    final apiUrl = _getApiUrl('kdn_loginForm_key');

    // 요청 데이터 준비 (민감한 정보 제외하고 로깅)
    final requestData = {
      ...request.toJson(),
      'uuid': uuid,
    };

    _logSafeRequest('Server Login', requestData);

    final response = await _apiClient.dio.post(
      apiUrl,
      data: requestData,
      options: Options(
        receiveTimeout: _operationTimeout,
        headers: {'Authorization': 'Bearer ${await StorageService.getFirebaseToken()}'},
      ),
    );

    // 응답 검증
    if (response.statusCode == 200) {
      return {
        'success': true,
        'username': response.data['username'],
        'uuid': response.data['uuid'],
        'data': response.data,
      };
    } else {
      return {
        'success': false,
        'message': response.data['message'] ?? '서버 로그인 실패',
      };
    }
  }

  /// 자동 로그인 수행
  Future<Map<String, dynamic>> _performAutoLogin(String token, String fcmToken) async {
    final apiUrl = _getApiUrl('kdn_loginForm_key');

    final requestData = {
      'auto_login': true,
      'fcm_token': fcmToken,
    };

    _logSafeRequest('Auto Login', requestData);

    final response = await _apiClient.dio.post(
      apiUrl,
      data: requestData,
      options: Options(
        receiveTimeout: _operationTimeout,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'username': response.data['username'],
        'data': response.data,
      };
    } else {
      return {
        'success': false,
        'message': response.data['message'] ?? '자동 로그인 실패',
      };
    }
  }

  /// 서버 회원가입 수행
  Future<Map<String, dynamic>> _performServerRegistration(RegisterRequest request, String uuid) async {
    final apiUrl = _getApiUrl('kdn_usm_insert_membership_key');

    final requestData = {
      ...request.toJson(),
      'firebase_uuid': uuid,
    };

    _logSafeRequest('Server Registration', requestData);

    final response = await _apiClient.dio.post(
      apiUrl,
      data: requestData,
      options: Options(receiveTimeout: _operationTimeout),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'data': response.data};
    } else {
      return {
        'success': false,
        'message': response.data['message'] ?? '서버 회원가입 실패',
      };
    }
  }

  /// 성공적인 로그인 처리
  Future<UserModel> _processSuccessfulLogin(Map<String, dynamic> serverResponse, String? uuid) async {
    final username = serverResponse['username']?.toString();
    if (username == null || username.isEmpty) {
      throw const AuthException('사용자명을 가져올 수 없습니다.');
    }

    await StorageService.saveUsername(username);

    // UUID 저장
    if (serverResponse['uuid'] != null) {
      await StorageService.saveUuid(serverResponse['uuid'].toString());
    }

    // 자동 로그인 설정
    await StorageService.saveAutoLogin(true);

    // 사용자 역할 정보 가져오기
    final userRole = await _getUserRole(username);

    return UserModel(
      username: username,
      role: userRole.role,
      mmsi: userRole.mmsi,
      uuid: uuid,
    );
  }

  /// 사용자 역할 정보 조회
  Future<({String role, int? mmsi})> _getUserRole(String username) async {
    try {
      final apiUrl = _getApiUrl('kdn_usm_select_role_data_key');
      final response = await _apiClient.dio.post(
        apiUrl,
        data: {'user_id': username},
        options: Options(receiveTimeout: _operationTimeout),
      );

      if (response.statusCode == 200 && response.data != null) {
        final role = response.data['role']?.toString() ?? '';
        final mmsi = response.data['mmsi'] as int?;

        // 저장소에 저장
        await Future.wait([
          StorageService.saveUserRole(role),
          if (mmsi != null) StorageService.saveUserMmsi(mmsi),
        ]);

        return (role: role, mmsi: mmsi);
      }
    } catch (e) {
      logger.e("Get user role error", error: e);
    }

    return (role: '', mmsi: null);
  }

  /// Firebase 인증 에러 매핑
  AuthException _mapFirebaseAuthError(FirebaseAuthException error) {
    String message;

    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        message = '아이디 또는 비밀번호를 확인해주세요.';
        break;
      case 'email-already-in-use':
        message = '이미 사용 중인 이메일입니다.';
        break;
      case 'weak-password':
        message = '비밀번호가 너무 약합니다. (6자 이상 입력해주세요)';
        break;
      case 'invalid-email':
        message = '이메일 형식이 올바르지 않습니다.';
        break;
      case 'user-disabled':
        message = '비활성화된 계정입니다. 관리자에게 문의하세요.';
        break;
      case 'too-many-requests':
        message = '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
        break;
      case 'operation-not-allowed':
        message = '허용되지 않은 작업입니다.';
        break;
      case 'network-request-failed':
        message = '네트워크 연결을 확인해주세요.';
        break;
      default:
        message = '인증 오류가 발생했습니다. (${error.code})';
        break;
    }

    return AuthException(message, code: error.code, originalError: error);
  }

  /// 네트워크 에러 매핑
  NetworkException _mapNetworkError(DioException error) {
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = '연결 시간이 초과되었습니다. 다시 시도해주세요.';
        break;
      case DioExceptionType.connectionError:
        message = '네트워크 연결을 확인해주세요.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          message = '인증이 만료되었습니다. 다시 로그인해주세요.';
        } else if (statusCode == 403) {
          message = '접근 권한이 없습니다.';
        } else if (statusCode == 404) {
          message = '서버를 찾을 수 없습니다.';
        } else if (statusCode != null && statusCode >= 500) {
          message = '서버에 일시적인 문제가 발생했습니다.';
        } else {
          message = '서버 오류가 발생했습니다. (상태코드: $statusCode)';
        }
        break;
      default:
        message = '네트워크 오류가 발생했습니다.';
        break;
    }

    return NetworkException(message, originalError: error);
  }

  /// 안전한 요청 로깅 (민감한 정보 제외)
  void _logSafeRequest(String operation, Map<String, dynamic> request) {
    if (!kDebugMode) return;

    final safeRequest = Map<String, dynamic>.from(request);

    // 민감한 정보 제거
    safeRequest.remove('user_pwd');
    safeRequest.remove('password');
    safeRequest.remove('firebase_uuid');
    safeRequest.remove('uuid');

    // 토큰은 일부만 표시
    if (safeRequest.containsKey('fcm_token')) {
      final token = safeRequest['fcm_token']?.toString();
      if (token != null && token.length > 10) {
        safeRequest['fcm_token'] = '${token.substring(0, 10)}...';
      }
    }

    logger.d("$operation Request (sanitized): $safeRequest");
  }

  /// 향상된 로깅 메서드들
  void _logApiCall(String method, String endpoint, {Map<String, dynamic>? data}) {
    LoggerUtils.logApiRequest(method, endpoint, data: data);
  }

  void _logApiResponse(String method, String endpoint, int statusCode, {dynamic data}) {
    LoggerUtils.logApiResponse(method, endpoint, statusCode, data: data);
  }

  /// 인증 흐름 로깅
  void _logAuthFlow(String step, {Map<String, dynamic>? context}) {
    logger.i('🔐 Auth Flow: $step${context != null ? '\nContext: $context' : ''}');
  }

  /// 성능 측정을 위한 로깅
  PerformanceLogger _startPerformanceLogging(String operation) {
    return PerformanceLogger('Auth_$operation');
  }
}