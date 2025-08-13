import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../models/vessel_model.dart';
import '../models/vessel_route_model.dart';
import '../repositories/vessel_repository.dart';

part 'vessel_state.dart';

/// 선박 관련 비즈니스 로직을 처리하는 Cubit
class VesselCubit extends Cubit<VesselState> {
  VesselCubit({
    required VesselRepository repository,
  }) : _repository = repository, super(const VesselState());

  final VesselRepository _repository;

  /// 선박 목록 로드
  Future<void> loadVesselList({
    String? regDt,
    int? mmsi,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      final vessels = await _repository.getVesselList(
        regDt: regDt,
        mmsi: mmsi,
      );

      emit(state.copyWith(
        vessels: vessels,
        isLoading: false,
        errorMessage: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '선박 목록을 불러오는 중 오류가 발생했습니다: $e',
      ));
    }
  }

  /// 선박 항로 로드
  Future<void> loadVesselRoute({
    required int mmsi,
    String? regDt,
    bool includePrediction = true,
  }) async {
    emit(state.copyWith(isLoadingRoute: true));

    try {
      final routeResponse = await _repository.getVesselRoute(
        regDt: regDt ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
        mmsi: mmsi,
      );

      emit(state.copyWith(
        predRoutes: includePrediction ? routeResponse.pred : [],
        pastRoutes: routeResponse.past,
        isLoadingRoute: false,
        isNavigationHistoryMode: !includePrediction,
        selectedVesselMmsi: mmsi,
        isTrackingEnabled: true,
        errorMessage: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingRoute: false,
        errorMessage: '항로 데이터를 불러오는 중 오류가 발생했습니다: $e',
      ));
    }
  }

  /// 항로 데이터 초기화
  void clearRoutes() {
    emit(state.copyWith(
      predRoutes: [],
      pastRoutes: [],
      isNavigationHistoryMode: false,
      selectedVesselMmsi: null,
      isTrackingEnabled: false,
    ));
  }

  /// 항행 이력 모드 설정
  void setNavigationHistoryMode(bool value) {
    emit(state.copyWith(isNavigationHistoryMode: value));
  }

  /// 추적 활성화 상태 설정
  void setTrackingEnabled(bool enabled) {
    emit(state.copyWith(isTrackingEnabled: enabled));
  }

  /// 선택된 선박 MMSI 설정
  void setSelectedVesselMmsi(int? mmsi) {
    emit(state.copyWith(selectedVesselMmsi: mmsi));
  }

  /// 다른 선박 가시성 토글
  void toggleOtherVesselsVisibility() {
    emit(state.copyWith(
      isOtherVesselsVisible: !state.isOtherVesselsVisible,
    ));
  }
}