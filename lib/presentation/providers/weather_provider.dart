import 'dart:math';
import 'package:flutter/foundation.dart';
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
      safeNotifyListeners();
    }
  }

  void _processWindData(List<WidModel> weatherList) {
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();

    debugPrint('🌪️ === 풍향 데이터 처리 시작 ===');
    debugPrint('총 ${weatherList.length}개 기상 데이터 처리');

    for (int i = 0; i < weatherList.length; i++) {
      final weather = weatherList[i];
      debugPrint('[$i] wind_u: ${weather.wind_u_surface}, wind_v: ${weather.wind_v_surface}');
      calculateWind(weather.wind_u_surface, weather.wind_v_surface, i);
    }
    
    debugPrint('🌪️ 풍향 계산 완료:');
    for (int i = 0; i < _windDirection.length; i++) {
      debugPrint('  [$i] 방향: ${_windDirection[i]}°, 속도: ${_windSpeed[i]}, 아이콘: ${_windIcon[i]}');
    }
    debugPrint('🌪️ ========================');
  }

  void calculateWind(double? windU, double? windV, int index) {
    debugPrint('🔍 [$index] 풍향 계산: U=$windU, V=$windV');
    
    if (windU != null && windV != null && (windU != 0 || windV != 0)) {
      // 풍속 계산
      double windSpeedValue = sqrt(windU * windU + windV * windV);

      // 풍향 계산 (기상학적 풍향: 바람이 불어오는 방향)
      double windDirectionRad = atan2(-windU, -windV); // 음수 사용으로 풍향 정확히 계산
      double windDirectionDegrees = windDirectionRad * 180 / pi;
      
      // 0~360도 범위로 정규화
      if (windDirectionDegrees < 0) windDirectionDegrees += 360;
      
      // 반올림하여 정수로
      int windDirectionInt = windDirectionDegrees.round() % 360;

      _windSpeed.add('${windSpeedValue.toStringAsFixed(1)} m/s');
      _windDirection.add(windDirectionInt.toString());
      
      // 풍향에 따른 회전 아이콘 생성 (ro + 각도)
      String iconName = 'ro$windDirectionInt';
      _windIcon.add(iconName);
      
      debugPrint('  ✅ 계산 완료: 속도=${windSpeedValue.toStringAsFixed(1)}, 방향=$windDirectionInt°, 아이콘=$iconName');
    } else {
      // 바람이 없는 경우
      _windSpeed.add('0.0 m/s');
      _windDirection.add('0');
      _windIcon.add('ro0'); // 무풍일 때도 ro0 형태
      
      debugPrint('  ⭕ 무풍 상태: 아이콘=ro0');
    }
  }

  /// 풍향을 방위로 변환 (디버깅/표시용)
  String getWindDirectionText(int direction) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    int index = ((direction + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  /// 특정 인덱스의 풍향 정보 가져오기
  Map<String, dynamic> getWindInfoAt(int index) {
    if (index < 0 || index >= _windDirection.length) {
      return {'direction': '0', 'speed': '0.0 m/s', 'icon': 'ro0'};
    }
    
    return {
      'direction': _windDirection[index],
      'speed': _windSpeed[index], 
      'icon': _windIcon[index],
      'directionText': getWindDirectionText(int.parse(_windDirection[index])),
    };
  }

  /// 디버깅용 - 모든 풍향 데이터 출력
  void printAllWindData() {
    debugPrint('🌪️ === 전체 풍향 데이터 ===');
    for (int i = 0; i < _windDirection.length; i++) {
      final windInfo = getWindInfoAt(i);
      debugPrint('[$i] ${windInfo['direction']}° (${windInfo['directionText']}) ${windInfo['speed']} → ${windInfo['icon']}');
    }
    debugPrint('🌪️ =====================');
  }
}
