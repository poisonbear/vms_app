import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// SVG 이미지를 로드하는 유틸리티 위젯
///
/// [svgUrl] : SVG 파일 경로
/// [height] : 이미지 높이
/// [width] : 이미지 너비
Widget svgload(String svgUrl, double height, double width) {
  return SvgPicture.asset(
    svgUrl,
    height: height,
    width: width,
    fit: BoxFit.contain,
  );
}

/// SVG 이미지 로더 클래스 - 더 많은 옵션 제공
class SvgLoader extends StatelessWidget {
  final String svgPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final BlendMode colorBlendMode;

  const SvgLoader({
    super.key,
    required this.svgPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode = BlendMode.srcIn,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      svgPath,
      width: width,
      height: height,
      fit: fit,
      colorFilter:
          color != null ? ColorFilter.mode(color!, colorBlendMode) : null,
    );
  }
}
