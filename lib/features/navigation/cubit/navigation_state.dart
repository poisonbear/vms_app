part of 'navigation_cubit.dart';

/// 항행 관련 상태
class NavigationState extends Equatable {
  const NavigationState({
    this.navigationHistory = const [],
    this.weatherInfo,
    this.navigationWarnings,
    this.weatherList = const [],
    this.isLoading = false,
    this.isLoadingWeather = false,
    this.isInitialized = false,
    this.errorMessage = '',
  });

  /// 항행 이력 목록
  final List<NavigationHistoryModel> navigationHistory;

  /// 날씨 정보 (파고, 시정)
  final WeatherInfoModel? weatherInfo;

  /// 항행경보 알림
  final NavigationWarningModel? navigationWarnings;

  /// 기상정보 목록
  final List<WeatherModel> weatherList;

  /// 항행 이력 로딩 상태
  final bool isLoading;

  /// 기상정보 로딩 상태
  final bool isLoadingWeather;

  /// 초기화 여부 (조회 버튼 클릭 여부)
  final bool isInitialized;

  /// 에러 메시지
  final String errorMessage;

  /// 상태 복사 메소드
  NavigationState copyWith({
    List<NavigationHistoryModel>? navigationHistory,
    WeatherInfoModel? weatherInfo,
    NavigationWarningModel? navigationWarnings,
    List<WeatherModel>? weatherList,
    bool? isLoading,
    bool? isLoadingWeather,
    bool? isInitialized,
    String? errorMessage,
  }) {
    return NavigationState(
      navigationHistory: navigationHistory ?? this.navigationHistory,
      weatherInfo: weatherInfo ?? this.weatherInfo,
      navigationWarnings: navigationWarnings ?? this.navigationWarnings,
      weatherList: weatherList ?? this.weatherList,
      isLoading: isLoading ?? this.isLoading,
      isLoadingWeather: isLoadingWeather ?? this.isLoadingWeather,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    navigationHistory,
    weatherInfo,
    navigationWarnings,
    weatherList,
    isLoading,
    isLoadingWeather,
    isInitialized,
    errorMessage,
  ];
}