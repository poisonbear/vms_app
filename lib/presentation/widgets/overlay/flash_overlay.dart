import 'package:flutter/material.dart';

/// 플래싱 오버레이 위젯 (터빈 진입 경고)
class FlashOverlay extends StatelessWidget {
  final Animation<double> animation;

  const FlashOverlay({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Stack(
              children: [
                Container(color: Colors.transparent),
                _buildGradient(Alignment.topCenter, 250, true),
                _buildGradient(Alignment.bottomCenter, 250, false),
                _buildGradient(Alignment.centerLeft, 100, true,
                    isVertical: false),
                _buildGradient(Alignment.centerRight, 100, false,
                    isVertical: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGradient(
    Alignment alignment,
    double size,
    bool isStart, {
    bool isVertical = true,
  }) {
    return Positioned(
      top: isVertical && alignment == Alignment.topCenter ? 0 : null,
      bottom: isVertical && alignment == Alignment.bottomCenter ? 0 : null,
      left: !isVertical && alignment == Alignment.centerLeft ? 0 : null,
      right: !isVertical && alignment == Alignment.centerRight ? 0 : null,
      width: isVertical ? null : size,
      height: isVertical ? size : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: alignment,
            end: isVertical
                ? (isStart ? Alignment.bottomCenter : Alignment.topCenter)
                : (isStart ? Alignment.centerRight : Alignment.centerLeft),
            colors: [
              Color.fromRGBO(255, 0, 0, 0.6 * animation.value),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
