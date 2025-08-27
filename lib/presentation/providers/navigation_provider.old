import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/app_colors.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/usecases/navigation/get_navigation_history.dart';
import 'package:vms_app/domain/usecases/navigation/get_weather_info.dart' as weather_usecase;

class NavigationProvider with ChangeNotifier {
  late final GetNavigationHistory _getNavigationHistory;
  late final weather_usecase.GetWeatherInfo _getWeatherInfo;
  late final NavigationRepository _navigationRepository;

  List<dynamic> _RosList = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String _errorMessage = '';

  //날씨 정보(파고, 시정) 가져오기
  double wave = 0;
  double visibility = 0;
  // 파고 알람 기준값
  double walm1 = 0.0;
  double walm2 = 0.0;
  double walm3 = 0.0;
  double walm4 = 0.0;
  // 시정 알람 기준값
  double valm1 = 0.0;
  double valm2 = 0.0;
  double valm3 = 0.0;
  double valm4 = 0.0;

  List<String> _navigationWarnings = [];

  List<dynamic> get RosList => _RosList;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String get errorMessage => _errorMessage;
  List<String> get navigationWarnings => _navigationWarnings;

  // Marquee에 표시할 결합된 항행 경보 메시지
  String get combinedNavigationWarnings {
    if (_navigationWarnings.isEmpty) {
      return '금일 항행경보가 없습니다.';
    }
    //메시지 결합
    String result = _navigationWarnings.join('             ');
    return result;
  }

  NavigationProvider() {
    _navigationRepository = getIt<NavigationRepository>();
    _getNavigationHistory = getIt<GetNavigationHistory>();
    _getWeatherInfo = getIt<weather_usecase.GetWeatherInfo>();
  }

  Future<void> getRosList(
      {String? startDate, String? endDate, int? mmsi, String? shipName}) async {
    try {
      _isLoading = true;
      _isInitialized = true;
      notifyListeners();

      List<RosModel> fetchedList = await _getNavigationHistory.execute(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
        shipName: shipName,
      );

      _RosList = fetchedList;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = '데이터 로드 중 오류 발생: $e';
      _RosList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getWeatherInfo() async {
    try {
      WeatherInfo? weatherInfo = await _getWeatherInfo.execute();

      if (weatherInfo != null) {
        wave = weatherInfo.wave ?? 0;
        visibility = weatherInfo.visibility ?? 0;

        // 알람 기준값도 저장
        walm1 = weatherInfo.walm1 ?? 0;
        walm2 = weatherInfo.walm2 ?? 0;
        walm3 = weatherInfo.walm3 ?? 0;
        walm4 = weatherInfo.walm4 ?? 0;

        valm1 = weatherInfo.valm1 ?? 0;
        valm2 = weatherInfo.valm2 ?? 0;
        valm3 = weatherInfo.valm3 ?? 0;
        valm4 = weatherInfo.valm4 ?? 0;

        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '날씨 정보 로드 중 오류 발생: $e';
    }
  }

  // 항행 경보 알림 데이터 정보
  Future<void> getNavigationWarnings() async {
    try {
      _navigationWarnings = await _navigationRepository.getNavigationWarnings() ?? [];
      _errorMessage = '';
    } catch (e) {
      _navigationWarnings = [];
      _errorMessage = '항행경보 데이터를 불러오는 중 오류가 발생했습니다';
    }
    notifyListeners();
  }

  // 파고 색상과 함께 적용된 기준값 반환
  Map<String, dynamic> getWaveColorAndThreshold(double wave) {
    Color color;
    double threshold;
    String warningText = '';

    if (wave == 0) {
      color = getColorwhite_type1();
      threshold = wave;
    } else if (walm4 > 0 && wave >= walm4) {
      color = getColorred_type2();
      threshold = wave;
      warningText = '(심각)';
    } else if (walm3 > 0 && wave >= walm3) {
      color = getColoryellow_Type2();
      threshold = wave;
      warningText = '(주의)';
    } else {
      color = getColorwhite_type1();
      threshold = wave;
      warningText = '(정상)';
    }

    return {'color': color, 'threshold': threshold, 'warningText': warningText};
  }

  // 시정 색상과 함께 적용된 기준값 반환
  Map<String, dynamic> getVisibilityColorAndThreshold(double visibility) {
    Color color;
    double threshold;
    String warningText = '';

    if (visibility == 0) {
      color = getColorwhite_type1();
      threshold = visibility;
    } else if (valm4 > 0 && visibility <= valm4) {
      color = getColorred_type2();
      threshold = visibility;
      warningText = '(심각)';
    } else if (valm3 > 0 && visibility <= valm3) {
      color = getColoryellow_Type2();
      threshold = visibility;
      warningText = '(주의)';
    } else {
      color = getColorwhite_type1();
      threshold = visibility;
      warningText = '(정상)';
    }

    return {'color': color, 'threshold': threshold, 'warningText': warningText};
  }

  // 파고 색깔만 간편하게 가져오기
  Color getWaveColor(double wave) {
    return getWaveColorAndThreshold(wave)['color'];
  }

  // 파고 임계값만 가져오기
  double getWaveThreshold(double wave) {
    return getWaveColorAndThreshold(wave)['threshold'];
  }

  // 시정 색깔만 간편하게 가져오기
  Color getVisibilityColor(double visibility) {
    return getVisibilityColorAndThreshold(visibility)['color'];
  }

  // 시정 임계값만 가져오기
  double getVisibilityThreshold(double visibility) {
    return getVisibilityColorAndThreshold(visibility)['threshold'];
  }

  // 파고 경고 텍스트 가져오기
  String getWaveWarningText(double wave) {
    return getWaveColorAndThreshold(wave)['warningText'];
  }

  // 시정 경고 텍스트 가져오기
  String getVisibilityWarningText(double visibility) {
    return getVisibilityColorAndThreshold(visibility)['warningText'];
  }

  // 파고 임계값 텍스트 포맷팅
  String getFormattedWaveThresholdText(double wave) {
    double threshold = getWaveThreshold(wave);
    String warningText = getWaveWarningText(wave);
    return '${threshold.toStringAsFixed(2)}m$warningText';
  }

  // 시정 임계값 텍스트 포맷팅
  String getFormattedVisibilityThresholdText(double visibility) {
    double threshold = getVisibilityThreshold(visibility);
    String warningText = getVisibilityWarningText(visibility);

    // 임계값이 1000m 이상인 경우 km 단위로 변환
    if (threshold >= 1000) {
      double thresholdInKm = threshold / 1000;
      return '${thresholdInKm.toStringAsFixed(0)}km$warningText';
    } else {
      // 1000m 미만인 경우 m 단위 유지
      return '${threshold.toStringAsFixed(0)}m$warningText';
    }
  }
}