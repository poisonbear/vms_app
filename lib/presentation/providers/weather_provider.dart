import 'dart:math';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';
import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class WidWeatherInfoViewModel extends BaseProvider {
  late final WeatherRepository _widRepository;

  List<WidModel>? _widList;
  final List<String> _windDirection = []; // final 제거
  final List<String> _windSpeed = []; // final 제거
  final List<String> _windIcon = []; // final 제거

  // Getters
  List<WidModel>? get widList => _widList;
  List<WidModel>? get WidList => _widList; // 하위 호환성
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
      // 실제 필드명 사용: wind_u_surface, wind_v_surface
      calculateWind(weather.wind_u_surface, weather.wind_v_surface);
    }
  }

  void calculateWind(double? windU, double? windV) {
    if (windU == null || windV == null) {
      _windDirection.add('');
      _windSpeed.add('');
      _windIcon.add('');
      return;
    }

    // 풍속 계산 (원본 로직 유지)
    final windSpeed = sqrt(pow(windU, 2) + pow(windV, 2));
    _windSpeed.add('${windSpeed.toStringAsFixed(0)} m/s');

    // 풍향 각도 계산 (원본 로직 유지)
    double theta = atan2(windV, windU);
    double degrees = (270 - (theta * 180 / pi)) % 360;
    if (degrees < 0) degrees += 360;

    // 풍향 결정 및 아이콘 설정 (원본 그대로)
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
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    _widList = null;
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();
    clearError();
    await getWidList();
  }

  @override
  void dispose() {
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();
    super.dispose();
  }
}
