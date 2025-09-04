import 'dart:async';
import 'package:flutter/material.dart';

/// 메모리 관리 서비스
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();
  
  // 관리할 리소스들
  final List<StreamSubscription> _subscriptions = [];
  final List<AnimationController> _animationControllers = [];
  final List<Timer> _timers = [];
  final List<ChangeNotifier> _notifiers = [];
  
  /// StreamSubscription 등록
  void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
    debugPrint('📝 Subscription registered. Total: ${_subscriptions.length}');
  }
  
  /// AnimationController 등록
  void registerAnimationController(AnimationController controller) {
    _animationControllers.add(controller);
    debugPrint('🎬 Animation controller registered. Total: ${_animationControllers.length}');
  }
  
  /// Timer 등록
  void registerTimer(Timer timer) {
    _timers.add(timer);
    debugPrint('⏰ Timer registered. Total: ${_timers.length}');
  }
  
  /// ChangeNotifier 등록
  void registerNotifier(ChangeNotifier notifier) {
    _notifiers.add(notifier);
    debugPrint('🔔 Notifier registered. Total: ${_notifiers.length}');
  }
  
  /// 모든 리소스 정리
  void disposeAll() {
    debugPrint('🧹 Cleaning up all resources...');
    
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();
    
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    
    for (final notifier in _notifiers) {
      notifier.dispose();
    }
    _notifiers.clear();
    
    debugPrint('✅ All resources cleaned up');
  }
}
