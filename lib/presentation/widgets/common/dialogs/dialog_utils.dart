// lib/presentation/widgets/common/dialogs/dialog_utils.dart

import 'package:flutter/material.dart';

/// 다이얼로그 유틸리티 클래스
///
/// 앱 전체에서 사용되는 공통 다이얼로그들을 제공합니다.
///
/// 사용 예시:
/// ```dart
/// DialogUtils.warning(context, '경고 메시지');
/// DialogUtils.warningDetail(context, title: '제목', message: '내용');
/// ```
class DialogUtils {
  DialogUtils._(); // 생성자 private

  /// 간단한 경고 팝업
  ///
  /// 제목 없이 메시지만 표시하는 기본 경고 다이얼로그입니다.
  static void warning(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('경고'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// 상세 경고 팝업
  ///
  /// 제목과 메시지를 별도로 표시하는 경고 다이얼로그입니다.
  /// 선택적으로 확인 콜백을 제공할 수 있습니다.
  static void warningDetail(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// 확인/취소 다이얼로그
  ///
  /// 사용자 확인이 필요한 경우 사용합니다.
  /// 확인 시 true, 취소 시 false를 반환합니다.
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '확인',
    String cancelText = '취소',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: confirmColor != null
                  ? TextButton.styleFrom(foregroundColor: confirmColor)
                  : null,
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  /// 삭제 확인 다이얼로그
  ///
  /// 삭제 작업 전에 사용자 확인을 받습니다.
  static Future<bool?> showDeleteConfirm(
    BuildContext context, {
    String title = '삭제 확인',
    String message = '정말 삭제하시겠습니까?',
  }) {
    return showConfirm(
      context,
      title: title,
      message: message,
      confirmText: '삭제',
      cancelText: '취소',
      confirmColor: Colors.red,
    );
  }

  /// 정보 다이얼로그
  ///
  /// 일반적인 정보 전달용 다이얼로그입니다.
  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClose?.call();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// 성공 다이얼로그
  ///
  /// 작업 성공을 알리는 다이얼로그입니다.
  static void showSuccess(
    BuildContext context, {
    String title = '성공',
    required String message,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClose?.call();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// 에러 다이얼로그
  ///
  /// 에러 발생을 알리는 다이얼로그입니다.
  static void showError(
    BuildContext context, {
    String title = '오류',
    required String message,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClose?.call();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// 로딩 다이얼로그 표시
  ///
  /// 작업 진행 중임을 표시합니다.
  /// hideLoading()으로 닫아야 합니다.
  static void showLoading(
    BuildContext context, {
    String message = '처리 중...',
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return PopScope(
          canPop: barrierDismissible,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 로딩 다이얼로그 닫기
  ///
  /// showLoading()으로 표시한 다이얼로그를 닫습니다.
  static void hideLoading(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// 커스텀 다이얼로그
  ///
  /// 자유로운 형태의 다이얼로그를 표시합니다.
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required Widget content,
    List<Widget>? actions,
    String? title,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title != null ? Text(title) : null,
          content: content,
          actions: actions,
        );
      },
    );
  }
}

// ============================================
// 하위 호환성을 위한 전역 함수
// ============================================

/// 간단한 경고 팝업 (하위 호환성)
///
/// **새로운 코드에서는 DialogUtils.warning() 사용을 권장합니다.**
void warningPop(BuildContext context, String message) {
  DialogUtils.warning(context, message);
}

/// 상세 경고 팝업 (하위 호환성)
///
/// **새로운 코드에서는 DialogUtils.warningDetail() 사용을 권장합니다.**
void warningPopdetail(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onConfirm,
}) {
  DialogUtils.warningDetail(
    context,
    title: title,
    message: message,
    onConfirm: onConfirm,
  );
}
