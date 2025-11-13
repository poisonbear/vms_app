import 'package:flutter/material.dart';

/// 상단 스낵바 표시 함수
void showTopSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
  Color? backgroundColor,
  Color? textColor,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black87,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon ?? Icons.info_outline,
                color: textColor ?? Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // 지정된 시간 후 자동 제거
  Future.delayed(duration, () {
    overlayEntry.remove();
  });
}

/// 하단 스낵바 표시 (기본 Material 스낵바 래퍼)
void showBottomSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
  Color? backgroundColor,
  Color? textColor,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor),
      ),
      duration: duration,
      action: action,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

/// 성공 메시지 전용 스낵바
void showSuccessSnackBar(BuildContext context, String message) {
  showTopSnackBar(
    context,
    message,
    icon: Icons.check_circle_outline,
    backgroundColor: Colors.green.shade700,
  );
}

/// 에러 메시지 전용 스낵바
void showErrorSnackBar(BuildContext context, String message) {
  showTopSnackBar(
    context,
    message,
    icon: Icons.error_outline,
    backgroundColor: Colors.red.shade700,
  );
}

/// 경고 메시지 전용 스낵바
void showWarningSnackBar(BuildContext context, String message) {
  showTopSnackBar(
    context,
    message,
    icon: Icons.warning_amber_rounded,
    backgroundColor: Colors.orange.shade700,
  );
}

/// 정보 메시지 전용 스낵바
void showInfoSnackBar(BuildContext context, String message) {
  showTopSnackBar(
    context,
    message,
    icon: Icons.info_outline,
    backgroundColor: Colors.blue.shade700,
  );
}

/// 커스텀 스낵바 클래스
class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    bool showAtTop = true,
  }) {
    switch (type) {
      case SnackBarType.success:
        showSuccessSnackBar(context, message);
      case SnackBarType.error:
        showErrorSnackBar(context, message);
      case SnackBarType.warning:
        showWarningSnackBar(context, message);
      case SnackBarType.info:
        showInfoSnackBar(context, message);
    }
  }
}

/// 스낵바 타입 enum
enum SnackBarType {
  success,
  error,
  warning,
  info,
}
