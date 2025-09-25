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

// ============ Emergency 탭 전용 색상 (새로 추가) ============

// Emergency Red 계열
Color getColorEmergencyRed50() {
  return const Color(0xFFFFEBEE);  // Colors.red.shade50
}

Color getColorEmergencyRed100() {
  return const Color(0xFFFFCDD2);  // Colors.red.shade100
}

Color getColorEmergencyRed200() {
  return const Color(0xFFEF9A9A);  // Colors.red.shade200
}

Color getColorEmergencyRed400() {
  return const Color(0xFFEF5350);  // Colors.red.shade400
}

Color getColorEmergencyRed500() {
  return const Color(0xFFF44336);  // Colors.red.shade500
}

Color getColorEmergencyRed600() {
  return const Color(0xFFE53935);  // Colors.red.shade600
}

Color getColorEmergencyRed700() {
  return const Color(0xFFD32F2F);  // Colors.red.shade700
}

Color getColorEmergencyRed() {
  return Colors.red;  // 기본 red
}

// Emergency Blue 계열 (기타 연락처 섹션)
Color getColorEmergencyBlue50() {
  return const Color(0xFFE3F2FD);  // Colors.blue.shade50
}

Color getColorEmergencyBlue200() {
  return const Color(0xFF90CAF9);  // Colors.blue.shade200
}

// Emergency Green (위치 추적 활성화)
Color getColorEmergencyGreenAccent() {
  return Colors.greenAccent;
}

Color getColorEmergencyGreen() {
  return Colors.green;  // 완료 상태
}

// Emergency Orange (취소 상태)
Color getColorEmergencyOrange() {
  return Colors.orange;
}

// Emergency 투명도 적용 색상
Color getColorEmergencyWhite70() {
  return Colors.white70;
}

Color getColorEmergencyWhite80() {
  return Colors.white.withOpacity(0.8);
}

Color getColorEmergencyRedOpacity30() {
  return Colors.red.withOpacity(0.3);
}

Color getColorEmergencyRedOpacity40() {
  return Colors.red.withOpacity(0.4);
}

Color getColorEmergencyBlackOpacity05() {
  return Colors.black.withOpacity(0.05);
}

Color getColorEmergencyBlackOpacity30() {
  return Colors.black.withOpacity(0.3);
}

// 폰트굵기
FontWeight getTextbold() {
  return FontWeight.bold;
}

FontWeight getText400() {
  return FontWeight.w400;
}

FontWeight getText500() {
  return FontWeight.w500;
}

FontWeight getText600() {
  return FontWeight.w600;
}

FontWeight getText700() {
  return FontWeight.w700;
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