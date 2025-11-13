import 'package:flutter/material.dart';

/// 기본 텍스트 위젯
///
/// [title] : 표시할 텍스트
/// [textAlign] : 텍스트 정렬
/// [size] : 폰트 크기
/// [fontWeight] : 폰트 굵기
/// [color] : 텍스트 색상
Widget TextWidgetString(
  String title,
  TextAlign textAlign,
  int size,
  FontWeight fontWeight,
  Color color,
) {
  return Text(
    title,
    textAlign: textAlign,
    style: TextStyle(
      fontFamily: 'PretendardVariable',
      fontSize: size.toDouble(),
      fontWeight: fontWeight,
      color: color,
    ),
  );
}

/// 밑줄이 있는 텍스트 위젯
///
/// [title] : 표시할 텍스트
/// [textAlign] : 텍스트 정렬
/// [size] : 폰트 크기
/// [fontWeight] : 폰트 굵기
/// [color] : 텍스트 색상
Widget TextWidgetStringLine(
  String title,
  TextAlign textAlign,
  int size,
  FontWeight fontWeight,
  Color color,
) {
  return Text(
    title,
    textAlign: textAlign,
    style: TextStyle(
      fontFamily: 'PretendardVariable',
      fontSize: size.toDouble(),
      fontWeight: fontWeight,
      color: color,
      decoration: TextDecoration.underline,
    ),
  );
}

/// 커스텀 텍스트 위젯 클래스 - 더 많은 옵션 제공
class CustomText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextDecoration? decoration;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;
  final double? height;

  const CustomText({
    super.key,
    required this.text,
    this.textAlign,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.decoration,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.left,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'PretendardVariable',
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? Colors.black,
        decoration: decoration,
        letterSpacing: letterSpacing,
        height: height,
      ),
    );
  }
}
