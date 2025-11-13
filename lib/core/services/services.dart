// lib/core/services/services.dart

/// Core Services 통합 Export 파일
///
/// 모든 core 서비스를 한 곳에서 import할 수 있습니다.
///
/// 사용 예시:
/// ```dart
/// import 'package:vms_app/core/services/services.dart';
///
/// final cache = CacheService();
/// final timer = TimerService();
/// ```
library core_services;

// ============================================
// Cache 서비스
// ============================================
export 'cache/persistent_cache.dart';
export 'cache/memory_cache.dart';

// ============================================
// Location 서비스
// ============================================
export 'location/location_service.dart';
export 'location/location_manager.dart';

// ============================================
// State 관리
// ============================================
export 'state/state_manager.dart';
export 'state/memory_manager.dart';

// ============================================
// System 서비스
// ============================================
export 'system/app_initializer.dart';
export 'system/timer_service.dart';

// ============================================
// Security
// ============================================
export 'security/secure_storage_service.dart';
