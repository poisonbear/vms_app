import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../models/navigation_history_model.dart';
import '../models/navigation_warning_model.dart';
import '../../weather/models/weather_model.dart';

/// 항행 관련 데이터 소스
class NavigationDatasource {
  const NavigationDatasource({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 항행 이력 조회
  Future<List<NavigationHistoryModel>> getNavigationHistory({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    try {
      final String apiUrl = dotenv.env['kdn_navigation_history_key'] ?? '';

      final Map<String, dynamic> requestData = {};
      if (startDate != null) requestData['start_date'] = startDate;
      if (endDate != null) requestData['end_date'] = endDate;
      if (mmsi != null) requestData['mmsi'] = mmsi;
      if (shipName != null) requestData['ship_name'] = shipName;

      final response = await _apiClient.dio.post(
        apiUrl,
        data: requestData,
      );

      logger.d("Navigation History API URL: $apiUrl");
      logger.d("Navigation History Request: $requestData");
      logger.d("Navigation History Response: ${response.data}");

      if (response.data is List) {
        return (response.data as List)
            .map<NavigationHistoryModel>((json) => NavigationHistoryModel.fromJson(json))
            .toList();
      }

      // Map 형태로 래핑된 경우
      if (response.data is Map && response.data['data'] is List) {
        return (response.data['data'] as List)
            .map<NavigationHistoryModel>((json) => NavigationHistoryModel.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      logger.e("Get navigation history error: $e");
      return [];
    }
  }

  /// 날씨 정보 조회 (파고, 시정)
  Future<WeatherInfoModel?> getWeatherInfo() async {
    try {
      final String apiUrl = dotenv.env['kdn_weather_info_key'] ?? '';

      final response = await _apiClient.dio.get(apiUrl);

      logger.d("Weather Info API URL: $apiUrl");
      logger.d("Weather Info Response: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        return WeatherInfoModel.fromJson(response.data);
      }

      return null;
    } catch (e) {
      logger.e("Get weather info error: $e");
      return null;
    }
  }

  /// 항행경보 조회
  Future<NavigationWarningModel?> getNavigationWarnings() async {
    try {
      final String apiUrl = dotenv.env['kdn_navigation_warnings_key'] ?? '';

      final response = await _apiClient.dio.get(apiUrl);

      logger.d("Navigation Warnings API URL: $apiUrl");
      logger.d("Navigation Warnings Response: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        return NavigationWarningModel.fromJson(response.data);
      }

      return null;
    } catch (e) {
      logger.e("Get navigation warnings error: $e");
      return null;
    }
  }

  /// 기상정보 목록 조회
  Future<List<WeatherModel>> getWeatherList() async {
    try {
      final String apiUrl = dotenv.env['kdn_weather_list_key'] ?? '';

      final response = await _apiClient.dio.get(apiUrl);

      logger.d("Weather List API URL: $apiUrl");
      logger.d("Weather List Response: ${response.data}");

      if (response.data is List) {
        return (response.data as List)
            .map<WeatherModel>((json) => WeatherModel.fromJson(json))
            .toList();
      }

      // Map 형태로 래핑된 경우
      if (response.data is Map && response.data['data'] is List) {
        return (response.data['data'] as List)
            .map<WeatherModel>((json) => WeatherModel.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      logger.e("Get weather list error: $e");
      return [];
    }
  }

  /// 실시간 기상 데이터 조회
  Future<WeatherModel?> getCurrentWeather({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final String apiUrl = dotenv.env['kdn_current_weather_key'] ?? '';

      final Map<String, dynamic> requestData = {};
      if (latitude != null) requestData['lat'] = latitude;
      if (longitude != null) requestData['lng'] = longitude;

      final response = await _apiClient.dio.post(
        apiUrl,
        data: requestData,
      );

      logger.d("Current Weather API URL: $apiUrl");
      logger.d("Current Weather Request: $requestData");
      logger.d("Current Weather Response: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        return WeatherModel.fromJson(response.data);
      }

      return null;
    } catch (e) {
      logger.e("Get current weather error: $e");
      return null;
    }
  }
}