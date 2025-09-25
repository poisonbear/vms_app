import 'package:dio/dio.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';
import 'package:vms_app/core/exceptions/result.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';

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

      List<RosModel> navigationList = [];
      
      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        navigationList = items.map<RosModel>((json) => RosModel.fromJson(json)).toList();
      } else if (response.data is List) {
        navigationList = (response.data as List)
            .map<RosModel>((json) => RosModel.fromJson(json))
            .toList();
      }

      return Success(navigationList);
    } catch (e) {
      AppLogger.e('Navigation API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }

  Future<Result<WeatherInfo, AppException>> getWeatherInfo() async {
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
        return Success(weatherInfo);
      }

      return const Failure(
        DataParsingException('날씨 정보 파싱 실패'),
      );
    } catch (e) {
      AppLogger.e('Weather API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }

  Future<Result<List<String>, AppException>> getNavigationWarnings() async {
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
