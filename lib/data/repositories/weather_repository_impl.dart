import 'package:vms_app/data/datasources/remote/weather_remote_datasource.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';

class WeatherRepository {
  final WidSource _dataSource;

  // ✅ 생성자를 통한 의존성 주입
  WeatherRepository(this._dataSource);

  Future<List<WidModel>> getWidList() {
    return _dataSource.getWidList();
  }
}