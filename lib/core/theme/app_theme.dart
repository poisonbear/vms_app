import 'package:flutter/material.dart';

/// 앱 테마 정의
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      splashFactory: NoSplash.splashFactory,
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.black),
        titleTextStyle: TextStyle(
          color: AppColors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      fontFamily: 'PretendardVariable',
    );
  }
}

/// 앱 색상 정의
class AppColors {
  // 기본 색상
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black2 = Color(0xFF333333);
  static const Color black3 = Color(0x00000000);
  static const Color black4 = Color(0x99000000);

  // 회색
  static const Color gray1 = Color(0x66333333);
  static const Color gray2 = Color(0xFF999999);
  static const Color gray3 = Color(0xFF666666);
  static const Color gray4 = Color(0xFFDDDDDD);
  static const Color gray5 = Color(0xFFEDEDED);
  static const Color gray6 = Color(0xFF838383);
  static const Color gray7 = Color(0xFFCCCCCC);
  static const Color gray8 = Color(0xFF333333);
  static const Color gray9 = Color(0x33333333);
  static const Color gray10 = Color(0xFFEEEEEE);
  static const Color gray11 = Color(0xFFD9D9D9);
  static const Color gray12 = Color(0x33D9D9D9);
  static const Color gray13 = Color(0xFFAAAAAA);
  static const Color gray14 = Color(0xFFF5F5F5);

  // 빨간색
  static const Color red1 = Color(0xFFDF2B2E);
  static const Color red2 = Color(0xFFCD0000);
  static const Color red3 = Color(0xFFDF2B2E);

  // 하늘색
  static const Color sky1 = Color(0xFFDDEDFF);
  static const Color sky2 = Color(0xFF5CA1F6);
  static const Color sky3 = Color(0xFF2196F3);

  // 초록색
  static const Color green1 = Color(0xFF80BE35);

  // 노란색
  static const Color yellow1 = Color(0xFFF0CF3E);
  static const Color yellow2 = Color(0xFFC28100);
}

/// 앱 텍스트 스타일
class AppTextStyles {
  static const TextStyle bold = TextStyle(fontWeight: FontWeight.bold);
  static const TextStyle w400 = TextStyle(fontWeight: FontWeight.w400);
  static const TextStyle w600 = TextStyle(fontWeight: FontWeight.w600);
  static const TextStyle w700 = TextStyle(fontWeight: FontWeight.w700);
  static const TextStyle normal = TextStyle(fontWeight: FontWeight.normal);
}

/// 앱 크기 상수
class AppSizes {
  static const double size0 = 0;
  static const double size1 = 1;
  static const double size2 = 2;
  static const double size3 = 3;
  static const double size4 = 4;
  static const double size5 = 5;
  static const double size6 = 6;
  static const double size7 = 7;
  static const double size8 = 8;
  static const double size9 = 9;
  static const double size10 = 10;
  static const double size12 = 12;
  static const double size13 = 13;
  static const double size14 = 14;
  static const double size15 = 15;
  static const double size16 = 16;
  static const double size18 = 18;
  static const double size20 = 20;
  static const double size21 = 21;
  static const double size24 = 24;
  static const double size25 = 25;
  static const double size26 = 26;
  static const double size28 = 28;
  static const double size29 = 29;
  static const double size30 = 30;
  static const double size32 = 32;
  static const double size34 = 34;
  static const double size35 = 35;
  static const double size36 = 36;
  static const double size37 = 37;
  static const double size40 = 40;
  static const double size41 = 41;
  static const double size44 = 44;
  static const double size45 = 45;
  static const double size48 = 48;
  static const double size50 = 50;
  static const double size54 = 54;
  static const double size56 = 56;
  static const double size60 = 60;
  static const double size65 = 65;
  static const double size70 = 70;
  static const double size80 = 80;
  static const double size92 = 92;
  static const double size96 = 96;
  static const double size100 = 100;
  static const double size120 = 120;
  static const double size133 = 133;
  static const double size134 = 134;
  static const double size150 = 150;
  static const double size160 = 160;
  static const double size170 = 170;
  static const double size206 = 206;
  static const double size266 = 266;
  static const double size300 = 300;
  static const double size312 = 312;
  static const double size400 = 400;
}

/// 앱 반지름 상수
class AppRadii {
  static BorderRadius get radius6 => BorderRadius.circular(6);
  static RoundedRectangleBorder get roundedBorder6 => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(6),
  );
}

/// 앱 텍스트 정렬
class AppTextAlign {
  static const TextAlign center = TextAlign.center;
  static const TextAlign left = TextAlign.left;
  static const TextAlign right = TextAlign.right;
}