import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 앱 전체 타이머 관리 서비스
class TimerService extends ChangeNotifier {
  // 타이머 식별자 상수
  static const String VESSEL_UPDATE = 'vessel_update';
  static const String ROUTE_UPDATE = 'route_update';
  static const String WEATHER_UPDATE = 'weather_update';
  static const String LOCATION_UPDATE = 'location_update';

  // 타이머 저장소
  final Map<String, Timer?> _timers = {};
  final Map<String, VoidCallback?> _callbacks = {};
  
  // dispose 상태 추적
  bool _isDisposed = false;

  // 타이머 상태 조회
  bool isTimerActive(String timerId) => _timers[timerId]?.isActive ?? false;

  /// 주기적 타이머 시작
  void startPeriodicTimer({
    required String timerId,
    required Duration duration,
    required VoidCallback callback,
  }) {
    if (_isDisposed) return;
    
    stopTimer(timerId);

    _callbacks[timerId] = callback;
    _timers[timerId] = Timer.periodic(duration, (_) {
      if (!_isDisposed) {
        callback();
      }
    });

    AppLogger.d('✅ Timer started: $timerId with duration: $duration');
    _safeNotifyListeners();
  }

  /// 단일 실행 타이머
  void startOnceTimer({
    required String timerId,
    required Duration duration,
    required VoidCallback callback,
  }) {
    if (_isDisposed) return;
    
    stopTimer(timerId);

    _callbacks[timerId] = callback;
    _timers[timerId] = Timer(duration, () {
      if (!_isDisposed) {
        callback();
        _timers.remove(timerId);
        _callbacks.remove(timerId);
        _safeNotifyListeners();
      }
    });

    AppLogger.d('⏱️ One-time timer started: $timerId');
  }

  /// 타이머 정지
  void stopTimer(String timerId) {
    if (_isDisposed) return;
    
    _timers[timerId]?.cancel();
    _timers.remove(timerId);
    _callbacks.remove(timerId);
    AppLogger.d('⏹️ Timer stopped: $timerId');
    _safeNotifyListeners();
  }

  /// 모든 타이머 정지
  void stopAllTimers() {
    if (_isDisposed) return;
    
    _timers.forEach((key, timer) {
      timer?.cancel();
    });
    _timers.clear();
    _callbacks.clear();
    AppLogger.d('🛑 All timers stopped');
    _safeNotifyListeners();
  }

  /// 타이머 재시작
  void restartTimer({
    required String timerId,
    required Duration duration,
  }) {
    if (_isDisposed) return;
    
    final callback = _callbacks[timerId];
    if (callback != null) {
      startPeriodicTimer(
        timerId: timerId,
        duration: duration,
        callback: callback,
      );
    }
  }
  
  /// 안전한 notifyListeners 호출
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // 모든 타이머 정리 (notifyListeners 호출 없이)
    _timers.forEach((key, timer) {
      timer?.cancel();
    });
    _timers.clear();
    _callbacks.clear();
    
    AppLogger.d('TimerService disposed');
    super.dispose();
  }
}
