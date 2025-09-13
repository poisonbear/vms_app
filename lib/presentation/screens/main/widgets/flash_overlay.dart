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
