import 'package:vms_app/core/constants/api_endpoints.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';
import 'package:flutter/foundation.dart';

class RosSource {
  final dioRequest = DioRequest();

  Future<List<RosModel>> getRosList({String? startDate, String? endDate, int? mmsi, String? shipName}) async {
    try {
      final String apiUrl = ApiEndpoints.navigationHistory;

      final Map<String, dynamic> queryParams = {
        'startDate': startDate,
        'endDate': endDate,
        'mmsi': mmsi,
        'shipName': shipName
      };

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await dioRequest.dio.get(apiUrl, data: queryParams, options: options);

      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        return items.map<RosModel>((json) => RosModel.fromJson(json)).toList();
      }

      if (response.data is List) {
        return (response.data as List).map<RosModel>((json) => RosModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      AppLogger.e('Error occurred: $e');
      return [];
    }
  }

  Future<WeatherInfo?> getWeatherInfo() async {
    try {
      final String apiUrl = ApiEndpoints.navigationVisibility;

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        data: {},
      );

      if (response.data != null && response.data is Map) {
        WeatherInfo weatherInfo = WeatherInfo.fromJson(response.data);
        return weatherInfo;
      }

      return null;
    } catch (e) {
      AppLogger.e('Weather API Error: $e');
      return null;
    }
  }

  //항행경보 알림 데이터 가져오기
  Future<List<String>> getNavigationWarnings() async {
    try {
      final String apiUrl = ApiEndpoints.navigationWarnings;

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        data: {},
      );

      // 디버그용 로그 추가
      if (kDebugMode) {
        AppLogger.d('🚢 === 항행경보 API 응답 ===');
        AppLogger.d('Response type: ${response.data.runtimeType}');
        if (response.data != null && response.data['data'] != null) {
          AppLogger.d('Data type: ${response.data['data'].runtimeType}');
          AppLogger.d('Data content: ${response.data['data']}');

          // 각 항목의 구조 확인
          if (response.data['data'] is List) {
            List<dynamic> dataList = response.data['data'];
            for (int i = 0; i < dataList.length && i < 3; i++) {
              AppLogger.d('Item $i type: ${dataList[i].runtimeType}');
              AppLogger.d('Item $i content: ${dataList[i]}');
            }
          }
        }
        AppLogger.d('🚢 =====================');
      }

      if (response.data != null && response.data['data'] != null) {
        return NavigationWarnings.fromJson(response.data).warnings;
      }

      return [];
    } catch (e) {
      AppLogger.e('Navigation Warning API Error: $e');
      return [];
    }
  }
}
