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
  
  // ============ Validation Patterns ============
  static const String mmsiPattern = r'^\d{9}$';
  static const String phonePattern = r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$';
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  // ============ Input Lengths ============
  static const int mmsiLength = 9;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 20;
  static const int maxShipNameLength = 50;
  static const int maxUserNameLength = 30;
}
