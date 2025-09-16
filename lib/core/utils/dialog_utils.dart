import 'package:flutter/material.dart';

/// 공통 다이얼로그 유틸리티 클래스
class DialogUtils {
  // 현재 표시 중인 다이얼로그 추적
  static bool _isDialogShowing = false;
  static bool _isLoadingShowing = false;

  /// Context 유효성 검증
  static bool _isContextValid(BuildContext context) {
    try {
      return context.mounted;
    } catch (e) {
      return false;
    }
  }

  /// 기본 확인 다이얼로그
  static Future<void> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '확인',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
    Color? titleColor,
  }) async {
    if (!_isContextValid(context)) return;

    try {
      await showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(
              title,
              style: TextStyle(
                color: titleColor ?? Theme.of(dialogContext).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(message),
            actions: [
              if (cancelText != null)
                TextButton(
                  onPressed: () {
                    if (_isContextValid(dialogContext)) {
                      Navigator.of(dialogContext).pop();
                      onCancel?.call();
                    }
                  },
                  child: Text(cancelText),
                ),
              ElevatedButton(
                onPressed: () {
                  if (_isContextValid(dialogContext)) {
                    Navigator.of(dialogContext).pop();
                    onConfirm?.call();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: titleColor ?? Theme.of(dialogContext).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing confirm dialog: $e');
    }
  }

  /// 권한 요청 다이얼로그
  static Future<void> showPermissionDialog({
    required BuildContext context,
    required String permissionType,
    required String message,
    required VoidCallback onOpenSettings,
    VoidCallback? onExit,
  }) async {
    if (!_isContextValid(context)) return;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text('$permissionType 권한 필요'),
              content: Text('$message\n권한을 허용하지 않으면 앱을 사용할 수 없습니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_isContextValid(dialogContext)) {
                      Navigator.of(dialogContext).pop();
                      onOpenSettings();
                    }
                  },
                  child: const Text('설정 열기'),
                ),
                if (onExit != null)
                  TextButton(
                    onPressed: () {
                      if (_isContextValid(dialogContext)) {
                        Navigator.of(dialogContext).pop();
                        onExit();
                      }
                    },
                    child: const Text('앱 종료'),
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing permission dialog: $e');
    }
  }

  /// 로딩 다이얼로그
  static void showLoadingDialog(BuildContext context, {String? message}) {
    if (!_isContextValid(context) || _isLoadingShowing) return;

    try {
      _isLoadingShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return PopScope(
            canPop: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(message),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ).then((_) {
        _isLoadingShowing = false;
      });
    } catch (e) {
      _isLoadingShowing = false;
      debugPrint('Error showing loading dialog: $e');
    }
  }

  /// 로딩 다이얼로그 닫기
  static void hideLoadingDialog(BuildContext context) {
    if (!_isContextValid(context) || !_isLoadingShowing) return;

    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        _isLoadingShowing = false;
      }
    } catch (e) {
      _isLoadingShowing = false;
      debugPrint('Error hiding loading dialog: $e');
    }
  }

  /// 에러 다이얼로그
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = '확인',
  }) async {
    if (!_isContextValid(context)) return;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (_isContextValid(dialogContext)) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing error dialog: $e');
    }
  }

  /// 성공 다이얼로그
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = '확인',
    VoidCallback? onConfirm,
  }) async {
    if (!_isContextValid(context)) return;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (_isContextValid(dialogContext)) {
                    Navigator.of(dialogContext).pop();
                    onConfirm?.call();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing success dialog: $e');
    }
  }

  /// 커스텀 경고 팝업 (warningPop 대체)
  static Future<void> showWarningPopup({
    required BuildContext context,
    required String title,
    required String detail,
    String? additionalInfo,
    Color titleColor = Colors.orange,
    Color shadowColor = Colors.black,
    String? iconPath,
  }) async {
    if (!_isContextValid(context) || _isDialogShowing) return;

    try {
      _isDialogShowing = true;
      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: '',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Stack(
            children: [
              // 배경
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: [
                        shadowColor.withOpacity(0.1),
                        shadowColor.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),
              // 팝업 내용
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (iconPath != null)
                          Image.asset(
                            iconPath,
                            width: 64,
                            height: 64,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.warning_amber_rounded,
                                size: 64,
                                color: Colors.orange,
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          detail,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        if (additionalInfo != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              additionalInfo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_isContextValid(context)) {
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: titleColor,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing warning popup: $e');
    } finally {
      _isDialogShowing = false;
    }
  }
}