import 'package:vms_app/core/security/secure_api_manager.dart';
import 'package:vms_app/core/utils/app_logger.dart';

class AppInitializer {
  static Future<void> initializeSecurity() async {
    try {
      AppLogger.i('Initializing security...');
      
      final secureManager = SecureApiManager();
      
      if (!(await secureManager.hasKey('login_api'))) {
        await secureManager.initializeSecureEndpoints();
        AppLogger.d('Secure endpoints initialized');
      }
      
      AppLogger.i('Security initialization complete');
    } catch (e) {
      AppLogger.e('Security initialization failed', e);
    }
  }
}
