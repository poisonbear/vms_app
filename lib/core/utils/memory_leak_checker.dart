import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

/// 메모리 누수 체크 유틸리티
class MemoryLeakChecker {
  static final Map<String, int> _objectCounts = {};
  
  /// 객체 생성 추적
  static void trackObjectCreation(String className) {
    _objectCounts[className] = (_objectCounts[className] ?? 0) + 1;
    _logMemoryStatus();
  }
  
  /// 객체 소멸 추적
  static void trackObjectDisposal(String className) {
    _objectCounts[className] = (_objectCounts[className] ?? 1) - 1;
    if (_objectCounts[className]! <= 0) {
      _objectCounts.remove(className);
    }
    _logMemoryStatus();
  }
  
  /// 메모리 상태 로깅
  static void _logMemoryStatus() {
    developer.log(
      'Active objects: ${_objectCounts.toString()}',
      name: 'MemoryLeak',
    );
  }
  
  /// 메모리 누수 의심 객체 확인
  static void checkForLeaks() {
    final suspiciousObjects = _objectCounts.entries
        .where((entry) => entry.value > 5)
        .toList();
        
    if (suspiciousObjects.isNotEmpty) {
      developer.log(
        '⚠️ Potential memory leaks detected:',
        name: 'MemoryLeak',
      );
      for (final entry in suspiciousObjects) {
        developer.log(
          '  ${entry.key}: ${entry.value} instances',
          name: 'MemoryLeak',
        );
      }
    }
  }
  
  /// 현재 메모리 상태 반환
  static Map<String, int> getCurrentStatus() {
    return Map.from(_objectCounts);
  }
  
  /// 메모리 상태 리셋
  static void reset() {
    _objectCounts.clear();
    developer.log('Memory leak checker reset', name: 'MemoryLeak');
  }
}

/// 자동 dispose mixin
mixin AutoDisposeMixin<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<AnimationController> _animationControllers = [];
  final List<TextEditingController> _textControllers = [];
  final List<ScrollController> _scrollControllers = [];
  final List<FocusNode> _focusNodes = [];
  
  /// StreamSubscription 추가
  @protected
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }
  
  /// Timer 추가
  @protected
  void addTimer(Timer timer) {
    _timers.add(timer);
  }
  
  /// AnimationController 추가
  @protected
  void addAnimationController(AnimationController controller) {
    _animationControllers.add(controller);
  }
  
  /// TextEditingController 추가
  @protected
  void addTextController(TextEditingController controller) {
    _textControllers.add(controller);
  }
  
  /// ScrollController 추가
  @protected
  void addScrollController(ScrollController controller) {
    _scrollControllers.add(controller);
  }
  
  /// FocusNode 추가
  @protected
  void addFocusNode(FocusNode node) {
    _focusNodes.add(node);
  }
  
  @override
  void initState() {
    super.initState();
    // 개발 모드에서만 메모리 추적
    assert(() {
      MemoryLeakChecker.trackObjectCreation(widget.runtimeType.toString());
      return true;
    }());
  }
  
  @override
  void dispose() {
    // 개발 모드에서만 메모리 추적
    assert(() {
      MemoryLeakChecker.trackObjectDisposal(widget.runtimeType.toString());
      return true;
    }());
    
    // 모든 구독 취소
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    // 모든 타이머 취소
    for (final timer in _timers) {
      if (timer.isActive) {
        timer.cancel();
      }
    }
    _timers.clear();
    
    // 모든 애니메이션 컨트롤러 dispose
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();
    
    // 모든 텍스트 컨트롤러 dispose
    for (final controller in _textControllers) {
      controller.dispose();
    }
    _textControllers.clear();
    
    // 모든 스크롤 컨트롤러 dispose
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    _scrollControllers.clear();
    
    // 모든 포커스 노드 dispose
    for (final node in _focusNodes) {
      node.dispose();
    }
    _focusNodes.clear();
    
    super.dispose();
  }
}

/// 메모리 사용량 모니터링 위젯
class MemoryMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const MemoryMonitor({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<MemoryMonitor> createState() => _MemoryMonitorState();
}

class _MemoryMonitorState extends State<MemoryMonitor> {
  Timer? _timer;
  Map<String, int> _memoryStatus = {};

  @override
  void initState() {
    super.initState();
    if (widget.showOverlay) {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        setState(() {
          _memoryStatus = MemoryLeakChecker.getCurrentStatus();
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showOverlay || _memoryStatus.isEmpty) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Memory Monitor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ..._memoryStatus.entries.map((entry) {
                  final isLeak = entry.value > 5;
                  return Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      color: isLeak ? Colors.red : Colors.green,
                      fontSize: 10,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
