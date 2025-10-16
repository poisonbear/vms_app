import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vms_app/core/constants/constants.dart';

class MainScreenPopups {
  /// Context 유효성 검증 헬퍼
  static bool _isContextValid(BuildContext context) {
    try {
      return context.mounted;
    } catch (e) {
      return false;
    }
  }

  /// 터빈 진입 경고 팝업
  static void showTurbineWarningPopup(
    BuildContext context,
    String title,
    String message,
    VoidCallback onClose,
  ) {
    if (!_isContextValid(context)) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
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
                  const SizedBox(height: AppSizes.spacing8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: DesignConstants.fontSizeXL,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDF2B2E),
                      height: 1.0,
                      letterSpacing: 0,
                      fontFamily: 'Pretendard Variable',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacing8),
                  SizedBox(
                    width: 300,
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: DesignConstants.fontSizeXS,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF999999),
                        height: 1.0,
                        letterSpacing: 0,
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
                      onPressed: () {
                        if (_isContextValid(dialogContext)) {
                          onClose();
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.spacing10,
                          horizontal: AppSizes.spacing10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignConstants.radiusS),
                          side: const BorderSide(
                              color: Color(0xFF5CA1F6), width: 1),
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
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing turbine warning popup: $e');
    }
  }

  /// 기상 경고 팝업
  static void showWeatherWarningPopup(
    BuildContext context,
    String title,
    String message,
    VoidCallback onClose,
  ) {
    // 터빈 경고와 유사한 구조
    showTurbineWarningPopup(context, title, message, onClose);
  }

  /// 해저케이블 경고 팝업
  static void showSubmarineWarningPopup(
    BuildContext context,
    String title,
    String message,
    VoidCallback onClose,
  ) {
    // 터빈 경고와 유사한 구조
    showTurbineWarningPopup(context, title, message, onClose);
  }
}
