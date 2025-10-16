import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/data/models/weather_model.dart';

/// 날씨 관련 UseCase 모음
class WeatherUseCases {
  final WeatherRepository _repository;

  WeatherUseCases(this._repository);

  /// 날씨 정보 목록 조회
  Future<List<WeatherModel>> getWeatherList() async {
    return await _repository.getWidList();
  }

  /// 현재 날씨 정보 조회 (첫 번째 항목)
  Future<WeatherModel?> getCurrentWeather() async {
    final weatherList = await _repository.getWidList();
    return weatherList.isNotEmpty ? weatherList.first : null;
  }

  /// 지역별 날씨 정보 필터링
  Future<List<WeatherModel>> getWeatherByRegion(String region) async {
    final weatherList = await _repository.getWidList();
    return weatherList
        .where((weather) => weather.toString().contains(region))
        .toList();
  }
}

// ===== 개별 UseCase 클래스들 =====

/// 날씨 정보 목록 조회 UseCase
class GetWeatherList {
  final WeatherRepository repository;

  GetWeatherList(this.repository);

  Future<List<WeatherModel>> execute() async {
    return await repository.getWidList();
  }
}

/// 현재 날씨 정보 조회 UseCase
class GetCurrentWeather {
  final WeatherRepository repository;

  GetCurrentWeather(this.repository);

  Future<WeatherModel?> execute() async {
    final weatherList = await repository.getWidList();
    return weatherList.isNotEmpty ? weatherList.first : null;
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef GetWidList = GetWeatherList;
// GetWeatherInfo는 navigation에만 남겨둠 (NavigationRepository의 WeatherInfo 사용)
