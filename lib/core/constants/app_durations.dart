/// 시간 관련 상수
class AppDurations {
  AppDurations._();

  // API 타임아웃
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiLongTimeout = Duration(seconds: 60);
  static const Duration apiShortTimeout = Duration(seconds: 10);
  
  // 애니메이션
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);
  
  // 디바운스
  static const Duration debounceSearch = Duration(milliseconds: 500);
  static const Duration debounceInput = Duration(milliseconds: 300);
  
  // 스낵바
  static const Duration snackbarShort = Duration(seconds: 2);
  static const Duration snackbarNormal = Duration(seconds: 3);
  static const Duration snackbarLong = Duration(seconds: 5);
}
