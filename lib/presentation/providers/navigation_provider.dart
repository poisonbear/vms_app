import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/usecases/navigation/get_navigation_history.dart';
import 'package:vms_app/domain/usecases/navigation/get_weather_info.dart'
    as weather_usecase;
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class NavigationProvider extends BaseProvider {
  late final GetNavigationHistory _getNavigationHistory;
  late final weather_usecase.GetWeatherInfo _getWeatherInfo;
  late final NavigationRepository _navigationRepository;

  // 기존 구조 유지 - State variables
  List<dynamic> _rosList = [];
  bool _isInitialized = false;
  List<String> _navigationWarnings = [];

  // Weather data - 기존 변수명 그대로 유지 (public)
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

  // 기존 getters 유지
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

  // 기존 메서드 유지
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
      showLoading: false,
    );

    if (weatherInfo != null) {
      wave = weatherInfo.wave;
      visibility = weatherInfo.visibility;
      walm1 = weatherInfo.walm1;
      walm2 = weatherInfo.walm2;
      walm3 = weatherInfo.walm3;
      walm4 = weatherInfo.walm4;
      valm1 = weatherInfo.valm1;
      valm2 = weatherInfo.valm2;
      valm3 = weatherInfo.valm3;
      valm4 = weatherInfo.valm4;
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

  // 기존 코드에서 사용하는 Color 반환 메서드들
  Color getWaveColor(double waveValue) {
    if (waveValue <= walm1) return Colors.green;
    if (waveValue <= walm2) return Colors.yellow;
    if (waveValue <= walm3) return Colors.orange;
    return Colors.red;
  }

  String getFormattedWaveThresholdText(double waveValue) {
    return '파고: ${waveValue.toStringAsFixed(1)}m';
  }

  Color getVisibilityColor(double visibilityValue) {
    if (visibilityValue >= valm1) return Colors.green;
    if (visibilityValue >= valm2) return Colors.yellow;
    if (visibilityValue >= valm3) return Colors.orange;
    return Colors.red;
  }

  String getFormattedVisibilityThresholdText(double visibilityValue) {
    return '시정: ${visibilityValue.toStringAsFixed(0)}m';
  }
}
