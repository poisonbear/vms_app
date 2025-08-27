#!/bin/bash

echo "🔧 Provider 중복 코드 정리 - BaseProvider 패턴 적용..."

# 1. BaseProvider 생성
echo "📝 [1/5] BaseProvider 생성..."
mkdir -p lib/presentation/providers/base

cat > lib/presentation/providers/base/base_provider.dart << 'EOF'
import 'package:flutter/material.dart';

/// 모든 Provider의 기본 클래스
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';

  // 공통 Getter
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  /// 로딩 상태 설정
  @protected
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 에러 메시지 설정
  @protected
  void setError(String message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  /// 에러 클리어
  @protected
  void clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }

  /// 비동기 작업 실행 래퍼
  @protected
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        _isLoading = true;
        _errorMessage = '';
        notifyListeners();
      }

      final result = await operation();

      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }

      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = errorMessage ?? e.toString();
      notifyListeners();
      return null;
    }
  }

  /// 동기 작업 실행 래퍼
  @protected
  T? executeSafe<T>(
    T Function() operation, {
    String? errorMessage,
  }) {
    try {
      clearError();
      return operation();
    } catch (e) {
      _errorMessage = errorMessage ?? e.toString();
      notifyListeners();
      return null;
    }
  }
}
EOF

# 2. NavigationProvider 리팩토링
echo "📝 [2/5] NavigationProvider 리팩토링..."
cp lib/presentation/providers/navigation_provider.dart lib/presentation/providers/navigation_provider.backup2

cat > lib/presentation/providers/navigation_provider_refactored.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/app_colors.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/core/utils/logger.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/usecases/navigation/get_navigation_history.dart';
import 'package:vms_app/domain/usecases/navigation/get_weather_info.dart' as weather_usecase;
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class NavigationProvider extends BaseProvider {
  late final GetNavigationHistory _getNavigationHistory;
  late final weather_usecase.GetWeatherInfo _getWeatherInfo;
  late final NavigationRepository _navigationRepository;

  // State variables (isLoading, errorMessage는 BaseProvider에서 상속)
  List<dynamic> _rosList = [];
  bool _isInitialized = false;
  List<String> _navigationWarnings = [];

  // Weather data
  double wave = 0;
  double visibility = 0;
  double walm1 = 0.0;
  double walm2 = 0.0;
  double walm3 = 0.0;
  double walm4 = 0.0;
  double valm1 = 0.0;
  double valm2 = 0.0;
  double valm3 = 0.0;
  double valm4 = 0.0;

  // Getters
  List<dynamic> get rosList => _rosList;
  List<dynamic> get RosList => _rosList; // 하위 호환성
  bool get isInitialized => _isInitialized;
  List<String> get navigationWarnings => _navigationWarnings;

  String get combinedNavigationWarnings {
    if (_navigationWarnings.isEmpty) {
      return '금일 항행경보가 없습니다.';
    }
    return _navigationWarnings.join('             ');
  }

  NavigationProvider() {
    _navigationRepository = getIt<NavigationRepository>();
    _getNavigationHistory = getIt<GetNavigationHistory>();
    _getWeatherInfo = getIt<weather_usecase.GetWeatherInfo>();

    // 초기 데이터 로드
    getWeatherInfo();
    getNavigationWarnings();
  }

  Future<void> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    _isInitialized = true;
    
    final result = await executeAsync(() async {
      return await _getNavigationHistory.execute(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
        shipName: shipName,
      );
    }, errorMessage: '데이터 로드 중 오류 발생');
    
    if (result != null) {
      _rosList = result;
      notifyListeners();
    }
  }

  Future<void> getWeatherInfo() async {
    final weatherInfo = await executeAsync(
      () => _getWeatherInfo.execute(),
      errorMessage: '기상 정보 로드 중 오류',
      showLoading: false, // 백그라운드 로드
    );

    if (weatherInfo != null) {
      wave = weatherInfo.wave ?? 0.5;
      visibility = weatherInfo.visibility ?? 1000;
      walm1 = weatherInfo.walm1 ?? 0.0;
      walm2 = weatherInfo.walm2 ?? 0.0;
      walm3 = weatherInfo.walm3 ?? 0.0;
      walm4 = weatherInfo.walm4 ?? 0.0;
      valm1 = weatherInfo.valm1 ?? 0.0;
      valm2 = weatherInfo.valm2 ?? 0.0;
      valm3 = weatherInfo.valm3 ?? 0.0;
      valm4 = weatherInfo.valm4 ?? 0.0;
      notifyListeners();
    }
  }

  Future<void> getNavigationWarnings() async {
    final warnings = await executeAsync(
      () => _navigationRepository.getNavigationWarnings(),
      errorMessage: '항행경보 로드 중 오류',
      showLoading: false,
    );

    if (warnings != null) {
      _navigationWarnings = warnings;
      notifyListeners();
    }
  }

  // 색상 및 포맷 메서드들은 그대로 유지
  Color getWaveColor(double waveHeight) {
    if (waveHeight >= walm4) return const Color(0xFFDF2B2E);
    if (waveHeight >= walm3) return const Color(0xFFF26C1D);
    if (waveHeight >= walm2) return const Color(0xFFFFCC00);
    if (waveHeight >= walm1) return const Color(0xFF0080FF);
    return const Color(0xFF999999);
  }

  Color getVisibilityColor(double visibilityValue) {
    if (visibilityValue <= valm4) return const Color(0xFFDF2B2E);
    if (visibilityValue <= valm3) return const Color(0xFFF26C1D);
    if (visibilityValue <= valm2) return const Color(0xFFFFCC00);
    if (visibilityValue <= valm1) return const Color(0xFF0080FF);
    return const Color(0xFF999999);
  }

  String getFormattedWaveThresholdText(double waveHeight) {
    if (walm1 == 0.0 || walm2 == 0.0 || walm3 == 0.0 || walm4 == 0.0) {
      return '${waveHeight.toStringAsFixed(1)} m';
    }

    if (waveHeight >= walm4) return '${walm4.toStringAsFixed(1)}m 이상';
    if (waveHeight >= walm3) return '${walm3.toStringAsFixed(1)}~${walm4.toStringAsFixed(1)}m';
    if (waveHeight >= walm2) return '${walm2.toStringAsFixed(1)}~${walm3.toStringAsFixed(1)}m';
    if (waveHeight >= walm1) return '${walm1.toStringAsFixed(1)}~${walm2.toStringAsFixed(1)}m';
    return '${walm1.toStringAsFixed(1)}m 미만';
  }

  String getFormattedVisibilityThresholdText(double visibilityValue) {
    if (valm1 == 0.0 || valm2 == 0.0 || valm3 == 0.0 || valm4 == 0.0) {
      double visibilityInKm = visibilityValue / 1000;
      return visibilityInKm >= 1
          ? '${visibilityInKm.toStringAsFixed(1)} km'
          : '${visibilityValue.toStringAsFixed(0)} m';
    }

    if (visibilityValue <= valm4) return '${(valm4/1000).toStringAsFixed(1)}km 이하';
    if (visibilityValue <= valm3) return '${(valm3/1000).toStringAsFixed(1)}~${(valm4/1000).toStringAsFixed(1)}km';
    if (visibilityValue <= valm2) return '${(valm2/1000).toStringAsFixed(1)}~${(valm3/1000).toStringAsFixed(1)}km';
    if (visibilityValue <= valm1) return '${(valm1/1000).toStringAsFixed(1)}~${(valm2/1000).toStringAsFixed(1)}km';
    return '${(valm1/1000).toStringAsFixed(1)}km 초과';
  }
}
EOF

