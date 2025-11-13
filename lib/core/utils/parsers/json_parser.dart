// lib/core/utils/parsers/json_parser.dart

import 'package:vms_app/core/utils/logging/app_logger.dart';

/// JSON 파서 유틸리티
class JsonParser {
  JsonParser._();

  /// String 파싱
  static String? parseString(dynamic value, [String? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// String 파싱 (Non-null)
  static String parseStringNonNull(dynamic value, [String defaultValue = '']) {
    return parseString(value, defaultValue) ?? defaultValue;
  }

  /// int 파싱
  static int? parseInt(dynamic value, [int? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return defaultValue;
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// int 파싱 (Non-null)
  static int parseIntNonNull(dynamic value, [int defaultValue = 0]) {
    return parseInt(value, defaultValue) ?? defaultValue;
  }

  /// double 파싱
  static double? parseDouble(dynamic value, [double? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return defaultValue;
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// double 파싱 (Non-null)
  static double parseDoubleNonNull(dynamic value, [double defaultValue = 0.0]) {
    return parseDouble(value, defaultValue) ?? defaultValue;
  }

  /// bool 파싱
  static bool? parseBool(dynamic value, [bool? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return defaultValue;
  }

  /// bool 파싱 (Non-null)
  static bool parseBoolNonNull(dynamic value, [bool defaultValue = false]) {
    return parseBool(value, defaultValue) ?? defaultValue;
  }

  /// List 파싱
  static List<T>? parseList<T>(
    dynamic value,
    T Function(dynamic) parser, [
    List<T>? defaultValue,
  ]) {
    if (value == null) return defaultValue;
    if (value is! List) return defaultValue;

    try {
      return value.map(parser).toList();
    } catch (e) {
      AppLogger.e('Failed to parse list: $e');
      return defaultValue;
    }
  }

  /// List 파싱 (Non-null)
  static List<T> parseListNonNull<T>(
    dynamic value,
    T Function(dynamic) parser, [
    List<T>? defaultValue,
  ]) {
    return parseList(value, parser, defaultValue) ?? defaultValue ?? [];
  }

  /// Map 파싱
  static Map<String, dynamic>? parseMap(dynamic value,
      [Map<String, dynamic>? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        AppLogger.e('Failed to parse map: $e');
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// Map 파싱 (Non-null)
  static Map<String, dynamic> parseMapNonNull(dynamic value,
      [Map<String, dynamic>? defaultValue]) {
    return parseMap(value, defaultValue) ?? defaultValue ?? {};
  }

  /// DateTime 파싱
  static DateTime? parseDateTime(dynamic value, [DateTime? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        AppLogger.e('Failed to parse DateTime: $e');
        return defaultValue;
      }
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return defaultValue;
  }

  /// DateTime 파싱 (Non-null)
  static DateTime parseDateTimeNonNull(dynamic value,
      [DateTime? defaultValue]) {
    return parseDateTime(value, defaultValue) ?? defaultValue ?? DateTime.now();
  }
}
