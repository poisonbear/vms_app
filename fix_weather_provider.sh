#!/bin/bash

echo "🔧 WeatherProvider 에러 수정..."

# 1. WeatherRepository 생성 (없는 경우)
echo "📝 [1/3] WeatherRepository 인터페이스 생성..."
cat > lib/domain/repositories/weather_repository.dart << 'EOF'
import 'package:vms_app/data/models/weather/weather_model.dart';

abstract class WeatherRepository {
  Future<List<WidModel>> getWidList();
}
EOF

# 2. WeatherRepositoryImpl 생성 
echo "📝 [2/3] WeatherRepositoryImpl 생성..."
cat > lib/data/repositories/weather_repository_impl.dart << 'EOF'
import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/data/datasources/remote/weather_remote_datasource.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WidSource _dataSource;

  WeatherRepositoryImpl(this._dataSource);

  @override
  Future<List<WidModel>> getWidList() {
    return _dataSource.getWidList();
  }
}
EOF

# 3. WeatherProvider 수정 (필드명 수정)
echo "📝 [3/3] WeatherProvider 수정..."
cat > lib/presentation/providers/weather_provider.dart << 'EOF'
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/core/utils/logger.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';
import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class WidWeatherInfoViewModel extends BaseProvider {
  late final WeatherRepository _widRepository;

  List<WidModel>? _widList;
  List<String> _windDirection = [];
  List<String> _windSpeed = [];
  List<String> _windIcon = [];

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
  }
}
EOF

# 4. injection.dart 업데이트 (WeatherRepository 추가)
echo "📝 WeatherRepository를 DI 컨테이너에 추가..."
cat >> lib/core/di/injection_weather_patch.dart << 'EOF'

// WeatherRepository 추가 (injection.dart의 _injectRepositories 함수에 추가)
// Weather Repository
getIt.registerLazySingleton<WeatherRepository>(
  () => WeatherRepositoryImpl(getIt<WidSource>()),
);

// DataSource 추가 (injection.dart의 _injectDataSources 함수에 추가)
// Weather DataSource
getIt.registerLazySingleton<WidSource>(
  () => WidSource(),
);
EOF

echo "✅ WeatherProvider 에러 수정 완료!"
echo ""
echo "📊 수정 내역:"
echo "  • WeatherRepository 인터페이스 생성"
echo "  • WeatherRepositoryImpl 구현체 생성"
echo "  • WeatherProvider 필드명 수정 (wind_u_surface, wind_v_surface)"
echo "  • BaseProvider 상속 적용"
echo ""
echo "⚠️ 주의: injection.dart에 다음을 추가해야 합니다:"
echo "  1. _injectDataSources()에 WidSource 등록"
echo "  2. _injectRepositories()에 WeatherRepository 등록"
echo ""
echo "🔍 검증 중..."
flutter analyze lib/presentation/providers/weather_provider.dart | grep -e 'error' || echo "✨ WeatherProvider 에러 해결!"
