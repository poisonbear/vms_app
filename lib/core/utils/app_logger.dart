import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 앱 전체 로그 관리 클래스
class AppLogger {
  static const String _appName = 'VMS_APP';
  
  static const int _verbose = 0;
  static const int _debug = 1;
  static const int _info = 2;
  static const int _warning = 3;
  static const int _error = 4;
  
  static int get _currentLevel => kReleaseMode ? _error : _debug;
  
  /// Verbose 로그 (상세 정보)
  static void v(String message, [dynamic error]) {
    if (_currentLevel <= _verbose) {
      _log('VERBOSE', message, error);
    }
  }
  
  /// Debug 로그 (디버깅 정보)
  static void d(String message, [dynamic error]) {
    if (_currentLevel <= _debug) {
      _log('DEBUG', message, error);
    }
  }
  
  /// Info 로그 (일반 정보)
  static void i(String message, [dynamic error]) {
    if (_currentLevel <= _info) {
      _log('INFO', message, error);
    }
  }
  
  /// Warning 로그 (경고)
  static void w(String message, [dynamic error]) {
    if (_currentLevel <= _warning) {
      _log('WARNING', message, error);
    }
  }
  
  /// Error 로그 (오류) - stackTrace 파라미터 추가
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_currentLevel <= _error) {
      _log('ERROR', message, error);
      if (stackTrace != null && !kReleaseMode) {
        // StackTrace는 별도로 출력
        developer.log(
          'StackTrace:\n${stackTrace.toString()}',
          name: '$_appName:STACK'
        );
      }
    }
  }
  
  static void _log(String level, String message, [dynamic error]) {
    if (kReleaseMode && level != 'ERROR') {
      return; // 릴리즈 모드에서는 ERROR만 출력
    }
    
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] $message';
    
    // developer.log의 올바른 사용법
    if (error != null) {
      developer.log(
        logMessage,
        error: error,
        name: _appName
      );
    } else {
      developer.log(
        logMessage,
        name: _appName
      );
    }
  }
  
  /// API 호출 로그 (개발 모드에서만)
  static void api(String method, String url, [dynamic data]) {
    if (!kReleaseMode) {
      d('API [$method] $url${data != null ? ' - Data: $data' : ''}');
    }
  }
  
  /// 민감한 정보 마스킹
  static String maskSensitive(String value, {int visibleChars = 4}) {
    if (value.isEmpty) return '';
    if (value.length <= visibleChars) {
      return '*' * value.length;
    }
    final visible = value.substring(0, visibleChars);
    final masked = '*' * (value.length - visibleChars);
    return '$visible$masked';
  }
}
