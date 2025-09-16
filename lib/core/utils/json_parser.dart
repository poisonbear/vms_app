/// JSON 파싱을 위한 타입 안전 유틸리티
class JsonParser {
  /// 안전한 int 변환
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 안전한 double 변환
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 안전한 String 변환
  static String? parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// 안전한 bool 변환
  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is int) return value != 0;
    return null;
  }

  /// 안전한 DateTime 변환
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// 안전한 List 변환
  static List<T>? parseList<T>(dynamic value, T Function(dynamic) parser) {
    if (value == null) return null;
    if (value is! List) return null;
    return value.map(parser).where((item) => item != null).toList();
  }
}
