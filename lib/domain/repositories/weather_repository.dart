import 'package:vms_app/data/models/weather/weather_model.dart';

abstract class WeatherRepository {
  Future<List<WidModel>> getWidList();
}
