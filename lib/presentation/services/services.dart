// lib/presentation/services/services.dart

/// Presentation Services 통합 Export 파일
///
/// 모든 presentation 레이어 서비스를 한 곳에서 import할 수 있습니다.
///
/// 사용 예시:
/// ```dart
/// import 'package:vms_app/presentation/services/services.dart';
///
/// final popupService = PopupService();
/// final locationFocus = LocationFocusService();
/// ```
library presentation_services;

// ============================================
// UI 서비스
// ============================================
export 'ui/ui_services.dart';
