part of 'vessel_cubit.dart';

/// 선박 관련 상태
class VesselState extends Equatable {
  const VesselState({
    this.vessels = const [],
    this.predRoutes = const [],
    this.pastRoutes = const [],
    this.isLoading = false,
    this.isLoadingRoute = false,
    this.isNavigationHistoryMode = false,
    this.isTrackingEnabled = false,
    this.isOtherVesselsVisible = true,
    this.selectedVesselMmsi,
    this.errorMessage = '',
  });

  /// 선박 목록
  final List<VesselModel> vessels;

  /// 예측 항로 목록
  final List<PredRouteModel> predRoutes;

  /// 과거 항적 목록
  final List<PastRouteModel> pastRoutes;

  /// 선박 목록 로딩 상태
  final bool isLoading;

  /// 항로 데이터 로딩 상태
  final bool isLoadingRoute;

  /// 항행 이력 모드 여부
  final bool isNavigationHistoryMode;

  /// 항적 추적 활성화 여부
  final bool isTrackingEnabled;

  /// 다른 선박 가시성 여부
  final bool isOtherVesselsVisible;

  /// 선택된 선박 MMSI
  final int? selectedVesselMmsi;

  /// 에러 메시지
  final String errorMessage;

  /// 상태 복사 메소드
  VesselState copyWith({
    List<VesselModel>? vessels,
    List<PredRouteModel>? predRoutes,
    List<PastRouteModel>? pastRoutes,
    bool? isLoading,
    bool? isLoadingRoute,
    bool? isNavigationHistoryMode,
    bool? isTrackingEnabled,
    bool? isOtherVesselsVisible,
    int? selectedVesselMmsi,
    String? errorMessage,
  }) {
    return VesselState(
      vessels: vessels ?? this.vessels,
      predRoutes: predRoutes ?? this.predRoutes,
      pastRoutes: pastRoutes ?? this.pastRoutes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      isNavigationHistoryMode: isNavigationHistoryMode ?? this.isNavigationHistoryMode,
      isTrackingEnabled: isTrackingEnabled ?? this.isTrackingEnabled,
      isOtherVesselsVisible: isOtherVesselsVisible ?? this.isOtherVesselsVisible,
      selectedVesselMmsi: selectedVesselMmsi ?? this.selectedVesselMmsi,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    vessels,
    predRoutes,
    pastRoutes,
    isLoading,
    isLoadingRoute,
    isNavigationHistoryMode,
    isTrackingEnabled,
    isOtherVesselsVisible,
    selectedVesselMmsi,
    errorMessage,
  ];
}