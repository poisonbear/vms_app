// lib/core/utils/logging/app_logger.dart

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 앱 로거 유틸리티 (민감 정보 보호 강화)
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.debug : Level.warning, // 프로덕션에서는 warning 이상만
  );

  // 민감 정보 키워드 (소문자로 통일)
  static const List<String> _sensitiveKeywords = [
    'password',
    'pwd',
    'token',
    'jwt',
    'bearer',
    'authorization',
    'secret',
    'key',
    'credential',
    'auth',
  ];

  AppLogger._();

  /// Debug 로그 (민감 정보 필터링)
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!kDebugMode) return; // 프로덕션에서는 출력 안함

    final filteredMessage = _filterSensitiveData(message);
    _logger.d(filteredMessage, error: error, stackTrace: stackTrace);
  }

  /// Info 로그 (민감 정보 필터링)
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    final filteredMessage = _filterSensitiveData(message);
    _logger.i(filteredMessage, error: error, stackTrace: stackTrace);
  }

  /// Warning 로그
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error 로그
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal 로그
  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Verbose 로그 (민감 정보 필터링)
  static void v(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!kDebugMode) return; // 프로덕션에서는 출력 안함

    final filteredMessage = _filterSensitiveData(message);
    _logger.t(filteredMessage, error: error, stackTrace: stackTrace);
  }

  // ============================================
  // 민감 정보 필터링
  // ============================================

  /// 민감한 정보를 마스킹 처리
  static String _filterSensitiveData(String message) {
    //수정: 프로덕션/개발 모드 모두 동일하게 특정 패턴만 마스킹
    String filtered = message;

    // 1. JWT 토큰 마스킹 (Bearer eyJ...)
    filtered = filtered.replaceAllMapped(
      RegExp(r'Bearer\s+([a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+)',
          caseSensitive: false),
      (match) => 'Bearer [MASKED_JWT]',
    );

    // 2. API 키/토큰 마스킹 (AIza..., ya29..., 등)
    filtered = filtered.replaceAllMapped(
      RegExp(r'(AIza|ya29|AKIA|sk-)[a-zA-Z0-9_-]{20,}', caseSensitive: false),
      (match) => '[MASKED_API_KEY]',
    );

    // 3. Password 값 마스킹
    filtered = filtered.replaceAllMapped(
      RegExp(r'(password|pwd)\s*[:=]\s*[^\s,}]+', caseSensitive: false),
      (match) => '${match.group(1)}: [MASKED]',
    );

    // 4. Authorization 헤더 마스킹
    filtered = filtered.replaceAllMapped(
      RegExp(r'Authorization\s*[:=]\s*[^\s,}]+', caseSensitive: false),
      (match) => 'Authorization: [MASKED]',
    );

    // 5. Token 값 마스킹
    filtered = filtered.replaceAllMapped(
      RegExp(r'(token|fcm_tkn)\s*[:=]\s*[^\s,}]+', caseSensitive: false),
      (match) => '${match.group(1)}: [MASKED]',
    );

    return filtered;
  }

  /// 민감 정보가 포함되어 있는지 확인
  static bool containsSensitiveData(String message) {
    final lowerMessage = message.toLowerCase();
    return _sensitiveKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// 프로덕션 환경 여부 확인
  static bool get isProduction => kReleaseMode;

  /// 디버그 환경 여부 확인
  static bool get isDebug => kDebugMode;
}
