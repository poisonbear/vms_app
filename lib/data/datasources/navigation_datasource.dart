import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/constants/api_endpoints.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/core/exceptions/result.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/navigation_model.dart';

/// 항행 정보 데이터소스 (기존 RosSource)
class NavigationDataSource {
  final dioRequest = DioRequest();

  /// 항행 이력 조회
  Future<Result<List<NavigationModel>, AppException>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    try {
      final String apiUrl = ApiEndpoints.navigationHistory;

      if (apiUrl.isEmpty) {
        return const Failure(
          GeneralAppException('API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      final Map<String, dynamic> queryParams = {
        'startDate': startDate,
        'endDate': endDate,
        'mmsi': mmsi,
        'shipName': shipName,
      };

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await dioRequest.dio.get(
        apiUrl,
        data: queryParams,
        options: options,
      );

      AppLogger.d('[API Call] Navigation history fetched successfully');

      List<NavigationModel> navigationList = [];

      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        // 디버그: 첫 번째 아이템 확인
        if (items.isNotEmpty) {
          AppLogger.d('Navigation API first item: ${items[0]}');
        }
        navigationList = items.map<NavigationModel>((json) => NavigationModel.fromJson(json)).toList();
      } else if (response.data is List) {
        // 디버그: 첫 번째 아이템 확인
        if ((response.data as List).isNotEmpty) {
          AppLogger.d('Navigation API first item: ${response.data[0]}');
        }
        navigationList = (response.data as List)
            .map<NavigationModel>((json) => NavigationModel.fromJson(json))
            .toList();
      }

      AppLogger.d('Navigation list parsed: ${navigationList.length} items');
      return Success(navigationList);
    } catch (e) {
      AppLogger.e('Navigation API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }

  /// 날씨 정보 조회 (시정/파고)
  Future<Result<WeatherInfo, AppException>> getWeatherInfo() async {
    try {
      final String apiUrl = dotenv.env['kdn_ros_select_visibility_Info'] ?? '';

      AppLogger.d('🌊 Weather API URL: $apiUrl');

      if (apiUrl.isEmpty) {
        AppLogger.e('❌ Weather API URL is empty!');
        return const Failure(
          GeneralAppException('API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      AppLogger.d('🔄 Calling Weather API...');

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        data: {},
      );

      // 🔍 디버그: API 응답 전체 출력
      AppLogger.d('=== Weather API Full Response ===');
      AppLogger.d('Status Code: ${response.statusCode}');
      AppLogger.d('Response Data Type: ${response.data.runtimeType}');

      // JSON 전체 출력 (너무 길면 처음 500자만)
      final responseStr = response.data.toString();
      if (responseStr.length > 500) {
        AppLogger.d('Response Data (first 500 chars): ${responseStr.substring(0, 500)}...');
      } else {
        AppLogger.d('Response Data: $responseStr');
      }

      // Map인 경우 키 확인
      if (response.data is Map) {
        final Map<String, dynamic> responseMap = response.data;
        AppLogger.d('Top Level Keys: ${responseMap.keys.toList()}');

        // 각 주요 키의 값 타입 확인
        responseMap.forEach((key, value) {
          if (value != null) {
            AppLogger.d('  $key: ${value.runtimeType} = ${value.toString().length > 100 ? "${value.toString().substring(0, 100)}..." : value}');
          }
        });

        // data 필드가 있는 경우
        if (responseMap['data'] != null) {
          AppLogger.d('📦 data field found!');
          final data = responseMap['data'];
          if (data is Map) {
            AppLogger.d('  data keys: ${data.keys.toList()}');

            // nowData 상세 확인
            if (data['nowData'] != null) {
              AppLogger.d('  📊 nowData: ${data['nowData']}');
            }

            // waveData 상세 확인
            if (data['waveData'] != null) {
              AppLogger.d('  🌊 waveData: ${data['waveData']}');
            }

            // visibilityData 상세 확인
            if (data['visibilityData'] != null) {
              AppLogger.d('  👁️ visibilityData: ${data['visibilityData']}');
            }
          }
        } else {
          AppLogger.w('⚠️ No "data" field in response');

          // 직접 필드 확인
          if (responseMap.containsKey('wave')) {
            AppLogger.d('  Direct wave field: ${responseMap['wave']}');
          }
          if (responseMap.containsKey('visibility')) {
            AppLogger.d('  Direct visibility field: ${responseMap['visibility']}');
          }
          if (responseMap.containsKey('nowWave')) {
            AppLogger.d('  Direct nowWave field: ${responseMap['nowWave']}');
          }
          if (responseMap.containsKey('nowVisibility')) {
            AppLogger.d('  Direct nowVisibility field: ${responseMap['nowVisibility']}');
          }
        }
      }
      AppLogger.d('=====================================');

      if (response.data != null && response.data is Map) {
        WeatherInfo weatherInfo = WeatherInfo.fromJson(response.data);
        AppLogger.d('✅ Parsed WeatherInfo - wave: ${weatherInfo.wave}, visibility: ${weatherInfo.visibility}');
        AppLogger.d('  Wave alarms: [${weatherInfo.walm1}, ${weatherInfo.walm2}, ${weatherInfo.walm3}, ${weatherInfo.walm4}]');
        AppLogger.d('  Visibility alarms: [${weatherInfo.valm1}, ${weatherInfo.valm2}, ${weatherInfo.valm3}, ${weatherInfo.valm4}]');
        return Success(weatherInfo);
      }

      AppLogger.e('❌ Failed to parse weather data');
      return const Failure(
        DataParsingException('날씨 정보 파싱 실패'),
      );
    } catch (e) {
      AppLogger.e('❌ Weather API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }

  /// 항행 경보 조회
  Future<Result<List<String>, AppException>> getNavigationWarnings() async {
    try {
      final String apiUrl = dotenv.env['kdn_ros_select_navigation_warn_Info'] ?? '';

      if (apiUrl.isEmpty) {
        return const Failure(
          GeneralAppException('API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        data: {},
      );

      if (response.data != null && response.data['data'] != null) {
        final warnings = NavigationWarnings.fromJson(response.data).warnings;
        return Success(warnings);
      }

      return const Success([]);
    } catch (e) {
      AppLogger.e('Navigation Warning API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef RosSource = NavigationDataSource;