// lib/presentation/widgets/widgets.dart

/// VMS App 위젯 라이브러리
///
/// 앱에서 사용되는 모든 커스텀 위젯들을 포함합니다.
///
/// 사용 예시:
/// ```dart
/// import 'package:vms_app/presentation/widgets/widgets.dart';
/// ```
library vms_widgets;

// Base Widgets - 기본 UI 컴포넌트
export 'base/base.dart';

// Common Widgets - 공통 기능 컴포넌트
export 'common/feedback/snackbar_utils.dart';
export 'common/dialogs/dialog_utils.dart';  // ✅ 추가
export 'common/loading/loading_widget.dart';
export 'common/loading/loading_container.dart';
export 'common/app_bar/custom_app_bar.dart';

// Feature Widgets - 기능별 특수 위젯
export 'features/map/map_widget.dart';
export 'features/map/map_control_widget.dart';
export 'features/map/map_layer.dart';

export 'features/navigation/bottom_navigation_widget.dart';

export 'features/weather/weather_control_widget.dart';
export 'features/weather/weather_info_widget.dart';

export 'features/vessel/vessel_info_widget.dart';

export 'features/button/warning_button.dart';

// Overlay Widgets - 오버레이 컴포넌트
export 'overlay/flash_overlay.dart';
export 'overlay/popup_dialog.dart';