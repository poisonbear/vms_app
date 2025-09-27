import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/data/models/navigation_model.dart';

/// 파고/시정 정보 조회 UseCase
/// NavigationRepository를 사용합니다 (WeatherRepository 아님!)
class GetWeatherInfo {
  final NavigationRepository repository;

  GetWeatherInfo(this.repository);

  Future<WeatherInfo?> execute() async {
    return await repository.getWeatherInfo();
  }
}
