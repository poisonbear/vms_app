// lib/presentation/providers/weather_provider.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/core/utils/logger.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';
import 'package:vms_app/data/repositories/weather_repository_impl.dart';

class WidWeatherInfoViewModel with ChangeNotifier {
  late final WeatherRepository _widRepository;

  List<WidModel>? _widList;
  List<String> _windDirection = [];
  List<String> _windSpeed = [];
  List<String> _windIcon = [];
  bool _isLoading = true;

  // Getter들
  List<WidModel>? get widList => _widList;
  List<WidModel>? get WidList => _widList; // 대문자 버전 (호환성)
  List<String> get windDirection => _windDirection;
  List<String> get windSpeed => _windSpeed;
  List<String> get windIcon => _windIcon;
  bool get isLoading => _isLoading;
  String get errorMessage => '';

  WidWeatherInfoViewModel() {
    // ✅ DI 컨테이너에서 주입
    _widRepository = getIt<WeatherRepository>();
    getWidList();
  }

  void calculateWind(double? windU, double? windV) {
    if (windU == null || windV == null) {
      _windDirection.add('');
      _windSpeed.add('');
      _windIcon.add('');
      return;
    }

    // 풍속 계산
    final windSpeed = sqrt(pow(windU, 2) + pow(windV, 2));
    _windSpeed.add('${windSpeed.toStringAsFixed(0)} m/s');

    // 풍향 각도 계산
    double theta = atan2(windV, windU);
    double degrees = (270 - (theta * 180 / pi)) % 360;
    if (degrees < 0) degrees += 360;

    // 풍향 결정
    if (degrees >= 337.5 || degrees < 22.5) {
      _windDirection.add('북풍');
      _windIcon.add('ro180');
    } else if (degrees >= 22.5 && degrees < 67.5) {
      _windDirection.add('북동풍');
      _windIcon.add('ro225');
    } else if (degrees >= 67.5 && degrees < 112.5) {
      _windDirection.add('동풍');
      _windIcon.add('ro270');
    } else if (degrees >= 112.5 && degrees < 157.5) {
      _windDirection.add('남동풍');
      _windIcon.add('ro315');
    } else if (degrees >= 157.5 && degrees < 202.5) {
      _windDirection.add('남풍');
      _windIcon.add('ro0');
    } else if (degrees >= 202.5 && degrees < 247.5) {
      _windDirection.add('남서풍');
      _windIcon.add('ro45');
    } else if (degrees >= 247.5 && degrees < 292.5) {
      _windDirection.add('서풍');
      _windIcon.add('ro90');
    } else {
      _windDirection.add('북서풍');
      _windIcon.add('ro135');
    }
    notifyListeners();
  }

  Future<void> getWidList() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<WidModel> fetchedList = await _widRepository.getWidList();
      _widList = fetchedList;

      if (fetchedList.isNotEmpty) {
        // 리스트 초기화
        _windDirection.clear();
        _windSpeed.clear();
        _windIcon.clear();

        for (int i = 0; i < fetchedList.length; i++) {
          calculateWind(
            fetchedList[i].wind_u_surface?.toDouble(),
            fetchedList[i].wind_v_surface?.toDouble(),
          );
        }
      }
    } catch (e) {
      logger.e('Error in getWidList: $e');
      _widList = [];
      _windDirection = [];
      _windSpeed = [];
      _windIcon = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}