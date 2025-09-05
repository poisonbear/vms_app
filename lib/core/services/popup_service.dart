import 'package:flutter/foundation.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 팝업 상태 관리 서비스
class PopupService extends ChangeNotifier {
  // 팝업 타입 상수
  static const String TURBINE_ENTRY_ALERT = 'turbine_entry_alert';
  static const String WEATHER_ALERT = 'weather_alert';
  static const String SUBMARINE_CABLE_ALERT = 'submarine_cable_alert';
  static const String NAVIGATION_HISTORY = 'navigation_history';
  static const String VESSEL_INFO = 'vessel_info';

  // 활성 팝업 상태
  final Map<String, bool> _activePopups = {};
  final Map<String, dynamic> _popupData = {};

  // Getter
  Map<String, bool> get activePopups => Map.unmodifiable(_activePopups);
  bool isPopupActive(String popupId) => _activePopups[popupId] ?? false;
  dynamic getPopupData(String popupId) => _popupData[popupId];

  /// 팝업 표시
  void showPopup(String popupId, {dynamic data}) {
    _activePopups[popupId] = true;
    if (data != null) {
      _popupData[popupId] = data;
    }
    AppLogger.d('📋 Popup shown: $popupId');
    notifyListeners();
  }

  /// 팝업 숨기기
  void hidePopup(String popupId) {
    _activePopups[popupId] = false;
    _popupData.remove(popupId);
    AppLogger.d('📋 Popup hidden: $popupId');
    notifyListeners();
  }

  /// 모든 팝업 숨기기
  void hideAllPopups() {
    _activePopups.clear();
    _popupData.clear();
    AppLogger.d('📋 All popups hidden');
    notifyListeners();
  }

  /// 토글 팝업
  void togglePopup(String popupId, {dynamic data}) {
    if (isPopupActive(popupId)) {
      hidePopup(popupId);
    } else {
      showPopup(popupId, data: data);
    }
  }

  /// 단일 팝업만 표시
  void showExclusivePopup(String popupId, {dynamic data}) {
    hideAllPopups();
    showPopup(popupId, data: data);
  }
}
