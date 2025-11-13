import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 텍스트 스타일
/// Material Design 3 타이포그래피 시스템 기반
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'PretendardVariable';

  // ========================================
  // Display Styles
  // ========================================
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // ========================================
  // Headline Styles
  // ========================================
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // ========================================
  // Title Styles
  // ========================================
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // ========================================
  // Body Styles
  // ========================================
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  // ========================================
  // Label Styles
  // ========================================
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // ========================================
  // Custom Styles (앱 특화)
  // ========================================
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.25,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: Colors.grey,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
  );

  // ========================================
  // 특수 스타일
  // ========================================
  static const TextStyle errorText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.red,
  );

  static const TextStyle successText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.green,
  );

  static const TextStyle warningText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.orange,
  );

  static const TextStyle linkText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.blue,
    decoration: TextDecoration.underline,
  );
}

/// 레거시 스타일 (기존 코드 호환)
@Deprecated('Use AppTextStyles instead')
class OptimizedStyles {
  OptimizedStyles._();

  static const TextStyle titleStyle = AppTextStyles.titleLarge;
  static const TextStyle subtitleStyle = AppTextStyles.caption;
  static const TextStyle bodyStyle = AppTextStyles.bodyLarge;
}

/// 텍스트 스타일 확장 메서드
extension TextStyleExtensions on TextStyle {
  /// 색상만 변경
  TextStyle withColor(Color color) => copyWith(color: color);

  /// 크기만 변경
  TextStyle withSize(double size) => copyWith(fontSize: size);

  /// 굵기만 변경
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);

  /// 밑줄 추가
  TextStyle withUnderline() => copyWith(decoration: TextDecoration.underline);

  /// 취소선 추가
  TextStyle withLineThrough() =>
      copyWith(decoration: TextDecoration.lineThrough);

  /// 투명도 적용
  TextStyle withOpacity(double opacity) => copyWith(
        color: color?.withValues(alpha: opacity),
      );
}
