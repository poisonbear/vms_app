import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/constants/constants.dart';
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
        receiveTimeout: AppDurations.seconds100,
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

  /// 🔧 수정: 날씨 정보 조회 (시정/파고) - 원본 필드명 사용
  Future<Result<WeatherInfo, AppException>> getWeatherInfo() async {
    try {
      final String apiUrl = dotenv.env['kdn_ros_select_visibility_Info'] ?? '';

      // 🔧 수정: API URL 검증 추가
      if (apiUrl.isEmpty) {
        AppLogger.e('❌ Weather API URL is empty!');
        return const Failure(
          GeneralAppException('날씨 정보 API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      AppLogger.d('🌊 Weather API URL: $apiUrl');

      final options = Options(
        receiveTimeout: AppDurations.seconds100,
        sendTimeout: AppDurations.seconds30,
      );

      Response? response;

      // 🔧 수정: POST 실패 시 GET도 시도
      try {
        AppLogger.d('🔄 Trying POST request...');
        response = await dioRequest.dio.post(
          apiUrl,
          options: options,
          data: {},
        );
      } catch (postError) {
        AppLogger.w('⚠️ POST failed, trying GET request: $postError');
        try {
          response = await dioRequest.dio.get(
            apiUrl,
            options: options,
          );
        } catch (getError) {
          AppLogger.e('❌ Both POST and GET failed: $getError');
          throw postError; // 원래 POST 에러를 throw
        }
      }

      AppLogger.d('✅ Weather API Response Status: ${response.statusCode}');

      // 🔧 수정: 응답 데이터 상세 로깅 추가
      if (response.data != null) {
        AppLogger.d('📊 Weather API Response Type: ${response.data.runtimeType}');
        final responseStr = response.data.toString();
        if (responseStr.length > 500) {
          AppLogger.d('📄 Weather API Response (truncated): ${responseStr.substring(0, 500)}...');
        } else {
          AppLogger.d('📄 Weather API Response: $responseStr');
        }

        // 🔧 수정: Map 구조 확인
        if (response.data is Map) {
          final Map<String, dynamic> responseMap = response.data;
          AppLogger.d('🔑 Response keys: ${responseMap.keys.toList()}');

          // data 필드 확인
          if (responseMap.containsKey('data')) {
            final data = responseMap['data'];
            AppLogger.d('📦 Found "data" field: ${data.runtimeType}');

            if (data is Map) {
              final dataMap = data as Map<String, dynamic>;
              AppLogger.d('🔑 Data keys: ${dataMap.keys.toList()}');

              // nowData 확인
              if (dataMap.containsKey('nowData')) {
                AppLogger.d('📊 nowData: ${dataMap['nowData']}');
              }

              // waveData 확인
              if (dataMap.containsKey('waveData')) {
                AppLogger.d('🌊 waveData: ${dataMap['waveData']}');
              }

              // visibilityData 확인
              if (dataMap.containsKey('visibilityData')) {
                AppLogger.d('👁️ visibilityData: ${dataMap['visibilityData']}');
              }
            }
          }
        }
      }

      // 🔧 수정: WeatherInfo 파싱 시도
      if (response.data != null && response.data is Map) {
        try {
          WeatherInfo weatherInfo = WeatherInfo.fromJson(response.data);
          AppLogger.d('✅ Successfully parsed WeatherInfo');
          AppLogger.d('  📊 Wave: ${weatherInfo.wave}m');
          AppLogger.d('  👁️ Visibility: ${weatherInfo.visibility}m');
          AppLogger.d('  🌊 Wave alarms: [${weatherInfo.walm1}, ${weatherInfo.walm2}, ${weatherInfo.walm3}, ${weatherInfo.walm4}]');
          AppLogger.d('  👁️ Visibility alarms: [${weatherInfo.valm1}, ${weatherInfo.valm2}, ${weatherInfo.valm3}, ${weatherInfo.valm4}]');
          return Success(weatherInfo);
        } catch (parseError) {
          AppLogger.e('❌ WeatherInfo parsing failed: $parseError');

          // 🔧 수정: 파싱 실패 시 기본값으로 WeatherInfo 생성
          AppLogger.w('⚠️ Creating fallback WeatherInfo with default values');
          final fallbackWeatherInfo = WeatherInfo(
            wave: 0.0,
            visibility: 0.0,
            walm1: 1.0,
            walm2: 2.0,
            walm3: 3.0,
            walm4: 4.0,
            valm1: 5000.0,
            valm2: 3000.0,
            valm3: 1000.0,
            valm4: 500.0,
          );
          return Success(fallbackWeatherInfo);
        }
      }

      AppLogger.e('❌ Invalid response data format');
      return const Failure(
        DataParsingException('날씨 정보 응답 형식이 올바르지 않습니다'),
      );
    } catch (e) {
      AppLogger.e('❌ Weather API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }

  /// 🔧 FIX: 항행 경보 조회 - GET에서 POST로 변경
  Future<Result<List<String>, AppException>> getNavigationWarnings() async {
    try {
      final String apiUrl = dotenv.env['kdn_ros_select_navigation_warn_Info'] ?? '';

      if (apiUrl.isEmpty) {
        AppLogger.e('❌ Navigation Warnings API URL is empty!');
        return const Failure(
          GeneralAppException('항행경보 API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      AppLogger.d('📢 Navigation Warnings API URL: $apiUrl');

      final options = Options(
        receiveTimeout: AppDurations.seconds100,
        sendTimeout: AppDurations.seconds30,
      );

      Response? response;

      // 🔧 FIX: POST 메서드 사용 (GET은 지원하지 않음)
      try {
        AppLogger.d('🔄 Calling Navigation Warnings API (POST)...');
        response = await dioRequest.dio.post(
          apiUrl,
          options: options,
          data: {},  // 빈 body로 POST 요청
        );
      } catch (postError) {
        // POST 실패 시 한번 더 시도 (fallback)
        AppLogger.w('⚠️ POST failed, retrying with different config: $postError');
        try {
          // Content-Type을 명시적으로 설정
          final retryOptions = Options(
            receiveTimeout: AppDurations.seconds100,
            sendTimeout: AppDurations.seconds30,
            headers: {
              'Content-Type': 'application/json',
            },
          );

          response = await dioRequest.dio.post(
            apiUrl,
            options: retryOptions,
            data: null,  // null body로 재시도
          );
        } catch (retryError) {
          AppLogger.e('❌ Navigation Warnings API call failed completely: $retryError');
          // 에러가 나도 빈 리스트 반환 (앱 크래시 방지)
          return const Success([]);
        }
      }

      AppLogger.d('✅ Navigation Warnings API Response Status: ${response.statusCode}');

      // 🔧 수정: 응답 데이터 상세 로깅
      if (response.data != null) {
        AppLogger.d('📊 Navigation Warnings Response Type: ${response.data.runtimeType}');
        final responseStr = response.data.toString();
        if (responseStr.length > 300) {
          AppLogger.d('📄 Navigation Warnings Response (truncated): ${responseStr.substring(0, 300)}...');
        } else {
          AppLogger.d('📄 Navigation Warnings Response: $responseStr');
        }

        // Map 구조 확인
        if (response.data is Map) {
          final Map<String, dynamic> responseMap = response.data;
          AppLogger.d('🔑 Response keys: ${responseMap.keys.toList()}');

          if (responseMap.containsKey('data')) {
            final data = responseMap['data'];
            AppLogger.d('📦 Found "data" field: ${data.runtimeType}');
            if (data is List) {
              AppLogger.d('📋 Data list length: ${data.length}');
              if (data.isNotEmpty) {
                AppLogger.d('📋 First item: ${data[0]}');
              }
            }
          }
        }
      }

      // 🔧 수정: 원본 방식으로 파싱
      if (response.data != null && response.data['data'] != null) {
        try {
          final warnings = NavigationWarnings.fromJson(response.data).warnings;
          AppLogger.d('✅ Parsed ${warnings.length} navigation warnings');
          if (warnings.isNotEmpty) {
            AppLogger.d('📋 First warning: ${warnings[0]}');
          }
          return Success(warnings);
        } catch (parseError) {
          AppLogger.e('❌ NavigationWarnings parsing failed: $parseError');
          return const Success([]); // 파싱 실패 시 빈 리스트 반환
        }
      }

      AppLogger.d('ℹ️ No navigation warnings data found');
      return const Success([]);
    } catch (e) {
      AppLogger.e('❌ Navigation Warning API Error', e);
      // 에러가 나도 빈 리스트 반환 (앱 크래시 방지)
      return const Success([]);
    }
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef RosSource = NavigationDataSource;