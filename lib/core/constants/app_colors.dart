import 'package:flutter/material.dart';

// 색상

// 흰색
Color getColorWhiteType1() {
  return const Color(0xFFFFFFFF);
}

// 검은색
Color getColorBlackType1() {
  return Colors.black;
}

Color getColorBlackType2() {
  return const Color(0xFF333333);
}

Color getColorBlackType3() {
  return const Color(0x00000000);
}

Color getColorBlackType4() {
  return const Color(0x99000000);
}

//회색
Color getColorGrayType1() {
  return const Color(0x66333333);
}

Color getColorGrayType2() {
  return const Color(0xFF999999);
}

Color getColorGrayType3() {
  return const Color(0xFF666666);
}

Color getColorGrayType4() {
  return const Color(0xFFDDDDDD);
}

Color getColorGrayType5() {
  return const Color(0xFFEDEDED);
}

Color getColorGrayType6() {
  return const Color(0xFF838383);
}

Color getColorGrayType7() {
  return const Color(0xFFCCCCCC);
}

Color getColorGrayType8() {
  return const Color(0xFF333333);
}

Color getColorGrayType9() {
  return const Color(0x33333333);
}

Color getColorGrayType10() {
  return const Color(0xFFEEEEEE);
}

Color getColorGrayType11() {
  return const Color(0xFFD9D9D9);
}

Color getColorGrayType12() {
  return const Color(0x33D9D9D9);
}

Color getColorGrayType13() {
  return const Color(0xFFAAAAAA);
}

Color getColorGrayType14() {
  return const Color(0xFFF5F5F5);
}

//레드
Color getColorRedType1() {
  return const Color(0xFFDF2B2E);
}

Color getColorRedType2() {
  return const Color(0xFFCD0000);
}

Color getColorRedType3() {
  return const Color(0xFFDF2B2E);
}

//하늘색
Color getColorSkyType1() {
  return const Color(0xFFDDEDFF);
}

Color getColorSkyType2() {
  return const Color(0xFF5CA1F6);
}

Color getColorSkyType3() {
  return const Color(0xFF2196F3);
}

// 메인 컬러 추가
Color getColorMainType1() {
  return const Color(0xFF5CA1F6); // getColorSkyType2와 동일한 색상 사용
}

// 초록색
Color getColorGreenType1() {
  return const Color(0xFF80BE35);
}

// 노란색
Color getColorYellowType1() {
  return const Color(0xFFF0CF3E);
}

Color getColorYellowType2() {
  return const Color(0xFFC28100);
}

// 폰트굵기
FontWeight getTextbold() {
  return FontWeight.bold;
}

FontWeight getText400() {
  return FontWeight.w400;
}

FontWeight getText700() {
  return FontWeight.w700;
}

FontWeight getText600() {
  return FontWeight.w600;
}

FontWeight getTextnormal() {
  return FontWeight.normal;
}

//폰트정렬
TextAlign getTextcenter() {
  return TextAlign.center;
}

TextAlign getTextleft() {
  return TextAlign.left;
}

TextAlign getTextright() {
  return TextAlign.right;
}

//테두리
RoundedRectangleBorder getTextradius6() {
  return RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0));
}

BorderRadius getTextRadius6Direct() {
  return BorderRadius.circular(10.0);
}