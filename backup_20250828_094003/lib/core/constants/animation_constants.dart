/// 애니메이션 관련 상수
class AnimationConstants {
  AnimationConstants._();

  // ============ Duration ============
  static const Duration durationInstant = Duration(milliseconds: 100);
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationQuick = Duration(milliseconds: 300);
  static const Duration durationNormal = Duration(milliseconds: 500);
  static const Duration durationSlow = Duration(milliseconds: 700);
  static const Duration durationVerySlow = Duration(milliseconds: 1000);
  
  // 특수 용도
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration autoScrollDelay = Duration(seconds: 2);
  static const Duration weatherUpdateInterval = Duration(seconds: 30);
  static const Duration notificationDuration = Duration(seconds: 3);

  // ============ Curves ============
  static const String curveDefault = 'easeInOut';
  static const String curveLinear = 'linear';
  static const String curveEaseIn = 'easeIn';
  static const String curveEaseOut = 'easeOut';
  static const String curveBounce = 'bounceIn';
}
