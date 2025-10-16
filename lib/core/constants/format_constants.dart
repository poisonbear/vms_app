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
  static const String iso8601Format = "yyyy-MM-dd'T'HH:mm:ss'Z'";

  // ============ Number Formats ============
  static const int decimalPlaces1 = 1;
  static const int decimalPlaces2 = 2;
  static const int coordinateDecimalPlaces = 6;
  static const int percentageDecimalPlaces = 1;
  static const int currencyDecimalPlaces = 0;

  // ============ 입력 필드 최대 길이 ============
  static const int maxShipNameLength = 50;
  static const int maxUserNameLength = 30;
  static const int maxDescriptionLength = 500;
  static const int maxAddressLength = 200;
  static const int maxTitleLength = 100;

  // ============ 통화 포맷 ============
  static const String currencySymbol = '₩';
  static const String currencyFormat = '#,###';

  // ============ 파일 크기 포맷 ============
  static const String byteUnit = 'B';
  static const String kilobyteUnit = 'KB';
  static const String megabyteUnit = 'MB';
  static const String gigabyteUnit = 'GB';

  // ============ 좌표 포맷 ============
  static const String latitudePrefix = 'N';
  static const String latitudeSuffix = 'S';
  static const String longitudePrefix = 'E';
  static const String longitudeSuffix = 'W';
}
