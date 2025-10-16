import 'package:vms_app/domain/repositories/weather_repository.dart' as domain;
import 'package:vms_app/data/datasources/weather_datasource.dart';
import 'package:vms_app/data/models/weather_model.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 날씨 정보 저장소 구현
class WeatherRepository implements domain.WeatherRepository {
  final WeatherDataSource _dataSource;

  WeatherRepository(this._dataSource);

  /// 날씨 정보 목록 조회
  @override
  Future<List<WeatherModel>> getWidList() async {
    final result = await _dataSource.getWidList();

    return result.fold(
      onSuccess: (weatherList) => weatherList,
      onFailure: (error) {
        AppLogger.e('Weather Repository Error: $error');
        return [];
      },
    );
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef WeatherRepositoryImpl = WeatherRepository;
