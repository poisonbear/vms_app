// lib/core/error/error_reporter.dart
import 'package:flutter/material.dart';
import 'exceptions.dart';
import 'error_handler.dart';
import 'error_logger.dart';
import '../../kdn/cmm_widget/common_widgets.dart';

/// 스낵바 타입 열거형 (CommonWidgets에서 사용)
enum SnackBarType { info, warning, error, success }

/// 사용자에게 에러를 표시하는 리포터 클래스
class ErrorReporter {
  ErrorReporter._();

  /// 에러를 사용자에게 표시
  /// [context] - BuildContext
  /// [error] - 발생한 에러
  /// [showSnackBar] - 스낵바 표시 여부 (기본값: true)
  /// [onRetry] - 재시도 콜백 (선택사항)
  static void reportError(
      BuildContext context,
      dynamic error, {
        bool showSnackBar = true,
        VoidCallback? onRetry,
      }) {
    final appException = ErrorHandler.handleError(error);
    final message = ErrorHandler.getUserFriendlyMessage(appException);

    // 에러 로깅
    ErrorLogger.logError(
      appException,
      context: {
        'screen': ModalRoute.of(context)?.settings.name ?? 'unknown',
        'error_type': appException.runtimeType.toString(),
      },
    );

    if (showSnackBar) {
      _showErrorSnackBar(context, message, appException, onRetry);
    }
  }

  /// 에러 스낵바 표시
  static void _showErrorSnackBar(
      BuildContext context,
      String message,
      AppException exception,
      VoidCallback? onRetry,
      ) {
    SnackBarType type = SnackBarType.error;

    // 예외 타입에 따른 스낵바 타입 결정
    if (exception is NetworkException) {
      type = SnackBarType.warning;
    } else if (exception is ValidationException) {
      type = SnackBarType.info;
    }

    // CommonWidgets가 없는 경우를 대비한 기본 스낵바
    _showBasicSnackBar(context, message, type, onRetry);
  }

  /// 기본 스낵바 표시 (CommonWidgets 의존성 제거)
  static void _showBasicSnackBar(
      BuildContext context,
      String message,
      SnackBarType type,
      VoidCallback? onRetry,
      ) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackBarType.error:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case SnackBarType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
      case SnackBarType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onRetry();
              },
              child: const Text(
                '다시 시도',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// 에러 다이얼로그 표시
  /// [context] - BuildContext
  /// [error] - 발생한 에러
  /// [title] - 다이얼로그 제목 (선택사항)
  /// [onRetry] - 재시도 콜백 (선택사항)
  /// [onCancel] - 취소 콜백 (선택사항)
  static void showErrorDialog(
      BuildContext context,
      dynamic error, {
        String? title,
        VoidCallback? onRetry,
        VoidCallback? onCancel,
      }) {
    final appException = ErrorHandler.handleError(error);
    final message = ErrorHandler.getUserFriendlyMessage(appException);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? '오류'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            if (onCancel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel();
                },
                child: const Text('취소'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onRetry != null) {
                  onRetry();
                }
              },
              child: Text(onRetry != null ? '다시 시도' : '확인'),
            ),
          ],
        );
      },
    );
  }

  /// 전체 화면 에러 위젯
  /// [error] - 발생한 에러
  /// [onRetry] - 재시도 콜백 (선택사항)
  static Widget errorWidget(
      dynamic error, {
        VoidCallback? onRetry,
      }) {
    final appException = ErrorHandler.handleError(error);
    final message = ErrorHandler.getUserFriendlyMessage(appException);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              '오류가 발생했습니다',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 에러 상세 정보 표시 (디버그용)
  static void showErrorDetails(
      BuildContext context,
      dynamic error, {
        StackTrace? stackTrace,
      }) {
    final appException = ErrorHandler.handleError(error);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('에러 상세 정보'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '타입: ${appException.runtimeType}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('메시지: ${appException.message}'),
                if (appException.code != null) ...[
                  const SizedBox(height: 8),
                  Text('코드: ${appException.code}'),
                ],
                if (stackTrace != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Stack Trace:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stackTrace.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}