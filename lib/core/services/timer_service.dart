import 'dart:async';
import 'package:flutter/foundation.dart';

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
  
  // 타이머 상태 조회
  bool isTimerActive(String timerId) => _timers[timerId]?.isActive ?? false;
  
  /// 주기적 타이머 시작
  void startPeriodicTimer({
    required String timerId,
    required Duration duration,
    required VoidCallback callback,
  }) {
    stopTimer(timerId);
    
    _callbacks[timerId] = callback;
    _timers[timerId] = Timer.periodic(duration, (_) {
      callback();
    });
    
    debugPrint('✅ Timer started: $timerId with duration: $duration');
    notifyListeners();
  }
  
  /// 단일 실행 타이머
  void startOnceTimer({
    required String timerId,
    required Duration duration,
    required VoidCallback callback,
  }) {
    stopTimer(timerId);
    
    _callbacks[timerId] = callback;
    _timers[timerId] = Timer(duration, () {
      callback();
      _timers.remove(timerId);
      _callbacks.remove(timerId);
      notifyListeners();
    });
    
    debugPrint('⏱️ One-time timer started: $timerId');
  }
  
  /// 타이머 정지
  void stopTimer(String timerId) {
    _timers[timerId]?.cancel();
    _timers.remove(timerId);
    _callbacks.remove(timerId);
    debugPrint('⏹️ Timer stopped: $timerId');
    notifyListeners();
  }
  
  /// 모든 타이머 정지
  void stopAllTimers() {
    _timers.forEach((key, timer) {
      timer?.cancel();
    });
    _timers.clear();
    _callbacks.clear();
    debugPrint('🛑 All timers stopped');
    notifyListeners();
  }
  
  /// 타이머 재시작
  void restartTimer({
    required String timerId,
    required Duration duration,
  }) {
    final callback = _callbacks[timerId];
    if (callback != null) {
      startPeriodicTimer(
        timerId: timerId,
        duration: duration,
        callback: callback,
      );
    }
  }
  
  @override
  void dispose() {
    stopAllTimers();
    super.dispose();
  }
}
