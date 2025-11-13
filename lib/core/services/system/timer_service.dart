// lib/core/services/system/timer_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 타이머 서비스
///
/// 앱 전체에서 사용되는 타이머를 중앙 집중식으로 관리합니다.
class TimerService {
  static TimerService? _instance;

  final Map<String, Timer> _timers = {};
  final Map<String, StreamController> _streamControllers = {};

  // ============================================
  // 타이머 이름 상수
  // ============================================

  static const String WEATHER_UPDATE = 'weather_update';
  static const String ROUTE_UPDATE = 'route_update';
  static const String VESSEL_UPDATE = 'vessel_update';
  static const String autoRefresh = 'auto_refresh';
  static const String locationUpdate = 'location_update';
  static const String weatherUpdate = 'weather_update';
  static const String vesselTracking = 'vessel_tracking';
  static const String sessionTimeout = 'session_timeout';

  // ============================================
  // Singleton
  // ============================================

  TimerService._();

  factory TimerService() {
    _instance ??= TimerService._();
    return _instance!;
  }

  // ============================================
  // 타이머 시작 메서드
  // ============================================

  /// 반복 타이머 시작
  void startTimer({
    required String name,
    required Duration duration,
    required VoidCallback callback,
    bool immediate = false,
  }) {
    cancelTimer(name);

    if (immediate) {
      try {
        callback();
      } catch (e) {
        AppLogger.e('Immediate callback error ($name): $e');
      }
    }

    _timers[name] = Timer.periodic(duration, (_) {
      try {
        callback();
      } catch (e) {
        AppLogger.e('Timer callback error ($name): $e');
      }
    });

    AppLogger.d('Timer started: $name (${duration.inSeconds}s)');
  }

  /// 일회성 타이머 시작
  void startOnceTimer({
    required String name,
    required Duration duration,
    required VoidCallback callback,
  }) {
    cancelTimer(name);

    _timers[name] = Timer(duration, () {
      try {
        callback();
        _timers.remove(name);
      } catch (e) {
        AppLogger.e('Once timer error ($name): $e');
      }
    });

    AppLogger.d('Once timer started: $name (${duration.inSeconds}s)');
  }

  /// 반복 타이머 시작 (별칭)
  void startPeriodicTimer(
    String name,
    Duration duration,
    VoidCallback callback,
  ) {
    startTimer(name: name, duration: duration, callback: callback);
  }

  /// 반복 타이머 시작 (명명된 매개변수)
  void startPeriodicTimerNamed({
    required String timerId,
    required Duration duration,
    required VoidCallback callback,
  }) {
    startTimer(name: timerId, duration: duration, callback: callback);
  }

  // ============================================
  // 타이머 제어 메서드
  // ============================================

  /// 특정 타이머 중지
  void stopTimer(String name) {
    cancelTimer(name);
  }

  /// 특정 타이머 취소
  void cancelTimer(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.cancel();
      _timers.remove(name);
      AppLogger.d('Timer cancelled: $name');
    }

    final controller = _streamControllers[name];
    if (controller != null) {
      controller.close();
      _streamControllers.remove(name);
    }
  }

  /// 모든 타이머 중지
  void stopAllTimers() {
    cancelAll();
  }

  /// 모든 타이머 취소
  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();

    AppLogger.d('All timers cancelled');
  }

  // ============================================
  // 상태 확인 메서드
  // ============================================

  /// 타이머 활성화 여부 확인
  bool isActive(String name) {
    return _timers[name]?.isActive ?? false;
  }

  // ============================================
  // 통계 및 모니터링
  // ============================================

  /// 타이머 통계 정보
  Map<String, dynamic> getStatistics() {
    final activeTimers =
        _timers.keys.where((key) => _timers[key]?.isActive ?? false).toList();

    return {
      'active': activeTimers,
      'total': _timers.length,
      'streams': _streamControllers.keys.toList(),
    };
  }

  // ============================================
  // 리소스 정리
  // ============================================

  /// 리소스 정리
  void dispose() {
    cancelAll();
  }
}
