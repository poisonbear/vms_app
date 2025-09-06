#!/bin/bash

echo "🔧 2단계: FlashOverlay 위젯 안전 분리 (기능 변경 없음)..."
echo ""

# 1. flash_overlay.dart 파일 생성 (단순 위젯만)
echo "📝 Creating widgets/flash_overlay.dart..."
cat > lib/presentation/screens/main/widgets/flash_overlay.dart << 'EOF'
import 'package:flutter/material.dart';

/// 터빈 진입 경고 플래시 오버레이 위젯
/// main_screen.dart의 AnimatedBuilder 부분만 분리
class FlashOverlay extends StatelessWidget {
  final AnimationController flashController;
  final bool isFlashing;

  const FlashOverlay({
    super.key,
    required this.flashController,
    required this.isFlashing,
  });

  @override
  Widget build(BuildContext context) {
    // 기존 main_screen.dart의 코드 그대로
    if (!isFlashing) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: flashController,
      builder: (context, child) {
        return Stack(
          children: [
            // 전체 투명
            Container(color: Colors.transparent),

            // 상단
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 250,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(
                          255, 0, 0, 0.6 * flashController.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 하단 (navigation bar는 안 가리게)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 250,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color.fromRGBO(
                          255, 0, 0, 0.6 * flashController.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 왼쪽
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.fromRGBO(
                          255, 0, 0, 0.6 * flashController.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 오른쪽
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Color.fromRGBO(
                          255, 0, 0, 0.6 * flashController.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
EOF

echo "✅ flash_overlay.dart 생성 완료!"
echo ""

# 2. main_screen.dart 수정 가이드 (최소한의 변경만)
echo "📝 Creating modification guide..."
cat > modify_main_screen_step2_safe.dart << 'EOF'
// main_screen.dart 수정 가이드 (안전 버전)

// 1. 상단에 import 추가:
import 'widgets/flash_overlay.dart';

// 2. build 메서드의 Stack 내부에서 플래시 부분만 교체:
/*
기존 코드 (약 100줄):
// Stack의 맨 마지막에 추가 (가장 위에 렌더링되도록)
if (_isFlashing)
  AnimatedBuilder(
    animation: _flashController,
    builder: (context, child) {
      return Stack(
        children: [
          // 전체 투명
          Container(color: Colors.transparent),

          // 상단
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(
                        255, 0, 0, 0.6 * _flashController.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 하단, 왼쪽, 오른쪽... (생략)
        ],
      );
    },
  ),

새 코드 (3줄):
// Stack의 맨 마지막에 추가 (가장 위에 렌더링되도록)
FlashOverlay(
  flashController: _flashController,
  isFlashing: _isFlashing,
),
*/

// 중요: 다른 코드는 전혀 건드리지 않습니다!
// - _flashController 변수 유지
// - _isFlashing 변수 유지
// - _startFlashing() 메서드 유지
// - _stopFlashing() 메서드 유지
// - initState, dispose 등 모두 그대로 유지
EOF

echo "📋 수정 가이드 생성 완료!"
echo ""
echo "======================================"
echo "📌 2단계 작업 요약 (안전 버전)"
echo "======================================"
echo ""
echo "✅ 생성된 파일:"
echo "   - lib/presentation/screens/main/widgets/flash_overlay.dart"
echo ""
echo "📝 main_screen.dart 수정 방법:"
echo ""
echo "1. import 추가:"
echo "   import 'widgets/flash_overlay.dart';"
echo ""
echo "2. Stack 내부의 AnimatedBuilder 부분만 교체:"
echo "   기존: if (_isFlashing) AnimatedBuilder(...) // 약 100줄"
echo "   신규: FlashOverlay("
echo "           flashController: _flashController,"
echo "           isFlashing: _isFlashing,"
echo "         )"
echo ""
echo "⚠️  중요: 다른 코드는 전혀 변경하지 않음!"
echo "   - 모든 변수명 유지 (_flashController, _isFlashing)"
echo "   - 모든 메서드 유지 (_startFlashing, _stopFlashing)"
echo "   - 애니메이션 로직 그대로 유지"
echo ""
echo "📊 효과:"
echo "   - 코드 라인: 약 100줄 → 3줄로 감소"
echo "   - 기능: 100% 동일"
echo "   - UI: 100% 동일"
echo "   - 리스크: 최소화"
echo ""
echo "======================================"
echo "테스트 후 문제없으면 3단계로 진행하겠습니다!"
echo "======================================"
