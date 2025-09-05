import 'package:vms_app/core/constants/string_constants.dart';

/// 네트워크 관련 상수
class NetworkConstants {
  NetworkConstants._();

  // User-Agent
  static const String userAgent =
      '${StringConstants.appName}/${StringConstants.appVersion}';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'ngrok-skip-browser-warning': '100',
  };

  // Retry
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