# 3. RouteSearchProvider 리팩토링
echo "📝 [3/5] RouteSearchProvider 리팩토링..."
cp lib/presentation/providers/route_search_provider.dart lib/presentation/providers/route_search_provider.backup2

cat > lib/presentation/providers/route_search_provider_refactored.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/navigation/route_search_model.dart';
import 'package:vms_app/domain/repositories/route_search_repository.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class RouteSearchProvider extends BaseProvider {
  late final RouteSearchRepository _routeSearchRepository;

  List<PastRouteSearchModel> _pastRouteList = [];
  List<PredRouteSearchModel> _predRouteList = [];
  bool _isNavigationHistoryMode = false;

  // Getters
  List<PastRouteSearchModel> get pastRouteList => _pastRouteList;
  List<PredRouteSearchModel> get predRouteList => _predRouteList;
  List<PastRouteSearchModel> get pastRoutes => _pastRouteList;
  List<PredRouteSearchModel> get predRoutes => _predRouteList;
  bool get isNavigationHistoryMode => _isNavigationHistoryMode;

  RouteSearchProvider() {
    _routeSearchRepository = getIt<RouteSearchRepository>();
  }

  Future<void> getVesselRoute({String? regDt, int? mmsi}) async {
    final response = await executeAsync(() async {
      return await _routeSearchRepository.getVesselRoute(
        regDt: regDt,
        mmsi: mmsi,
      );
    }, errorMessage: '항로 조회 중 오류 발생');

    if (response != null) {
      _pastRouteList = response.past;
      _predRouteList = response.pred;
      notifyListeners();
    }
  }

  void clearRoutes() {
    _pastRouteList = [];
    _predRouteList = [];
    clearError();
    notifyListeners();
  }

  void setNavigationHistoryMode(bool value) {
    _isNavigationHistoryMode = value;
    notifyListeners();
  }

  void setPastRoutes(List<PastRouteSearchModel> routes) {
    _pastRouteList = routes;
    notifyListeners();
  }

  void setPredRoutes(List<PredRouteSearchModel> routes) {
    _predRouteList = routes;
    notifyListeners();
  }

  void reset() {
    _pastRouteList = [];
    _predRouteList = [];
    _isNavigationHistoryMode = false;
    clearError();
    setLoading(false);
    notifyListeners();
  }
}
EOF

