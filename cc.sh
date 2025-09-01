#!/bin/bash

echo "=== AppLogger 및 관련 오류 수정 시작 ==="

# 1. AppLogger 파일 수정 (developer.log 파라미터 문제 해결)
echo "[1/4] AppLogger 파일 수정 중..."
cat > lib/core/utils/app_logger.dart << 'EOF'
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
EOF

# 2. memory_leak_checker.dart 수정
echo "[2/4] memory_leak_checker.dart 수정 중..."
if [ -f "lib/core/utils/memory_leak_checker.dart" ]; then
  cat > lib/core/utils/memory_leak_checker.dart << 'EOF'
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 메모리 누수 체크 유틸리티
class MemoryLeakChecker {
  static final Map<String, int> _instanceCounts = {};
  static Timer? _periodicChecker;
  
  /// 인스턴스 추적 시작
  static void trackInstance(String className) {
    if (kReleaseMode) return;
    
    _instanceCounts[className] = (_instanceCounts[className] ?? 0) + 1;
    AppLogger.v('Instance created: $className (count: ${_instanceCounts[className]})');
  }
  
  /// 인스턴스 해제 추적
  static void releaseInstance(String className) {
    if (kReleaseMode) return;
    
    if (_instanceCounts.containsKey(className)) {
      _instanceCounts[className] = (_instanceCounts[className]! - 1);
      if (_instanceCounts[className]! <= 0) {
        _instanceCounts.remove(className);
      }
      AppLogger.v('Instance released: $className (remaining: ${_instanceCounts[className] ?? 0})');
    }
  }
  
  /// 주기적 메모리 체크 시작
  static void startPeriodicCheck({Duration interval = const Duration(minutes: 1)}) {
    if (kReleaseMode) return;
    
    _periodicChecker?.cancel();
    _periodicChecker = Timer.periodic(interval, (_) {
      printMemoryReport();
    });
    
    AppLogger.i('Memory leak checker started');
  }
  
  /// 메모리 체크 중지
  static void stopPeriodicCheck() {
    _periodicChecker?.cancel();
    _periodicChecker = null;
    AppLogger.i('Memory leak checker stopped');
  }
  
  /// 메모리 리포트 출력
  static void printMemoryReport() {
    if (kReleaseMode) return;
    
    if (_instanceCounts.isEmpty) {
      AppLogger.d('No tracked instances');
      return;
    }
    
    final report = StringBuffer();
    report.writeln('=== Memory Report ===');
    _instanceCounts.forEach((className, count) {
      if (count > 0) {
        report.writeln('$className: $count instances');
      }
    });
    report.writeln('====================');
    
    // Flutter 환경에서 안전하게 출력
    if (kDebugMode) {
      debugPrint(report.toString());
    } else {
      AppLogger.d(report.toString());
    }
  }
  
  /// 특정 클래스의 인스턴스 수 가져오기
  static int getInstanceCount(String className) {
    return _instanceCounts[className] ?? 0;
  }
  
  /// 모든 추적 정보 초기화
  static void reset() {
    _instanceCounts.clear();
    _periodicChecker?.cancel();
    _periodicChecker = null;
    AppLogger.d('Memory leak checker reset');
  }
}
EOF
fi

# 3. register_screen.dart의 stackTrace 파라미터 오류 수정
echo "[3/4] register_screen.dart 오류 수정 중..."
if [ -f "lib/presentation/screens/auth/register_screen.dart" ]; then
  # stackTrace 파라미터 제거 (developer.log는 stackTrace를 파라미터로 받지 않음)
  sed -i 's/, stackTrace: [^)]*)/)/g' lib/presentation/screens/auth/register_screen.dart
  
  # AppLogger.e 호출 수정
  sed -i 's/AppLogger\.e(\([^,]*\), \([^,]*\), stackTrace: \([^)]*\))/AppLogger.e(\1, \2, \3)/g' lib/presentation/screens/auth/register_screen.dart
fi

# 4. 필요한 import 추가 스크립트
echo "[4/4] 필요한 파일에 import 추가 중..."

# memory_leak_checker.dart에 필요한 import가 있는지 확인
FILES_NEEDING_APPLOGGER=(
  "lib/core/utils/permission_manager.dart"
  "lib/core/utils/load_location.dart"
  "lib/core/utils/optimize_images.dart"
  "lib/core/constants/api_endpoints.dart"
)

for file in "${FILES_NEEDING_APPLOGGER[@]}"; do
  if [ -f "$file" ]; then
    # AppLogger import가 없으면 추가
    if ! grep -q "import 'package:vms_app/core/utils/app_logger.dart';" "$file"; then
      echo "Adding AppLogger import to $file"
      sed -i "1i import 'package:vms_app/core/utils/app_logger.dart';" "$file"
    fi
  fi
done

echo ""
echo "=== ✅ 오류 수정 완료 ==="
echo ""
echo "수정된 내용:"
echo "1. AppLogger의 developer.log 파라미터 문제 해결"
echo "2. memory_leak_checker.dart의 print 함수를 debugPrint로 변경"
echo "3. register_screen.dart의 stackTrace 파라미터 오류 수정"
echo "4. 필요한 파일들에 AppLogger import 추가"
echo ""
echo "다음 명령 실행:"
echo "flutter clean"
echo "flutter pub get"
echo "flutter run"
EOF
