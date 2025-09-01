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
