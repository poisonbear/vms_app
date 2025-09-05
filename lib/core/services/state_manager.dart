import 'package:flutter/foundation.dart';

/// 전역 상태 관리 서비스
class StateManager extends ChangeNotifier {
  // 상태 저장소
  final Map<String, dynamic> _state = {};
  final Map<String, List<VoidCallback>> _listeners = {};

  /// 상태 설정
  void setState<T>(String key, T value) {
    if (_state[key] != value) {
      _state[key] = value;
      _notifyKeyListeners(key);
      notifyListeners();
    }
  }

  /// 상태 가져오기
  T? getState<T>(String key) {
    return _state[key] as T?;
  }

  /// 특정 키에 대한 리스너 등록
  void addKeyListener(String key, VoidCallback listener) {
    _listeners[key] ??= [];
    _listeners[key]!.add(listener);
  }

  /// 특정 키에 대한 리스너 제거
  void removeKeyListener(String key, VoidCallback listener) {
    _listeners[key]?.remove(listener);
  }

  /// 특정 키의 리스너들에게 알림
  void _notifyKeyListeners(String key) {
    _listeners[key]?.forEach((listener) => listener());
  }

  /// 여러 상태를 한번에 업데이트
  void updateStates(Map<String, dynamic> updates) {
    bool hasChanges = false;
    final changedKeys = <String>[];

    updates.forEach((key, value) {
      if (_state[key] != value) {
        _state[key] = value;
        changedKeys.add(key);
        hasChanges = true;
      }
    });

    if (hasChanges) {
      for (final key in changedKeys) {
        _notifyKeyListeners(key);
      }
      notifyListeners();
    }
  }

  /// 상태 초기화
  void clearState() {
    _state.clear();
    _listeners.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clearState();
    super.dispose();
  }
}

/// 상태 키 상수
class StateKeys {
  static const String currentPosition = 'current_position';
  static const String selectedVessel = 'selected_vessel';
  static const String isTracking = 'is_tracking';
  static const String isOtherVesselsVisible = 'is_other_vessels_visible';
  static const String isWaveSelected = 'is_wave_selected';
  static const String isVisibilitySelected = 'is_visibility_selected';
  static const String selectedTabIndex = 'selected_tab_index';
  static const String isFlashing = 'is_flashing';
  static const String fcmToken = 'fcm_token';
}
