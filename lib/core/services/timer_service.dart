import 'dart:async';
import 'package:vms_app/core/utils/app_logger.dart';

/// 타이머 중앙 관리 서비스
class TimerService {
  final Map<String, Timer?> _timers = {};
  static final TimerService _instance = TimerService._internal();
  
  factory TimerService() => _instance;
  TimerService._internal();
  
  /// 타이머 등록
  void registerTimer(String key, Timer timer) {
    AppLogger.d('Timer registered: $key');
    cancelTimer(key);
    _timers[key] = timer;
  }
  
  /// 특정 타이머 취소
  void cancelTimer(String key) {
    if (_timers.containsKey(key)) {
      _timers[key]?.cancel();
      _timers[key] = null;
      AppLogger.d('Timer cancelled: $key');
    }
  }
  
  /// 모든 타이머 취소
  void cancelAll() {
    AppLogger.d('Cancelling all timers: ${_timers.keys.join(", ")}');
    for (var timer in _timers.values) {
      timer?.cancel();
    }
    _timers.clear();
  }
  
  /// 리소스 정리
  void dispose() {
    cancelAll();
  }
  
  /// 타이머 활성 상태 확인
  bool isActive(String key) => _timers[key]?.isActive ?? false;
}
