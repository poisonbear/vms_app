import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/navigation_history_model.dart';
import '../models/navigation_warning_model.dart';
import '../repositories/navigation_repository.dart';
import '../../weather/models/weather_model.dart';

part 'navigation_state.dart';

/// 항행 관련 비즈니스 로직을 처리하는 Cubit
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit({
    required NavigationRepository repository,
  }) : _repository = repository, super(const NavigationState());

  final NavigationRepository _repository;

  /// 항행 이력 목록 로드
  Future<void> loadNavigationHistory({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      final historyList = await _repository.getNavigationHistory(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
        shipName: shipName,
      );

      emit(state.copyWith(
        navigationHistory: historyList,
        isLoading: false,
        isInitialized: true,
        errorMessage: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '항행 이력을 불러오는 중 오류가 발생했습니다: $e',
      ));
    }
  }

  /// 날씨 정보 로드
  Future<void> loadWeatherInfo() async {
    try {
      final weatherInfo = await _repository.getWeatherInfo();
      if (weatherInfo != null) {
        emit(state.copyWith(weatherInfo: weatherInfo));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '날씨 정보를 불러오는 중 오류가 발생했습니다: $e',
      ));
    }
  }

  /// 항행경보 알림 로드
  Future<void> loadNavigationWarnings() async {
    try {
      final warnings = await _repository.getNavigationWarnings();
      if (warnings != null) {
        emit(state.copyWith(navigationWarnings: warnings));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '항행경보를 불러오는 중 오류가 발생했습니다: $e',
      ));
    }
  }

  /// 기상정보 목록 로드
  Future<void> loadWeatherList() async {
    emit(state.copyWith(isLoadingWeather: true));

    try {
      final weatherList = await _repository.getWeatherList();
      emit(state.copyWith(
        weatherList: weatherList,
        isLoadingWeather: false,
        errorMessage: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingWeather: false,
        errorMessage: '기상정보를 불러오는 중 오류가 발생했습니다: $e',
      ));
    }
  }

  /// 상태 초기화
  void reset() {
    emit(const NavigationState());
  }
}