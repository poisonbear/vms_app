// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 상수
///
/// 사용 예시:
/// - Container(color: AppColors.primary)
/// - Container(color: AppColors.primaryOpacity(0.5))
class AppColors {
  AppColors._();

  // ============================================
  // Primary Colors
  // ============================================
  static const primary = Color(0xFF5CA1F6);
  static const secondary = Color(0xFF2196F3);
  static const accent = Color(0xFFFF9800);

  // ============================================
  // White Colors
  // ============================================
  static const whiteType1 = Color(0xFFFFFFFF);

  // ============================================
  // Black Colors
  // ============================================
  static const blackType1 = Colors.black;
  static const blackType2 = Color(0xFF333333);
  static const blackType3 = Color(0x00000000);
  static const blackType4 = Color(0x99000000);

  // ============================================
  // Gray Colors
  // ============================================
  static const grayType1 = Color(0x66333333);
  static const grayType2 = Color(0xFF999999);
  static const grayType3 = Color(0xFF666666);
  static const grayType4 = Color(0xFFDDDDDD);
  static const grayType5 = Color(0xFFEDEDED);
  static const grayType6 = Color(0xFF838383);
  static const grayType7 = Color(0xFFCCCCCC);
  static const grayType8 = Color(0xFF333333);
  static const grayType9 = Color(0x33333333);
  static const grayType10 = Color(0xFFEEEEEE);
  static const grayType11 = Color(0xFFD9D9D9);
  static const grayType12 = Color(0x33D9D9D9);
  static const grayType13 = Color(0xFFAAAAAA);
  static const grayType14 = Color(0xFFF5F5F5);
  static const grayType15 = Color(0xFFF8F9FA);
  static const grayType16 = Color(0xFFE9ECEF);

  // ============================================
  // Red Colors
  // ============================================
  static const redType1 = Color(0xFFDF2B2E);
  static const redType2 = Color(0xFFCD0000);
  static const redType3 = Color(0xFFDF2B2E);

  // ============================================
  // Sky Colors
  // ============================================
  static const skyType1 = Color(0xFFDDEDFF);
  static const skyType2 = Color(0xFF5CA1F6);
  static const skyType3 = Color(0xFF2196F3);

  // ============================================
  // Main Colors
  // ============================================
  static const mainType1 = Color(0xFF5CA1F6);

  // ============================================
  // Green Colors
  // ============================================
  static const greenType1 = Color(0xFF80BE35);

  // ============================================
  // blue Colors
  // ============================================
  static const blueNavy = Color(0xFF1E3A5F);

  // ============================================
  // Yellow Colors
  // ============================================
  static const yellowType1 = Color(0xFFF0CF3E);
  static const yellowType2 = Color(0xFFC28100);

  // ============================================
  // Emergency Red Colors
  // ============================================
  static const emergencyRed = Colors.red;
  static const emergencyRed50 = Color(0xFFFFEBEE);
  static const emergencyRed100 = Color(0xFFFFCDD2);
  static const emergencyRed200 = Color(0xFFEF9A9A);
  static const emergencyRed400 = Color(0xFFEF5350);
  static const emergencyRed500 = Color(0xFFF44336);
  static const emergencyRed600 = Color(0xFFE53935);
  static const emergencyRed700 = Color(0xFFD32F2F);
  static const emergencyRed800 = Color(0xFFDC2626);
  static const emergencyRed900 = Color(0xFFB91C1C);

  // ============================================
  // Emergency Blue Colors
  // ============================================
  static const emergencyBlue50 = Color(0xFFE3F2FD);
  static const emergencyBlue200 = Color(0xFF90CAF9);

  // ============================================
  // Emergency Other Colors
  // ============================================
  static const emergencyOrange = Colors.orange;
  static const emergencyGreen = Colors.green;
  static const emergencyGreenAccent = Colors.greenAccent;

  // ============================================
  // 경고/알림 색상 (Warning Colors)
  // ============================================
  static const warningBg = Color(0xFFFFFBEB); // 크림색 배경
  static const warningBorder = Color(0xFFFDE68A); // 부드러운 노란색 테두리
  static const warningIconBg = Color(0xFFFBBF24); // 골드 아이콘 배경
  static const warningText = Color(0xFF92400E); // 브라운 텍스트

  //수정: withOpacity → withValues
  static final warningBgLight = warningBg.withValues(alpha: 0.8);
  static final warningTextLight = warningText.withValues(alpha: 0.8);

  // ============================================
  // Flutter Material Colors (직접 참조)
  // ============================================
  static const white = Colors.white;
  static const black = Colors.black;
  static const grey = Colors.grey;
  static const transparent = Colors.transparent;
  static const red = Colors.red;
  static const orange = Colors.orange;
  static const green = Colors.green;
  static const blue = Colors.blue;

  // Material의 미리 정의된 opacity 색상
  static const white70 = Colors.white70;

  // ============================================
  // Opacity Helper Methods
  // ============================================
  /// 색상에 투명도 적용 (일반)
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);

  /// White에 투명도 적용
  static Color whiteOpacity(double opacity) =>
      Colors.white.withValues(alpha: opacity);

  /// Black에 투명도 적용
  static Color blackOpacity(double opacity) =>
      Colors.black.withValues(alpha: opacity);

  /// Emergency Red에 투명도 적용
  static Color emergencyRedOpacity(double opacity) =>
      emergencyRed.withValues(alpha: opacity);

  // ============================================
  // 자주 사용하는 투명도 (편의 상수)
  // ============================================
  static final white80 = Colors.white.withValues(alpha: 0.8);
  static final black05 = Colors.black.withValues(alpha: 0.05);
  static final black30 = Colors.black.withValues(alpha: 0.3);
  static final emergencyRed30 = emergencyRed.withValues(alpha: 0.3);
  static final emergencyRed40 = emergencyRed.withValues(alpha: 0.4);
}

/// 폰트 굵기 상수
class FontWeights {
  FontWeights._();

  static const normal = FontWeight.normal;
  static const bold = FontWeight.bold;
  static const w400 = FontWeight.w400;
  static const w500 = FontWeight.w500;
  static const w600 = FontWeight.w600;
  static const w700 = FontWeight.w700;
}

/// 텍스트 정렬 상수
class TextAligns {
  TextAligns._();

  static const center = TextAlign.center;
  static const left = TextAlign.left;
  static const right = TextAlign.right;
  static const justify = TextAlign.justify;
}

/// Border 관련 상수
class Borders {
  Borders._();

  /// 기본 둥근 모서리 (radius 10)
  static final rounded10 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10.0),
  );

  /// BorderRadius 직접 제공 (radius 10)
  static final radius10 = BorderRadius.circular(10.0);

  /// BorderRadius 직접 제공 (radius 6)
  static final radius6 = BorderRadius.circular(6.0);
}
