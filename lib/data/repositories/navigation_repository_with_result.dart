import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/utils/error_handler.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';
import 'package:vms_app/data/datasources/remote/navigation_remote_datasource.dart';
import 'package:dio/dio.dart';

/// Result 패턴을 적용한 Repository 예시
class NavigationRepositoryWithResult {
  final RosSource _dataSource = RosSource();

  Future<Result<List<RosModel>, AppException>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    try {
      final result = await _dataSource.getRosList(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
        shipName: shipName,
      );
      return Success(result);
    } on DioException catch (e) {
      return Failure(ErrorHandler.handleDioError(e));
    } catch (e) {
      return Failure(ErrorHandler.handleError(e));
    }
  }

  Future<Result<WeatherInfo, AppException>> getWeatherInfo() async {
    try {
      final result = await _dataSource.getWeatherInfo();
      if (result == null) {
        return const Failure(DataParsingException('날씨 정보를 가져올 수 없습니다'));
      }
      return Success(result);
    } on DioException catch (e) {
      return Failure(ErrorHandler.handleDioError(e));
    } catch (e) {
      return Failure(ErrorHandler.handleError(e));
    }
  }
}
