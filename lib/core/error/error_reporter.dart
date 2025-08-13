// lib/core/error/error_reporter.dart
import 'package:flutter/material.dart';
import 'exceptions.dart';
import 'error_handler.dart';
import 'error_logger.dart';

/// 스낵바 타입 열거형
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

    // 에러 로깅 (async 함수이므로 await 없이 호출)
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

  /// 에러를 사용자에게 표시 (async 버전)
  /// [context] - BuildContext
  /// [error] - 발생한 에러
  /// [showSnackBar] - 스낵바 표시 여부 (기본값: true)
  /// [onRetry] - 재시도 콜백 (선택사항)
  static Future<void> reportErrorAsync(
      BuildContext context,
      dynamic error, {
        bool showSnackBar = true,
        VoidCallback? onRetry,
      }) async {
    final appException = ErrorHandler.handleError(error);
    final message = ErrorHandler.getUserFriendlyMessage(appException);

    // 에러 로깅 (async/await 사용)
    await ErrorLogger.logError(
      appException,
      context: {
        'screen': ModalRoute.of(context)?.settings.name ?? 'unknown',
        'error_type': appException.runtimeType.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (showSnackBar) {
      _showErrorSnackBar(context, message, appException, onRetry);
    }
  }

  /// AppException 전용 에러 리포팅
  /// [context] - BuildContext
  /// [exception] - AppException 인스턴스
  /// [showSnackBar] - 스낵바 표시 여부 (기본값: true)
  /// [onRetry] - 재시도 콜백 (선택사항)
  static Future<void> reportAppException(
      BuildContext context,
      AppException exception, {
        bool showSnackBar = true,
        VoidCallback? onRetry,
      }) async {
    final message = ErrorHandler.getUserFriendlyMessage(exception);

    // AppException 전용 로깅
    await ErrorLogger.logAppException(
      exception,
      context: {
        'screen': ModalRoute.of(context)?.settings.name ?? 'unknown',
        'user_action': 'error_occurred',
      },
    );

    if (showSnackBar && exception.isUserFriendly) {
      _showErrorSnackBar(context, message, exception, onRetry);
    }
  }

  /// 에러 스낵바 표시
  static void _showErrorSnackBar(
      BuildContext context,
      String message,
      AppException exception,
      VoidCallback? onRetry,
      ) {
    SnackBarType type = _getSnackBarTypeFromException(exception);
    _showBasicSnackBar(context, message, type, onRetry, exception);
  }

  /// 예외 타입에 따른 스낵바 타입 결정
  static SnackBarType _getSnackBarTypeFromException(AppException exception) {
    if (exception is NetworkException || exception is TimeoutException) {
      return SnackBarType.warning;
    } else if (exception is ValidationException) {
      return SnackBarType.info;
    } else if (exception is AuthException || exception is PermissionException) {
      return SnackBarType.error;
    } else if (exception.severity == ErrorSeverity.critical) {
      return SnackBarType.error;
    } else if (exception.severity == ErrorSeverity.high) {
      return SnackBarType.warning;
    } else {
      return SnackBarType.info;
    }
  }

  /// 기본 스낵바 표시
  static void _showBasicSnackBar(
      BuildContext context,
      String message,
      SnackBarType type,
      VoidCallback? onRetry,
      AppException? exception,
      ) {
    final colorScheme = _getSnackBarColors(type);
    final showRetryButton = onRetry != null && (exception?.isRetryable ?? false);

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(colorScheme['icon'] as IconData, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (exception != null && exception.code != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error Code: ${exception.code}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showRetryButton) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry!();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '다시 시도',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: colorScheme['backgroundColor'] as Color,
      duration: _getSnackBarDuration(type, exception),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 6,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// 스낵바 색상 및 아이콘 설정
  static Map<String, dynamic> _getSnackBarColors(SnackBarType type) {
    switch (type) {
      case SnackBarType.error:
        return {
          'backgroundColor': const Color(0xFFD32F2F),
          'icon': Icons.error_outline,
        };
      case SnackBarType.warning:
        return {
          'backgroundColor': const Color(0xFFFF9800),
          'icon': Icons.warning_amber_outlined,
        };
      case SnackBarType.info:
        return {
          'backgroundColor': const Color(0xFF1976D2),
          'icon': Icons.info_outline,
        };
      case SnackBarType.success:
        return {
          'backgroundColor': const Color(0xFF388E3C),
          'icon': Icons.check_circle_outline,
        };
    }
  }

  /// 스낵바 표시 시간 결정
  static Duration _getSnackBarDuration(SnackBarType type, AppException? exception) {
    if (exception?.severity == ErrorSeverity.critical) {
      return const Duration(seconds: 8); // 치명적 에러는 오래 표시
    } else if (type == SnackBarType.error) {
      return const Duration(seconds: 6);
    } else if (type == SnackBarType.warning) {
      return const Duration(seconds: 4);
    } else {
      return const Duration(seconds: 3);
    }
  }

  /// 에러 다이얼로그 표시 (개선된 버전)
  /// [context] - BuildContext
  /// [error] - 발생한 에러
  /// [title] - 다이얼로그 제목 (선택사항)
  /// [onRetry] - 재시도 콜백 (선택사항)
  /// [onCancel] - 취소 콜백 (선택사항)
  static Future<void> showErrorDialog(
      BuildContext context,
      dynamic error, {
        String? title,
        VoidCallback? onRetry,
        VoidCallback? onCancel,
      }) async {
    final appException = ErrorHandler.handleError(error);
    final message = ErrorHandler.getUserFriendlyMessage(appException);

    // 에러 로깅
    await ErrorLogger.logAppException(
      appException,
      context: {
        'display_type': 'dialog',
        'screen': ModalRoute.of(context)?.settings.name ?? 'unknown',
      },
    );

    final showRetryButton = onRetry != null && appException.isRetryable;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: _getErrorColor(appException),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title ?? _getErrorTitle(appException),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              if (appException.code != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Error Code: ${appException.code}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (onCancel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onCancel();
                },
                child: const Text('취소'),
              ),
            if (showRetryButton)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onRetry!();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('확인'),
              ),
          ],
        );
      },
    );
  }

  /// 에러 타입에 따른 색상 결정
  static Color _getErrorColor(AppException exception) {
    switch (exception.severity) {
      case ErrorSeverity.critical:
        return const Color(0xFFD32F2F);
      case ErrorSeverity.high:
        return const Color(0xFFFF5722);
      case ErrorSeverity.medium:
        return const Color(0xFFFF9800);
      case ErrorSeverity.low:
        return const Color(0xFF1976D2);
    }
  }

  /// 에러 타입에 따른 제목 결정
  static String _getErrorTitle(AppException exception) {
    if (exception is NetworkException) {
      return '네트워크 오류';
    } else if (exception is AuthException) {
      return '인증 오류';
    } else if (exception is ValidationException) {
      return '입력 오류';
    } else if (exception is PermissionException) {
      return '권한 오류';
    } else if (exception is ServerException) {
      return '서버 오류';
    } else {
      return '오류';
    }
  }

  /// 전체 화면 에러 위젯 (개선된 버전)
  /// [error] - 발생한 에러
  /// [onRetry] - 재시도 콜백 (선택사항)
  static Widget errorWidget(
      dynamic error, {
        VoidCallback? onRetry,
        String? customMessage,
      }) {
    final appException = ErrorHandler.handleError(error);
    final message = customMessage ?? ErrorHandler.getUserFriendlyMessage(appException);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getErrorColor(appException).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getErrorIcon(appException),
                size: 64,
                color: _getErrorColor(appException),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getErrorTitle(appException),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            if (appException.code != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Error: ${appException.code}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            if (onRetry != null && appException.isRetryable) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 에러 타입에 따른 아이콘 결정
  static IconData _getErrorIcon(AppException exception) {
    if (exception is NetworkException) {
      return Icons.wifi_off;
    } else if (exception is AuthException) {
      return Icons.lock_outline;
    } else if (exception is ValidationException) {
      return Icons.warning_amber_outlined;
    } else if (exception is PermissionException) {
      return Icons.block;
    } else if (exception is ServerException) {
      return Icons.cloud_off;
    } else {
      return Icons.error_outline;
    }
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
          title: const Text('에러 상세 정보 (디버그)'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDebugInfoRow('타입', appException.runtimeType.toString()),
                  _buildDebugInfoRow('메시지', appException.message),
                  if (appException.code != null)
                    _buildDebugInfoRow('코드', appException.code!),
                  _buildDebugInfoRow('심각도', appException.severity.name),
                  _buildDebugInfoRow('재시도 가능', appException.isRetryable.toString()),
                  _buildDebugInfoRow('사용자 친화적', appException.isUserFriendly.toString()),
                  if (stackTrace != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Stack Trace:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stackTrace.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // 클립보드에 복사 기능 추가 가능
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('복사'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  /// 디버그 정보 행 위젯
  static Widget _buildDebugInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// 성공 메시지 표시
  static void showSuccess(
      BuildContext context,
      String message, {
        Duration? duration,
      }) {
    _showBasicSnackBar(
      context,
      message,
      SnackBarType.success,
      null,
      null,
    );
  }

  /// 정보 메시지 표시
  static void showInfo(
      BuildContext context,
      String message, {
        Duration? duration,
      }) {
    _showBasicSnackBar(
      context,
      message,
      SnackBarType.info,
      null,
      null,
    );
  }

  /// 경고 메시지 표시
  static void showWarning(
      BuildContext context,
      String message, {
        Duration? duration,
      }) {
    _showBasicSnackBar(
      context,
      message,
      SnackBarType.warning,
      null,
      null,
    );
  }
}