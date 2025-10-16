// lib/core/utils/common/function_utils.dart

import 'dart:async';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 함수형 유틸리티
class FunctionUtils {
  FunctionUtils._();

  /// 디바운스 함수
  static Function debounce(Function func, Duration delay) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, () => func());
    };
  }

  /// 스로틀 함수
  static Function throttle(Function func, Duration delay) {
    bool isThrottled = false;
    return () {
      if (!isThrottled) {
        func();
        isThrottled = true;
        Timer(delay, () => isThrottled = false);
      }
    };
  }

  /// 안전한 Future 실행
  static Future<T?> safeFuture<T>(Future<T> Function() function) async {
    try {
      return await function();
    } catch (e) {
      AppLogger.e('Safe future execution failed: $e');
      return null;
    }
  }

  /// 재시도 로직
  static Future<T?> retry<T>({
    required Future<T> Function() function,
    int retries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        return await function();
      } catch (e) {
        if (i == retries - 1) rethrow;
        await Future.delayed(delay * (i + 1));
      }
    }
    return null;
  }
}

/// 헬퍼 클래스 (기존 코드 호환성)
class Helpers {
  Helpers._();

  static Function debounce(Function func, Duration delay) {
    return FunctionUtils.debounce(func, delay);
  }

  static Function throttle(Function func, Duration delay) {
    return FunctionUtils.throttle(func, delay);
  }

  static Future<T?> safeFuture<T>(Future<T> Function() function) async {
    return await FunctionUtils.safeFuture(function);
  }

  static Future<T?> retry<T>({
    required Future<T> Function() function,
    int retries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    return await FunctionUtils.retry(
      function: function,
      retries: retries,
      delay: delay,
    );
  }
}
