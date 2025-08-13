import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../models/auth_model.dart';
import '../cubit/auth_cubit.dart';

/// 인증 데이터 소스
class AuthDatasource {
  const AuthDatasource({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 로그인
  Future<LoginResult> login(LoginRequest request) async {
    try {
      // Firebase 인증
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: request.userId,
        password: request.password,
      );

      String? firebaseToken = await userCredential.user?.getIdToken();
      String? uuid = userCredential.user?.uid;

      if (firebaseToken == null) {
        return const LoginResult(
          isSuccess: false,
          errorMessage: 'Firebase 토큰을 가져올 수 없습니다.',
        );
      }

      // 토큰 저장
      await StorageService.saveFirebaseToken(firebaseToken);

      // 서버 로그인 요청
      final String apiUrl = dotenv.env['kdn_loginForm_key'] ?? '';
      final response = await _apiClient.dio.post(
        apiUrl,
        data: {
          ...request.toJson(),
          'uuid': uuid,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $firebaseToken',
          },
        ),
      );

      logger.d("Login API URL: $apiUrl");
      logger.d("Login Response: ${response.data}");

      if (response.statusCode == 200) {
        String username = response.data['username'];
        await StorageService.saveUsername(username);

        // UUID 저장
        if (response.data.containsKey('uuid')) {
          String uuid = response.data['uuid'];
          await StorageService.saveUuid(uuid);
        }

        // 자동 로그인 설정
        await StorageService.saveAutoLogin(true);

        // 사용자 역할 정보 가져오기
        final userRole = await _getUserRole(username);

        final user = UserModel(
          username: username,
          role: userRole.role,
          mmsi: userRole.mmsi,
          uuid: uuid,
        );

        return LoginResult(
          isSuccess: true,
          user: user,
          username: username,
        );
      } else {
        return LoginResult(
          isSuccess: false,
          errorMessage: response.data['message'] ?? '잘못된 아이디 또는 비밀번호',
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = '아이디 또는 비밀번호를 확인해주세요.';
      if (e.code == 'invalid-credential') {
        errorMessage = '아이디 또는 비밀번호를 확인해주세요.';
      }
      return LoginResult(
        isSuccess: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      logger.e("Login error: $e");
      return LoginResult(
        isSuccess: false,
        errorMessage: '로그인 중 오류가 발생했습니다.',
      );
    }
  }

  /// 자동 로그인
  Future<LoginResult> autoLogin({
    required String token,
    required String fcmToken,
  }) async {
    try {
      final String apiUrl = dotenv.env['kdn_loginForm_key'] ?? '';
      final response = await _apiClient.dio.post(
        apiUrl,
        data: {
          'auto_login': true,
          'fcm_token': fcmToken,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        String? fetchedUsername = response.data['username']?.toString();

        if (fetchedUsername != null && fetchedUsername.isNotEmpty) {
          await StorageService.saveUsername(fetchedUsername);

          // 사용자 역할 정보 가져오기
          final userRole = await _getUserRole(fetchedUsername);

          final user = UserModel(
            username: fetchedUsername,
            role: userRole.role,
            mmsi: userRole.mmsi,
          );

          return LoginResult(
            isSuccess: true,
            user: user,
            username: fetchedUsername,
          );
        } else {
          return const LoginResult(
            isSuccess: false,
            errorMessage: '사용자 정보를 가져올 수 없습니다.',
          );
        }
      } else {
        await StorageService.saveAutoLogin(false);
        return const LoginResult(
          isSuccess: false,
          errorMessage: '자동 로그인에 실패했습니다.',
        );
      }
    } catch (e) {
      logger.e("Auto login error: $e");
      return const LoginResult(
        isSuccess: false,
        errorMessage: '자동 로그인 중 오류가 발생했습니다.',
      );
    }
  }

  /// 사용자 역할 정보 조회
  Future<({String role, int? mmsi})> _getUserRole(String username) async {
    try {
      final String apiUrl = dotenv.env['kdn_usm_select_role_data_key'] ?? '';
      Response roleResponse = await _apiClient.dio.post(
        apiUrl,
        data: {'user_id': username},
      );

      if (roleResponse.statusCode == 200) {
        String role = roleResponse.data['role'];
        int? mmsi = roleResponse.data['mmsi'];

        // 저장소에 저장
        await StorageService.saveUserRole(role);
        if (mmsi != null) {
          await StorageService.saveUserMmsi(mmsi);
        }

        return (role: role, mmsi: mmsi);
      }
    } catch (e) {
      logger.e("Get user role error: $e");
    }

    return (role: '', mmsi: null);
  }

  /// 회원가입
  Future<RegisterResult> register(RegisterRequest request) async {
    try {
      // Firebase 사용자 생성
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: '${request.userId.trim()}@kdn.vms.com',
        password: request.password.trim(),
      );

      String uuid = userCredential.user!.uid;

      // 서버 회원가입 요청
      final String apiUrl = dotenv.env['kdn_usm_insert_membership_key'] ?? '';
      final response = await _apiClient.dio.post(
        apiUrl,
        data: {
          ...request.toJson(),
          'firebase_uuid': uuid,
        },
      );

      if (response.statusCode == 200) {
        return const RegisterResult(isSuccess: true);
      } else {
        return const RegisterResult(
          isSuccess: false,
          errorMessage: '회원가입에 실패했습니다.',
        );
      }
    } catch (e) {
      logger.e("Register error: $e");
      return RegisterResult(
        isSuccess: false,
        errorMessage: '회원가입 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 아이디 중복 확인
  Future<bool> checkUserIdAvailability(String userId) async {
    try {
      final String apiUrl = dotenv.env['kdn_usm_select_membership_search_key'] ?? '';
      final response = await _apiClient.dio.post(
        apiUrl,
        data: {'user_id': userId},
      );

      if (response.data is int) {
        return response.data == 0; // 0이면 사용 가능
      }
      return false;
    } catch (e) {
      logger.e("Check user ID availability error: $e");
      return false;
    }
  }

  /// 이용약관 목록 조회
  Future<List<TermsModel>> getTermsList() async {
    try {
      final String apiUrl = dotenv.env['kdn_usm_select_cmd_key'] ?? '';
      final response = await _apiClient.dio.get(apiUrl);

      logger.d("Terms API URL: $apiUrl");
      logger.d("Terms Response: ${response.data}");

      return (response.data as List)
          .map<TermsModel>((json) => TermsModel.fromJson(json))
          .toList();
    } catch (e) {
      logger.e("Get terms list error: $e");
      return [];
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    await StorageService.clearAll();
    await FirebaseAuth.instance.signOut();
  }
}