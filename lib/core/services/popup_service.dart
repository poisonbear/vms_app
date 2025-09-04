import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// FCM 알림 팝업 관리 서비스
class PopupService {
  final Map<String, bool> _activePopups = {};
  static final PopupService _instance = PopupService._internal();
  
  factory PopupService() => _instance;
  PopupService._internal();

  /// 팝업 활성 상태 확인
  bool isPopupActive(String type) => _activePopups[type] ?? false;
  
  /// 팝업 활성 상태 설정
  void setPopupActive(String type, bool active) {
    _activePopups[type] = active;
    AppLogger.d('Popup $type active: $active');
  }

  /// 알림 팝업 표시
  void showAlertPopup({
    required BuildContext context,
    required String title,
    required String message,
    required String type,
    required VoidCallback onClose,
    required VoidCallback onStopFlashing,
  }) {
    if (isPopupActive(type)) {
      AppLogger.d('Popup $type already active, skipping');
      return;
    }
    
    setPopupActive(type, true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _buildAlertContent(
            title: title,
            message: message,
            onClose: () {
              onStopFlashing();
              setPopupActive(type, false);
              Navigator.of(context).pop();
              onClose();
            },
          ),
        );
      },
    );
  }
  
  /// 알림 컨텐츠 빌드
  Widget _buildAlertContent({
    required String title,
    required String message,
    required VoidCallback onClose,
  }) {
    return Container(
      width: 310,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/kdn/home/img/red_triangle-exclamation.svg',
            width: 60,
            height: 60,
          ),
          const SizedBox(height: DesignConstants.spacing8),
          Text(
            title,
            style: const TextStyle(
              fontSize: DesignConstants.fontSizeXL,
              fontWeight: FontWeight.w600,
              color: Color(0xFFDF2B2E),
              height: 1.0,
              fontFamily: 'Pretendard Variable',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignConstants.spacing8),
          SizedBox(
            width: 300,
            child: Text(
              message,
              style: const TextStyle(
                fontSize: DesignConstants.fontSizeS,
                fontWeight: FontWeight.w600,
                color: Color(0xFF999999),
                height: 1.0,
                fontFamily: 'Pretendard Variable',
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 270,
            height: 48,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: DesignConstants.spacing10,
                  horizontal: DesignConstants.spacing10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignConstants.radiusS),
                  side: const BorderSide(color: Color(0xFF5CA1F6), width: 1),
                ),
                elevation: 0,
                minimumSize: const Size(270, 48),
              ),
              child: const Text(
                '알람 종료하기',
                style: TextStyle(
                  color: Color(0xFF5CA1F6),
                  fontSize: DesignConstants.fontSizeS,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 모든 팝업 상태 초기화
  void reset() {
    _activePopups.clear();
  }
}
