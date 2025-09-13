import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/data/datasources/remote/weather_remote_datasource.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';
import 'package:vms_app/core/utils/app_logger.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WidSource _dataSource;

  WeatherRepositoryImpl(this._dataSource);

  @override
  Future<List<WidModel>> getWidList() async {
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
