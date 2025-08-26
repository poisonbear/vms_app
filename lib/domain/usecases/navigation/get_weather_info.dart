import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';

class GetWeatherInfo {
  final NavigationRepository repository;

  GetWeatherInfo(this.repository);

  Future<WeatherInfo?> execute() async {
    return await repository.getWeatherInfo();
  }
}
