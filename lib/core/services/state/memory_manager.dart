// lib/core/services/state/memory_manager.dart

import 'package:flutter/material.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 메모리 관리자
///
/// Disposable 리소스를 중앙에서 관리하고 자동으로 정리합니다.
class MemoryManager {
  final List<VoidCallback> _disposables = [];
  final Map<String, dynamic> _resources = {};

  /// Disposable 콜백 등록
  void register(VoidCallback disposable) {
    _disposables.add(disposable);
  }

  /// 리소스 추가
  void addResource(String key, dynamic resource) {
    _resources[key] = resource;
  }

  /// 리소스 가져오기
  T? getResource<T>(String key) {
    return _resources[key] as T?;
  }

  /// 리소스 제거
  void removeResource(String key) {
    _resources.remove(key);
  }

  /// 모든 리소스 정리
  void disposeAll() {
    for (final disposable in _disposables) {
      try {
        disposable();
      } catch (e) {
        AppLogger.e('Error disposing resource: $e');
      }
    }
    _disposables.clear();
    _resources.clear();
    AppLogger.d('All resources disposed');
  }

  /// 리소스만 클리어 (Disposable은 유지)
  void clear() {
    _resources.clear();
  }

  /// 통계 정보
  Map<String, dynamic> getStatistics() {
    return {
      'disposables': _disposables.length,
      'resources': _resources.keys.toList(),
      'resourceCount': _resources.length,
    };
  }

  /// 디버그 정보 출력
  void printDebugInfo() {
    final stats = getStatistics();
    AppLogger.d('MemoryManager Status:');
    AppLogger.d('  - Disposables: ${stats['disposables']}');
    AppLogger.d('  - Resources: ${stats['resourceCount']}');
    AppLogger.d('  - Resource keys: ${stats['resources']}');
  }
}
