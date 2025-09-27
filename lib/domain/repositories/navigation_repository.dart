import 'package:vms_app/data/models/navigation_model.dart';

abstract class NavigationRepository {
  Future<List<RosModel>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  });

  Future<WeatherInfo?> getWeatherInfo();
  Future<List<String>?> getNavigationWarnings();
}
