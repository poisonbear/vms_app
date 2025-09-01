#!/bin/bash

# VMS App - 메모리 누수 체크 파일 수정 스크립트
# 실행 방법: Git Bash에서 프로젝트 루트 디렉토리에서 실행
# chmod +x fix_memory_leak_checker.sh && ./fix_memory_leak_checker.sh

echo "========================================="
echo "메모리 누수 체크 파일 수정"
echo "========================================="

# 1. check_memory_leaks.dart를 lib/core/utils 폴더로 이동하고 import 추가
echo ""
echo "📝 memory_leak_checker.dart 파일 생성 중..."

mkdir -p lib/core/utils

cat > lib/core/utils/memory_leak_checker.dart << 'EOF'
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
EOF

echo "✅ memory_leak_checker.dart 생성 완료"

# 2. 기존 check_memory_leaks.dart 파일 삭제
if [ -f "check_memory_leaks.dart" ]; then
    rm check_memory_leaks.dart
    echo "✅ 기존 check_memory_leaks.dart 파일 삭제"
fi

# 3. 사용 예제 파일 생성
echo ""
echo "📝 사용 예제 파일 생성 중..."

cat > lib/presentation/screens/example/memory_optimized_screen.dart << 'EOF'
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vms_app/core/utils/memory_leak_checker.dart';

/// AutoDisposeMixin을 사용한 메모리 최적화 화면 예제
class MemoryOptimizedScreen extends StatefulWidget {
  const MemoryOptimizedScreen({super.key});

  @override
  State<MemoryOptimizedScreen> createState() => _MemoryOptimizedScreenState();
}

class _MemoryOptimizedScreenState extends State<MemoryOptimizedScreen>
    with AutoDisposeMixin {
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  Timer? _timer;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    
    // 컨트롤러 초기화 및 자동 dispose 등록
    _textController = TextEditingController();
    addTextController(_textController);
    
    _scrollController = ScrollController();
    addScrollController(_scrollController);
    
    _focusNode = FocusNode();
    addFocusNode(_focusNode);
    
    // 타이머 생성 및 자동 dispose 등록
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // 주기적인 작업
      debugPrint('Timer tick: ${timer.tick}');
    });
    if (_timer != null) {
      addTimer(_timer!);
    }
    
    // Stream 구독 예제
    _subscription = Stream.periodic(const Duration(seconds: 3), (i) => i)
        .listen((value) {
      debugPrint('Stream value: $value');
    });
    if (_subscription != null) {
      addSubscription(_subscription!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메모리 최적화 화면'),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              labelText: '텍스트 입력',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AutoDisposeMixin을 사용하면 dispose 메서드에서\n'
            '모든 컨트롤러, 타이머, 구독이 자동으로 정리됩니다.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              MemoryLeakChecker.checkForLeaks();
            },
            child: const Text('메모리 누수 체크'),
          ),
        ],
      ),
    );
  }
  
  // dispose 메서드를 오버라이드할 필요 없음!
  // AutoDisposeMixin이 자동으로 처리
}
EOF

echo "✅ memory_optimized_screen.dart 예제 생성 완료"

# 4. 검증 스크립트 생성
echo ""
echo "📝 검증 스크립트 생성 중..."

cat > verify_memory_fix.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "메모리 누수 체크 파일 검증"
echo "========================================="

# 1. 파일 존재 확인
echo ""
echo "1. 파일 존재 확인:"
if [ -f "lib/core/utils/memory_leak_checker.dart" ]; then
    echo "✅ memory_leak_checker.dart 파일 존재"
else
    echo "❌ memory_leak_checker.dart 파일 없음"
fi

if [ -f "lib/presentation/screens/example/memory_optimized_screen.dart" ]; then
    echo "✅ memory_optimized_screen.dart 예제 파일 존재"
else
    echo "❌ memory_optimized_screen.dart 예제 파일 없음"
fi

# 2. Flutter analyze 실행
echo ""
echo "2. Flutter analyze 실행:"
flutter analyze lib/core/utils/memory_leak_checker.dart

if [ $? -eq 0 ]; then
    echo "✅ 에러 없음"
else
    echo "❌ 에러 발견"
fi

# 3. import 확인
echo ""
echo "3. 필요한 import 확인:"
echo "memory_leak_checker.dart의 import:"
head -5 lib/core/utils/memory_leak_checker.dart

echo ""
echo "========================================="
echo "검증 완료"
echo "========================================="
EOF

chmod +x verify_memory_fix.sh

echo "✅ verify_memory_fix.sh 생성 완료"

# 5. 기존 check_memory_leaks.dart 관련 파일 정리
echo ""
echo "🧹 기존 파일 정리 중..."

# Root 디렉토리의 check_memory_leaks.dart 삭제
if [ -f "check_memory_leaks.dart" ]; then
    rm check_memory_leaks.dart
    echo "✅ root/check_memory_leaks.dart 삭제"
fi

# optimize_images.dart도 lib/core/utils로 이동
if [ -f "optimize_images.dart" ]; then
    mv optimize_images.dart lib/core/utils/optimize_images.dart
    echo "✅ optimize_images.dart를 lib/core/utils로 이동"
fi

echo ""
echo "========================================="
echo "✅ 메모리 누수 체크 파일 수정 완료!"
echo "========================================="
echo ""
echo "📌 생성/이동된 파일:"
echo "  - lib/core/utils/memory_leak_checker.dart (수정됨)"
echo "  - lib/presentation/screens/example/memory_optimized_screen.dart (예제)"
echo "  - lib/core/utils/optimize_images.dart (이동됨)"
echo ""
echo "📌 삭제된 파일:"
echo "  - check_memory_leaks.dart (root 디렉토리)"
echo ""
echo "🔧 다음 단계:"
echo "  1. 수정 검증:"
echo "     ./verify_memory_fix.sh"
echo ""
echo "  2. Flutter analyze 확인:"
echo "     flutter analyze | grep -e 'error'"
echo ""
echo "  3. 사용 예제:"
echo "     - AutoDisposeMixin을 State 클래스에 추가"
echo "     - addTimer(), addSubscription() 등으로 자동 dispose 등록"
echo ""
echo "💡 사용 방법:"
echo "```dart"
echo "class _MyScreenState extends State<MyScreen>"
echo "    with AutoDisposeMixin {"
echo "  "
echo "  @override"
echo "  void initState() {"
echo "    super.initState();"
echo "    "
echo "    final timer = Timer.periodic(...);"
echo "    addTimer(timer); // 자동 dispose 등록"
echo "  }"
echo "  // dispose 메서드 작성 불필요!"
echo "}"
echo "```"
