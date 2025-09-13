import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/security/secure_api_manager.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/network/dio_client.dart';

/// 보안 강화된 API 서비스
class SecureApiService {
  static final SecureApiService _instance = SecureApiService._internal();
  factory SecureApiService() => _instance;
  SecureApiService._internal();

  final _secureManager = SecureApiManager();
  final _dioRequest = DioRequest();

  /// API URL 가져오기 (Secure Storage 우선, .env fallback)
  Future<String> getApiUrl(String secureKey, String envKey) async {
    try {
      // 1. Secure Storage에서 시도
      final secureUrl = await _secureManager.getSecureEndpoint(secureKey);
      if (secureUrl.isNotEmpty) {
        AppLogger.d('Using secure endpoint for $secureKey');
        return secureUrl;
      }
    } catch (e) {
      AppLogger.w('Secure storage failed for $secureKey, falling back to .env');
    }

    // 2. .env에서 fallback
    final envUrl = dotenv.env[envKey] ?? '';
    if (envUrl.isEmpty) {
      AppLogger.e('No API URL found for $envKey');
    }
    return envUrl;
  }

  /// 로그인 API
  Future<Response> login({
    required String userId,
    required String password,
    required bool autoLogin,
    required String fcmToken,
    String? uuid,
    String? firebaseToken,
  }) async {
    final apiUrl = await getApiUrl('login_api', 'kdn_loginForm_key');

    if (apiUrl.isEmpty) {
      throw Exception('Login API URL not configured');
    }

    AppLogger.api('POST', apiUrl, {
      'user_id': AppLogger.maskSensitive(userId),
      'user_pwd': '[HIDDEN]',
      'auto_login': autoLogin,
    });

    try {
      final response = await _dioRequest.dio.post(
        apiUrl,
        data: {
          'user_id': userId,
          'user_pwd': password,
          'auto_login': autoLogin,
          'fcm_tkn': fcmToken,
          'uuid': uuid,
        },
        options: Options(
          headers: firebaseToken != null ? {'Authorization': 'Bearer $firebaseToken'} : null,
        ),
      );

      AppLogger.i('Login successful');
      return response;
    } catch (e) {
      AppLogger.e('Login failed', e);
      rethrow;
    }
  }

  /// 사용자 역할 조회 API
  Future<Response> getUserRole(String username) async {
    final apiUrl = await getApiUrl('role_api', 'kdn_usm_select_role_data_key');

    if (apiUrl.isEmpty) {
      throw Exception('Role API URL not configured');
    }

    AppLogger.api('POST', apiUrl, {'user_id': AppLogger.maskSensitive(username)});

    try {
      final response = await _dioRequest.dio.post(
        apiUrl,
        data: {'user_id': username},
      );

      AppLogger.i('User role fetched successfully');
      return response;
    } catch (e) {
      AppLogger.e('Failed to fetch user role', e);
      rethrow;
    }
  }

  /// 약관 목록 조회 API
  Future<Response> getTermsList() async {
    final apiUrl = await getApiUrl('terms_api', 'kdn_usm_select_cmd_key');

    if (apiUrl.isEmpty) {
      throw Exception('Terms API URL not configured');
    }

    AppLogger.api('GET', apiUrl);

    try {
      final response = await _dioRequest.dio.get(apiUrl);
      AppLogger.i('Terms list fetched successfully');
      return response;
    } catch (e) {
      AppLogger.e('Failed to fetch terms list', e);
      rethrow;
    }
  }

  /// 선박 목록 조회 API
  Future<Response> getVesselList({String? regDt, int? mmsi}) async {
    final apiUrl = await getApiUrl('vessel_list_api', 'kdn_gis_select_vessel_List');

    if (apiUrl.isEmpty) {
      throw Exception('Vessel API URL not configured');
    }

    AppLogger.api('GET', apiUrl, {'regDt': regDt, 'mmsi': mmsi});

    try {
      final response = await _dioRequest.dio.get(
        apiUrl,
        queryParameters: {
          if (regDt != null) 'reg_dt': regDt,
          if (mmsi != null) 'mmsi': mmsi,
        },
      );

      AppLogger.i('Vessel list fetched successfully');
      return response;
    } catch (e) {
      AppLogger.e('Failed to fetch vessel list', e);
      rethrow;
    }
  }
}
