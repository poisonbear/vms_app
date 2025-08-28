import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';
import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

// 기존 WidWeatherInfoViewModel 클래스명 유지
class WidWeatherInfoViewModel extends BaseProvider {
  late final WeatherRepository _widRepository;

  List<WidModel>? _widList;
  final List<String> _windDirection = [];
  final List<String> _windSpeed = [];
  final List<String> _windIcon = [];

  // 기존 getters 유지 (null safety 개선)
  List<WidModel>? get widList => _widList;
  List<WidModel>? get WidList => _widList; // 하위 호환성 (대문자 W)
  List<String> get windDirection => _windDirection;
  List<String> get windSpeed => _windSpeed;
  List<String> get windIcon => _windIcon;

  WidWeatherInfoViewModel() {
    _widRepository = getIt<WeatherRepository>();
    getWidList();
  }

  Future<void> getWidList() async {
    final result = await executeAsync(() async {
      return await _widRepository.getWidList();
    }, errorMessage: '기상 정보 로드 중 오류 발생');

    if (result != null) {
      _widList = result;
      _processWindData(result);
      notifyListeners();
    }
  }

  void _processWindData(List<WidModel> weatherList) {
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();

    for (var weather in weatherList) {
      calculateWind(weather.wind_u_surface, weather.wind_v_surface);
    }
  }

  void calculateWind(double? windU, double? windV) {
    if (windU != null && windV != null) {
      // 풍속 계산
      double windSpeedValue = sqrt(windU * windU + windV * windV);

      // 풍향 계산
      double windDirectionValue = atan2(windV, windU) * 180 / pi;
      if (windDirectionValue < 0) windDirectionValue += 360;

      _windSpeed.add(windSpeedValue.toStringAsFixed(1));
      _windDirection.add(windDirectionValue.toStringAsFixed(0));

      // 아이콘 결정
      String iconName;
      if (windSpeedValue < 3) {
        iconName = 'wind_light';
      } else if (windSpeedValue < 7) {
        iconName = 'wind_moderate';
      } else {
        iconName = 'wind_strong';
      }
      _windIcon.add(iconName);
    } else {
      _windSpeed.add('0.0');
      _windDirection.add('0');
      _windIcon.add('wind_light');
    }
  }
}
