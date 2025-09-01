#!/bin/bash

# 모든 DataSource에 Result 패턴 적용하는 스크립트

echo "모든 DataSource에 Result 패턴 적용 시작..."

# navigation_remote_datasource.dart 개선
cat > lib/data/datasources/remote/navigation_remote_datasource.dart << 'EEOF'
import 'package:vms_app/core/constants/api_endpoints.dart';
import 'package:vms_app/core/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/errors/error_handler.dart';

class RosSource {
  final dioRequest = DioRequest();

  Future<Result<List<RosModel>, AppException>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    try {
      final String apiUrl = ApiEndpoints.navigationHistory;

      final Map<String, dynamic> queryParams = {
        'startDate': startDate,
        'endDate': endDate,
        'mmsi': mmsi,
        'shipName': shipName
      };

      final options = Options(
        receiveTimeout: const Duration(seconds: 30), // 100초는 너무 김
      );

      final response = await dioRequest.dio.get(
        apiUrl,
        data: queryParams,
        options: options,
      );

      List<RosModel> list = [];
      
      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        list = items.map<RosModel>((json) => RosModel.fromJson(json)).toList();
      } else if (response.data is List) {
        list = (response.data as List)
            .map<RosModel>((json) => RosModel.fromJson(json))
            .toList();
      }

      return Success(list);
    } catch (e) {
      logger.e('Navigation API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }

  Future<Result<WeatherInfo?, AppException>> getWeatherInfo() async {
    try {
      final String apiUrl = ApiEndpoints.navigationVisibility;

      final options = Options(
        receiveTimeout: const Duration(seconds: 30),
      );

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        data: {},
      );

      if (response.data != null && response.data is Map) {
        WeatherInfo weatherInfo = WeatherInfo.fromJson(response.data);
        return Success(weatherInfo);
      }

      return const Success(null);
    } catch (e) {
      logger.e('Weather API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }

  Future<Result<List<String>, AppException>> getNavigationWarnings() async {
    try {
      final String apiUrl = ApiEndpoints.navigationWarnings;

      final options = Options(
        receiveTimeout: const Duration(seconds: 30),
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
      logger.e('Navigation Warnings API Error: $e');
      return const Success([]); // 경고는 실패해도 빈 리스트 반환
    }
  }
}
EEOF

echo "✅ 모든 DataSource에 Result 패턴 적용 완료"
