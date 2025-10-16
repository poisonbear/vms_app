import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// 원형 버튼 위젯 - 상태 관리 포함
class CircularButton extends StatefulWidget {
  final String svgPath;
  final Color colorOn;
  final Color colorOff;
  final int widthSize;
  final int heightSize;
  final VoidCallback onTap;

  const CircularButton({
    super.key,
    required this.svgPath,
    required this.colorOn,
    required this.colorOff,
    required this.widthSize,
    required this.heightSize,
    required this.onTap,
  });

  @override
  _CircularButtonState createState() => _CircularButtonState();
}

class _CircularButtonState extends State<CircularButton> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isOn = !isOn;
        });
        widget.onTap();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.widthSize.toDouble(),
            height: widget.heightSize.toDouble(),
            decoration: BoxDecoration(
              color: isOn ? widget.colorOn : widget.colorOff,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              widget.svgPath,
              width: 24.0,
              height: 24.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// 정적 원형 버튼 (상태 관리 없음)
class StaticCircularButton extends StatelessWidget {
  final String svgPath;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final double iconSize;

  const StaticCircularButton({
    super.key,
    required this.svgPath,
    required this.color,
    this.size = 50,
    this.onTap,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          svgPath,
          width: iconSize,
          height: iconSize,
        ),
      ),
    );
  }
}