# 4. WeatherProvider 리팩토링
echo "📝 [4/5] WeatherProvider 리팩토링..."
cp lib/presentation/providers/weather_provider.dart lib/presentation/providers/weather_provider.backup2

cat > lib/presentation/providers/weather_provider_refactored.dart << 'EOF'
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
      return await _widRepository.getWeatherList();
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
      calculateWind(weather.u_wind, weather.v_wind);
    }
  }

  void calculateWind(double? windU, double? windV) {
    if (windU == null || windV == null) {
      _windDirection.add('정온');
      _windSpeed.add('0.0');
      _windIcon.add('');
      return;
    }

    double windSpeed = sqrt(windU * windU + windV * windV);
    double windDirectionDeg = atan2(-windU, -windV) * (180 / pi);

    if (windDirectionDeg < 0) {
      windDirectionDeg += 360;
    }

    String windDirStr = _getWindDirectionString(windDirectionDeg);
    String windIcon = _getWindIcon(windDirectionDeg);

    _windDirection.add(windDirStr);
    _windSpeed.add(windSpeed.toStringAsFixed(1));
    _windIcon.add(windIcon);
  }

  String _getWindDirectionString(double degrees) {
    const List<String> directions = [
      '북', '북북동', '북동', '동북동',
      '동', '동남동', '남동', '남남동',
      '남', '남남서', '남서', '서남서',
      '서', '서북서', '북서', '북북서'
    ];
    int index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  String _getWindIcon(double degrees) {
    if (degrees >= 337.5 || degrees < 22.5) return 'N';
    if (degrees >= 22.5 && degrees < 67.5) return 'NE';
    if (degrees >= 67.5 && degrees < 112.5) return 'E';
    if (degrees >= 112.5 && degrees < 157.5) return 'SE';
    if (degrees >= 157.5 && degrees < 202.5) return 'S';
    if (degrees >= 202.5 && degrees < 247.5) return 'SW';
    if (degrees >= 247.5 && degrees < 292.5) return 'W';
    if (degrees >= 292.5 && degrees < 337.5) return 'NW';
    return '';
  }
}
EOF

# 5. 파일 교체
echo "📝 [5/5] 파일 교체..."
echo "NavigationProvider 교체..."
if [ -f lib/presentation/providers/navigation_provider_refactored.dart ]; then
  mv lib/presentation/providers/navigation_provider.dart lib/presentation/providers/navigation_provider.original
  mv lib/presentation/providers/navigation_provider_refactored.dart lib/presentation/providers/navigation_provider.dart
fi

echo "RouteSearchProvider 교체..."
if [ -f lib/presentation/providers/route_search_provider_refactored.dart ]; then
  mv lib/presentation/providers/route_search_provider.dart lib/presentation/providers/route_search_provider.original
  mv lib/presentation/providers/route_search_provider_refactored.dart lib/presentation/providers/route_search_provider.dart
fi

echo "WeatherProvider 교체..."
if [ -f lib/presentation/providers/weather_provider_refactored.dart ]; then
  mv lib/presentation/providers/weather_provider.dart lib/presentation/providers/weather_provider.original
  mv lib/presentation/providers/weather_provider_refactored.dart lib/presentation/providers/weather_provider.dart
fi

echo "✅ Provider 중복 코드 정리 완료!"
echo ""
echo "📊 개선 내역:"
echo "  • BaseProvider 생성 - 공통 로직 추출"
echo "  • NavigationProvider - executeAsync 패턴 적용"
echo "  • RouteSearchProvider - executeAsync 패턴 적용"
echo "  • WeatherProvider - executeAsync 패턴 적용"
echo ""
echo "🔍 검증 중..."
flutter analyze | grep -e 'error' || echo "✨ 에러 없음!"

echo ""
echo "💡 복원 방법:"
echo "  mv lib/presentation/providers/navigation_provider.original lib/presentation/providers/navigation_provider.dart"
echo "  mv lib/presentation/providers/route_search_provider.original lib/presentation/providers/route_search_provider.dart"
echo "  mv lib/presentation/providers/weather_provider.original lib/presentation/providers/weather_provider.dart"
