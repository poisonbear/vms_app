import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/data/datasources/remote/weather_remote_datasource.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WidSource _dataSource;

  WeatherRepositoryImpl(this._dataSource);

  @override
  Future<List<WidModel>> getWidList() {
    return _dataSource.getWidList();
  }
}
