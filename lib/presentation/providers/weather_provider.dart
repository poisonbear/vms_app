import 'dart:math';
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/services/cache_service.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';
import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';


// 기존 WidWeatherInfoViewModel 클래스명 유지
class WidWeatherInfoViewModel extends BaseProvider {
  late final WeatherRepository _widRepository;
  final _cache = SimpleCache(); // 캐시 매니저

  List<WidModel>? _widList;
  final List<String> _windDirection = []; // 한글 방위명 저장
  final List<String> _windSpeed = []; // 반올림된 풍속 저장
  final List<String> _windIcon = []; // 아이콘 회전 각도

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
        // ========== 캐싱 로직 시작 ==========
    final now = DateTime.now();
    final cacheKey = 'wid_list_${now.hour}_${now.minute ~/ 30}'; // 30분 단위
    
    // 캐시 확인
    final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('✅ [캐시 사용] 기상정보 리스트');
      AppLogger.d('📦 캐시 데이터 타입: ${cachedData['widList'].runtimeType}');

      // 캐시된 데이터 복원
      if (cachedData['widList'] != null) {
        try {
          _widList = cachedData['widList'] as List<WidModel>?;
          AppLogger.d('📊 _widList 길이: ${_widList?.length}');
          AppLogger.d('📊 첫 번째 데이터: ${_widList?.first}');

          if (_widList != null && _widList!.isNotEmpty) {
            AppLogger.d('🌡️ 첫 데이터 온도: ${_widList!.first.current_temp}');
            AppLogger.d('🌊 첫 데이터 파고: ${_widList!.first.wave_height}');
          }

          _processWindData(_widList!);
          safeNotifyListeners();
        } catch(e) {
          AppLogger.e('❌ 캐시 복원 에러: $e');  // 추가
          AppLogger.e('❌ 타입 캐스팅 실패, API 재호출 필요');
        }
      }
      return;
    }
    
    AppLogger.d('🔄 [API 호출] 기상정보 리스트');

    final result = await executeAsync(() async {
      return await _widRepository.getWidList();
    }, errorMessage: '기상 정보 로드 중 오류 발생');

    if (result != null) {
      _widList = result;
      _processWindData(result);

      AppLogger.d('💾 저장 전 _widList 타입: ${_widList.runtimeType}');
      AppLogger.d('💾 저장 전 _widList 길이: ${_widList?.length}');

      final dataToCache = {
        'widList': result,
      };
      
      _cache.put(cacheKey, dataToCache, const Duration(minutes: 30));
      AppLogger.d('💾 [캐시 저장] 기상정보 리스트 (30분간 유효)');
      // ========== 캐시 저장 끝 ==========
      safeNotifyListeners();
    }
  }

  void _processWindData(List<WidModel> weatherList) {
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();

    AppLogger.d('🌪️ === 풍향/풍속 데이터 처리 (8방위) ===');
    AppLogger.d('총 ${weatherList.length}개 기상 데이터 처리');
    AppLogger.d('');
    AppLogger.d('📌 SVG 아이콘 정보:');
    AppLogger.d('   • 기본 아이콘(ro0): 위쪽(북쪽) 방향');
    AppLogger.d('   • Transform.rotate: 시계방향 회전');
    AppLogger.d('   • 바람 화살표는 바람이 가는 방향을 표시해야 함');
    AppLogger.d('');

    for (int i = 0; i < weatherList.length; i++) {
      final weather = weatherList[i];
      calculateWind(weather.wind_u_surface, weather.wind_v_surface, i);
    }

    AppLogger.d('🌪️ 풍향/풍속 계산 완료');
    printAllWindData();
  }

  void calculateWind(double? windU, double? windV, int index) {
    AppLogger.d('');
    AppLogger.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.d('🔍 [$index] 풍향/풍속 계산:');
    AppLogger.d('   입력: U=$windU, V=$windV');

    if (windU != null && windV != null) {
      // 매우 작은 값은 무풍으로 처리
      if (windU.abs() < 0.1 && windV.abs() < 0.1) {
        _windSpeed.add('0 m/s');
        _windDirection.add('무풍');
        _windIcon.add('ro0');
        AppLogger.d('   → 무풍 처리 (U, V 값이 매우 작음)');
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

      AppLogger.d('   계산 결과:');
      AppLogger.d('     • 풍속: ${windSpeedValue.toStringAsFixed(2)} → $windSpeedRounded m/s');
      AppLogger.d('     • 풍향 각도: ${windDirectionDegrees.toStringAsFixed(1)}° → $windDirectionInt°');
      AppLogger.d('     • 풍향 방위: $windDirectionText (바람이 불어오는 방향)');
      AppLogger.d('     • 화살표 회전: $arrowRotation° (바람이 가는 방향)');
      AppLogger.d('     • 아이콘: $iconName');

      // 검증
      _verifyWindDirection(windU, windV, windDirectionInt, windDirectionText);
    } else {
      // 데이터가 null인 경우
      _windSpeed.add('0 m/s');
      _windDirection.add('무풍');
      _windIcon.add('ro0');
      AppLogger.d('   → 무풍 (데이터 없음)');
    }
  }

  /// 풍향 계산 검증
  void _verifyWindDirection(double u, double v, int direction, String directionText) {
    AppLogger.d('   📐 검증:');

    // 주요 방향 확인
    if (u.abs() < 0.5 && v < -2) {
      AppLogger.d('     예상: 북풍 (V가 음수로 큼) → 실제: $directionText ${directionText == '북풍' ? '✅' : '⚠️'}');
    } else if (u < -2 && v.abs() < 0.5) {
      AppLogger.d('     예상: 동풍 (U가 음수로 큼) → 실제: $directionText ${directionText == '동풍' ? '✅' : '⚠️'}');
    } else if (u.abs() < 0.5 && v > 2) {
      AppLogger.d('     예상: 남풍 (V가 양수로 큼) → 실제: $directionText ${directionText == '남풍' ? '✅' : '⚠️'}');
    } else if (u > 2 && v.abs() < 0.5) {
      AppLogger.d('     예상: 서풍 (U가 양수로 큼) → 실제: $directionText ${directionText == '서풍' ? '✅' : '⚠️'}');
    }
  }

  /// 8방위 한글 변환
  String getWindDirectionText8(int direction) {
    const directions = [
      '북풍', // 0° (337.5° ~ 22.5°)
      '북동풍', // 45° (22.5° ~ 67.5°)
      '동풍', // 90° (67.5° ~ 112.5°)
      '남동풍', // 135° (112.5° ~ 157.5°)
      '남풍', // 180° (157.5° ~ 202.5°)
      '남서풍', // 225° (202.5° ~ 247.5°)
      '서풍', // 270° (247.5° ~ 292.5°)
      '북서풍' // 315° (292.5° ~ 337.5°)
    ];

    int index = ((direction + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// 특정 인덱스의 풍향 정보 가져오기
  Map<String, dynamic> getWindInfoAt(int index) {
    if (index < 0 || index >= _windDirection.length) {
      return {'direction': '무풍', 'speed': '0 m/s', 'icon': 'ro0'};
    }

    return {'direction': _windDirection[index], 'speed': _windSpeed[index], 'icon': _windIcon[index]};
  }

  /// 디버깅용 - 모든 풍향 데이터 출력
  void printAllWindData() {
    AppLogger.d('');
    AppLogger.d('🌪️ === 전체 풍향/풍속 요약 (8방위) ===');
    for (int i = 0; i < _windDirection.length; i++) {
      final windInfo = getWindInfoAt(i);
      final iconAngle = windInfo['icon'].toString().replaceAll('ro', '');
      AppLogger.d('[$i] ${windInfo['direction']} ${windInfo['speed']} → 화살표 $iconAngle°');
    }
    AppLogger.d('🌪️ ================================');
  }

  /// 테스트 케이스 실행
  void runIconRotationTest() {
    AppLogger.d('');
    AppLogger.d('🧪 === 아이콘 회전 테스트 ===');
    AppLogger.d('기본 아이콘(ro0)은 위쪽(0°)을 가리킴');
    AppLogger.d('');

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

      AppLogger.d('$name ($windDir°):');
      AppLogger.d('  화살표 회전: $calculatedIcon° → $rounded° (5도 단위)');
      AppLogger.d('  예상값: $expectedIcon° ${(calculatedIcon - expectedIcon).abs() <= 5 ? '✅' : '⚠️'}');
    }

    AppLogger.d('🧪 ====================');
  }

  @override
  @override
  void dispose() {
    // 캐시 정리
    //_cache.clear();
    // Weather 관련 리소스 정리
    // 실제 변수가 있다면 여기서 정리

    // BaseProvider의 dispose 호출
    super.dispose();
  }
}
