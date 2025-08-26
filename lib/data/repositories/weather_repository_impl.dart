import 'package:vms_app/data/datasources/remote/weather_remote_datasource.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';

// 기상정보 데이터 Load
final WidSource _dataSource = WidSource();

class WidRepository {
  Future<List<WidModel>> getWidList() {
    return _dataSource.getWidList();
  }
}
