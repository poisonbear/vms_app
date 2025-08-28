import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
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

    if (visibilityValue <= valm4) return '${(valm4 / 1000).toStringAsFixed(1)}km 이하';
    if (visibilityValue <= valm3) {
      return '${(valm3 / 1000).toStringAsFixed(1)}~${(valm4 / 1000).toStringAsFixed(1)}km';
    }
    if (visibilityValue <= valm2) {
      return '${(valm2 / 1000).toStringAsFixed(1)}~${(valm3 / 1000).toStringAsFixed(1)}km';
    }
    if (visibilityValue <= valm1) {
      return '${(valm1 / 1000).toStringAsFixed(1)}~${(valm2 / 1000).toStringAsFixed(1)}km';
    }
    return '${(valm1 / 1000).toStringAsFixed(1)}km 초과';
  }
}
