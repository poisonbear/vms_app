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
  final List<String> _windDirection = [];  // 한글 방위명 저장
  final List<String> _windSpeed = [];      // 반올림된 풍속 저장
  final List<String> _windIcon = [];       // 아이콘 회전 각도

  // 기존 getters 유지
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
      safeNotifyListeners();
    }
  }

  void _processWindData(List<WidModel> weatherList) {
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();

    debugPrint('🌪️ === 풍향/풍속 데이터 처리 (8방위) ===');
    debugPrint('총 ${weatherList.length}개 기상 데이터 처리');
    debugPrint('');
    debugPrint('📌 SVG 아이콘 정보:');
    debugPrint('   • 기본 아이콘(ro0): 위쪽(북쪽) 방향');
    debugPrint('   • Transform.rotate: 시계방향 회전');
    debugPrint('   • 바람 화살표는 바람이 가는 방향을 표시해야 함');
    debugPrint('');

    for (int i = 0; i < weatherList.length; i++) {
      final weather = weatherList[i];
      calculateWind(weather.wind_u_surface, weather.wind_v_surface, i);
    }
    
    debugPrint('🌪️ 풍향/풍속 계산 완료');
    printAllWindData();
  }

  void calculateWind(double? windU, double? windV, int index) {
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔍 [$index] 풍향/풍속 계산:');
    debugPrint('   입력: U=$windU, V=$windV');
    
    if (windU != null && windV != null) {
      // 매우 작은 값은 무풍으로 처리
      if (windU.abs() < 0.1 && windV.abs() < 0.1) {
        _windSpeed.add('0 m/s');
        _windDirection.add('무풍');
        _windIcon.add('ro0');
        debugPrint('   → 무풍 처리 (U, V 값이 매우 작음)');
        return;
      }
      
      // 풍속 계산 및 반올림
      double windSpeedValue = sqrt(windU * windU + windV * windV);
      int windSpeedRounded = windSpeedValue.round();

      // 기상학적 풍향 계산 (바람이 불어오는 방향)
      // atan2(-windU, -windV)를 사용
      double windDirectionRad = atan2(-windU, -windV);
      double windDirectionDegrees = windDirectionRad * 180 / pi;
      
      // 0~360도 범위로 정규화
      if (windDirectionDegrees < 0) {
        windDirectionDegrees += 360;
      }
      
      // 정수로 반올림
      int windDirectionInt = windDirectionDegrees.round() % 360;
      
      // 화살표가 가리킬 방향 계산
      // 바람이 가는 방향 = 풍향 + 180°
      int arrowRotation = (windDirectionInt + 180) % 360;
      
      // 5도 단위로 반올림 (더 부드러운 회전을 위해)
      arrowRotation = ((arrowRotation / 5).round() * 5) % 360;

      // 풍속 저장
      _windSpeed.add('$windSpeedRounded m/s');
      
      // 8방위 한글 방위명
      String windDirectionText = getWindDirectionText8(windDirectionInt);
      _windDirection.add(windDirectionText);
      
      // 아이콘 회전 각도
      String iconName = 'ro$arrowRotation';
      _windIcon.add(iconName);
      
      debugPrint('   계산 결과:');
      debugPrint('     • 풍속: ${windSpeedValue.toStringAsFixed(2)} → $windSpeedRounded m/s');
      debugPrint('     • 풍향 각도: ${windDirectionDegrees.toStringAsFixed(1)}° → $windDirectionInt°');
      debugPrint('     • 풍향 방위: $windDirectionText (바람이 불어오는 방향)');
      debugPrint('     • 화살표 회전: $arrowRotation° (바람이 가는 방향)');
      debugPrint('     • 아이콘: $iconName');
      
      // 검증
      _verifyWindDirection(windU, windV, windDirectionInt, windDirectionText);
      
    } else {
      // 데이터가 null인 경우
      _windSpeed.add('0 m/s');
      _windDirection.add('무풍');
      _windIcon.add('ro0');
      debugPrint('   → 무풍 (데이터 없음)');
    }
  }

  /// 풍향 계산 검증
  void _verifyWindDirection(double u, double v, int direction, String directionText) {
    debugPrint('   📐 검증:');
    
    // 주요 방향 확인
    if (u.abs() < 0.5 && v < -2) {
      debugPrint('     예상: 북풍 (V가 음수로 큼) → 실제: $directionText ${directionText == '북풍' ? '✅' : '⚠️'}');
    } else if (u < -2 && v.abs() < 0.5) {
      debugPrint('     예상: 동풍 (U가 음수로 큼) → 실제: $directionText ${directionText == '동풍' ? '✅' : '⚠️'}');
    } else if (u.abs() < 0.5 && v > 2) {
      debugPrint('     예상: 남풍 (V가 양수로 큼) → 실제: $directionText ${directionText == '남풍' ? '✅' : '⚠️'}');
    } else if (u > 2 && v.abs() < 0.5) {
      debugPrint('     예상: 서풍 (U가 양수로 큼) → 실제: $directionText ${directionText == '서풍' ? '✅' : '⚠️'}');
    }
  }

  /// 8방위 한글 변환
  String getWindDirectionText8(int direction) {
    const directions = [
      '북풍',    // 0° (337.5° ~ 22.5°)
      '북동풍',  // 45° (22.5° ~ 67.5°)
      '동풍',    // 90° (67.5° ~ 112.5°)
      '남동풍',  // 135° (112.5° ~ 157.5°)
      '남풍',    // 180° (157.5° ~ 202.5°)
      '남서풍',  // 225° (202.5° ~ 247.5°)
      '서풍',    // 270° (247.5° ~ 292.5°)
      '북서풍'   // 315° (292.5° ~ 337.5°)
    ];
    
    int index = ((direction + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// 특정 인덱스의 풍향 정보 가져오기
  Map<String, dynamic> getWindInfoAt(int index) {
    if (index < 0 || index >= _windDirection.length) {
      return {
        'direction': '무풍',
        'speed': '0 m/s',
        'icon': 'ro0'
      };
    }
    
    return {
      'direction': _windDirection[index],
      'speed': _windSpeed[index],
      'icon': _windIcon[index]
    };
  }

  /// 디버깅용 - 모든 풍향 데이터 출력
  void printAllWindData() {
    debugPrint('');
    debugPrint('🌪️ === 전체 풍향/풍속 요약 (8방위) ===');
    for (int i = 0; i < _windDirection.length; i++) {
      final windInfo = getWindInfoAt(i);
      final iconAngle = windInfo['icon'].toString().replaceAll('ro', '');
      debugPrint('[$i] ${windInfo['direction']} ${windInfo['speed']} → 화살표 $iconAngle°');
    }
    debugPrint('🌪️ ================================');
  }

  /// 테스트 케이스 실행
  void runIconRotationTest() {
    debugPrint('');
    debugPrint('🧪 === 아이콘 회전 테스트 ===');
    debugPrint('기본 아이콘(ro0)은 위쪽(0°)을 가리킴');
    debugPrint('');
    
    final testCases = [
      {'name': '북풍', 'windDir': 0, 'expectedIcon': 180},
      {'name': '북동풍', 'windDir': 45, 'expectedIcon': 225},
      {'name': '동풍', 'windDir': 90, 'expectedIcon': 270},
      {'name': '남동풍', 'windDir': 135, 'expectedIcon': 315},
      {'name': '남풍', 'windDir': 180, 'expectedIcon': 0},
      {'name': '남서풍', 'windDir': 225, 'expectedIcon': 45},
      {'name': '서풍', 'windDir': 270, 'expectedIcon': 90},
      {'name': '북서풍', 'windDir': 315, 'expectedIcon': 135},
    ];
    
    for (final test in testCases) {
      final windDir = test['windDir'] as int;
      final expectedIcon = test['expectedIcon'] as int;
      final name = test['name'] as String;
      
      final calculatedIcon = (windDir + 180) % 360;
      final rounded = ((calculatedIcon / 5).round() * 5) % 360;
      
      debugPrint('$name ($windDir°):');
      debugPrint('  화살표 회전: $calculatedIcon° → $rounded° (5도 단위)');
      debugPrint('  예상값: $expectedIcon° ${(calculatedIcon - expectedIcon).abs() <= 5 ? '✅' : '⚠️'}');
    }
    
    debugPrint('🧪 ====================');
  }
}
