import 'package:dio/dio.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/core/exceptions/result.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
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
      final String apiUrl = ApiConfig.navigationHistory;

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
        if (items.isNotEmpty) {
          AppLogger.d('Navigation API first item: ${items[0]}');
        }
        navigationList = items
            .map<NavigationModel>((json) => NavigationModel.fromJson(json))
            .toList();
      } else if (response.data is List) {
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
      final String apiUrl = ApiConfig.navigationVisibility;

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

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        data: {},
      );

      AppLogger.d('✅ Weather API Response Status: ${response.statusCode}');

      if (response.data != null && response.data is Map) {
        try {
          WeatherInfo weatherInfo = WeatherInfo.fromJson(response.data);
          AppLogger.d('✅ Successfully parsed WeatherInfo');
          AppLogger.d('  📊 Wave: ${weatherInfo.wave}m');
          AppLogger.d('  👁️ Visibility: ${weatherInfo.visibility}m');
          return Success(weatherInfo);
        } catch (parseError) {
          AppLogger.e('❌ WeatherInfo parsing failed: $parseError');
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

  /// 항행 경보 조회 (메시지 목록)
  Future<Result<List<String>, AppException>> getNavigationWarnings() async {
    try {
      final String apiUrl = ApiConfig.navigationWarnings;

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

      try {
        AppLogger.d('🔄 Calling Navigation Warnings API (POST)...');
        response = await dioRequest.dio.post(
          apiUrl,
          options: options,
          data: {},
        );
      } catch (postError) {
        AppLogger.w('⚠️ POST failed, retrying: $postError');
        try {
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
            data: null,
          );
        } catch (retryError) {
          AppLogger.e('❌ Navigation Warnings API call failed: $retryError');
          return const Success([]);
        }
      }

      AppLogger.d(
          '✅ Navigation Warnings API Response Status: ${response.statusCode}');

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
          return const Success([]);
        }
      }

      AppLogger.d('ℹ️ No navigation warnings data found');
      return const Success([]);
    } catch (e) {
      AppLogger.e('❌ Navigation Warning API Error', e);
      return const Success([]);
    }
  }

  /// 항행 경보 상세 데이터 조회 (지도 표시용)
  Future<Result<List<NavigationWarningModel>, AppException>>
      getNavigationWarningDetails() async {
    try {
      final String apiUrl = ApiConfig.navigationWarnings;

      if (apiUrl.isEmpty) {
        AppLogger.e('❌ Navigation Warning Details API URL is empty!');
        return const Failure(
          GeneralAppException('항행경보 상세 API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      AppLogger.d('📍 Navigation Warning Details API URL: $apiUrl');

      final options = Options(
        receiveTimeout: AppDurations.seconds100,
        sendTimeout: AppDurations.seconds30,
      );

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        data: {},
      );

      AppLogger.d(
          '✅ Navigation Warning Details Response Status: ${response.statusCode}');

      if (response.data != null && response.data is Map) {
        final data = response.data['data'];

        if (data is List) {
          final warningList = data
              .map<NavigationWarningModel>(
                  (json) => NavigationWarningModel.fromJson(json))
              .toList();

          AppLogger.d(
              '✅ Parsed ${warningList.length} navigation warning details');
          if (warningList.isNotEmpty) {
            AppLogger.d('📋 First warning detail: ${warningList[0].areaNm}');
          }

          return Success(warningList);
        }
      }

      AppLogger.d('ℹ️ No navigation warning details found');
      return const Success([]);
    } catch (e) {
      AppLogger.e('❌ Navigation Warning Details API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef RosSource = NavigationDataSource;
