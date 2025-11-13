import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 전역 상태 관리자 (메모리 관리 통합)
class StateManager {
  static StateManager? _instance;

  // 상태 저장소
  final Map<String, dynamic> _states = {};

  // 상태 변경 스트림
  final _stateController = StreamController<StateChange>.broadcast();

  // 메모리 모니터링
  Timer? _memoryMonitor;
  int _lastMemoryUsage = 0;

  StateManager._() {
    _startMemoryMonitoring();
  }

  factory StateManager() {
    _instance ??= StateManager._();
    return _instance!;
  }

  // ============================================
  // 상태 관리
  // ============================================

  /// 상태 설정
  void setState<T>(String key, T value) {
    final oldValue = _states[key];
    _states[key] = value;

    _stateController.add(StateChange(
      key: key,
      oldValue: oldValue,
      newValue: value,
    ));

    AppLogger.d('State updated: $key');
  }

  /// 상태 가져오기
  T? getState<T>(String key) {
    return _states[key] as T?;
  }

  /// 상태 존재 확인
  bool hasState(String key) {
    return _states.containsKey(key);
  }

  /// 상태 제거
  void removeState(String key) {
    if (_states.containsKey(key)) {
      final oldValue = _states[key];
      _states.remove(key);

      _stateController.add(StateChange(
        key: key,
        oldValue: oldValue,
        newValue: null,
        isRemoved: true,
      ));

      AppLogger.d('State removed: $key');
    }
  }

  /// 모든 상태 클리어
  void clearAllStates() {
    _states.clear();
    AppLogger.i('All states cleared');
  }

  /// 상태 변경 스트림
  Stream<StateChange> get stateChanges => _stateController.stream;

  /// 특정 키의 상태 변경 스트림
  Stream<T?> watchState<T>(String key) {
    return _stateController.stream
        .where((change) => change.key == key)
        .map((change) => change.newValue as T?);
  }

  // ============================================
  // 메모리 관리
  // ============================================

  /// 메모리 모니터링 시작
  void _startMemoryMonitoring() {
    if (!kReleaseMode) {
      _memoryMonitor?.cancel();
      _memoryMonitor = Timer.periodic(const Duration(minutes: 1), (_) {
        _checkMemoryUsage();
      });
    }
  }

  /// 메모리 사용량 체크
  void _checkMemoryUsage() {
    try {
      // 상태 크기 계산
      int stateSize = 0;
      _states.forEach((key, value) {
        stateSize += key.length;
        if (value is String) {
          stateSize += value.length;
        } else if (value is List) {
          stateSize += value.length * 8;
        } else if (value is Map) {
          stateSize += value.length * 16;
        }
      });

      final currentMemory = stateSize ~/ 1024; // KB 단위

      if (currentMemory > _lastMemoryUsage + 100) {
        // 100KB 이상 증가 시
        AppLogger.w('Memory usage increased: ${currentMemory}KB');

        if (currentMemory > 5000) {
          // 5MB 초과 시
          _performMemoryCleanup();
        }
      }

      _lastMemoryUsage = currentMemory;
    } catch (e) {
      AppLogger.e('Memory monitoring error: $e');
    }
  }

  /// 메모리 정리
  void _performMemoryCleanup() {
    AppLogger.w('Performing memory cleanup...');

    // 큰 상태들 제거
    final keysToRemove = <String>[];

    _states.forEach((key, value) {
      if (!_isEssentialState(key)) {
        if (value is List && value.length > 100) {
          keysToRemove.add(key);
        } else if (value is Map && value.length > 100) {
          keysToRemove.add(key);
        }
      }
    });

    for (final key in keysToRemove) {
      removeState(key);
    }

    if (keysToRemove.isNotEmpty) {
      AppLogger.i('Cleaned up ${keysToRemove.length} large states');
    }
  }

  /// 필수 상태 확인
  bool _isEssentialState(String key) {
    const essentialKeys = [
      'user_info',
      'auth_token',
      'current_location',
      'vessel_list',
    ];
    return essentialKeys.contains(key);
  }

  // ============================================
  // 유틸리티
  // ============================================

  /// 상태 통계
  Map<String, dynamic> getStatistics() {
    return {
      'totalStates': _states.length,
      'memoryUsageKB': _lastMemoryUsage,
      'states': _states.keys.toList(),
    };
  }

  /// 리소스 정리
  void dispose() {
    _memoryMonitor?.cancel();
    _stateController.close();
    _states.clear();
  }
}

/// 상태 변경 이벤트
class StateChange {
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  final bool isRemoved;

  StateChange({
    required this.key,
    this.oldValue,
    this.newValue,
    this.isRemoved = false,
  });
}
