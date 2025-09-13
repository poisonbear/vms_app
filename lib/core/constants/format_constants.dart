/// 데이터 포맷 관련 상수
class FormatConstants {
  FormatConstants._();

  // ============ Date/Time Formats ============
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateFormatKr = 'yyyy년 MM월 dd일';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String dateTimeFormatKr = 'yyyy년 MM월 dd일 HH시 mm분';
  static const String timeFormat = 'HH:mm:ss';
  static const String timeFormatShort = 'HH:mm';
  static const String monthDayFormat = 'MM.dd';
  static const String yearMonthFormat = 'yyyy.MM';
  static const String dayOfWeekFormat = 'EEEE';

  // ============ Number Formats ============
  static const int decimalPlaces1 = 1;
  static const int decimalPlaces2 = 2;
  static const int coordinateDecimalPlaces = 6;

  // ============ Input Lengths (ValidationConstants로 이동됨) ============
  // static const int mmsiLength = 9; // → ValidationConstants.mmsiLength
  // static const int minPasswordLength = 8; // → ValidationConstants.passwordMinLength
  // static const int maxPasswordLength = 20; // → ValidationConstants.passwordMaxLength
  static const int maxShipNameLength = 50;
  static const int maxUserNameLength = 30;

  // 참고: 정규식 패턴들은 ValidationPatterns 클래스로 이동되었습니다.
}
