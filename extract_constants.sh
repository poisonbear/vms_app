#!/bin/bash

echo "🔧 하드코딩된 값들을 상수로 추출하는 작업 시작..."
echo "================================"

# 1. 디렉토리 구조 생성
echo "📂 [1/6] 디렉토리 구조 생성..."
mkdir -p lib/core/constants

# 2. 디자인 시스템 상수 파일 생성
echo "📝 [2/6] 디자인 시스템 상수 생성..."
cat > lib/core/constants/design_constants.dart << 'EOF'
/// 디자인 시스템 관련 상수
class DesignConstants {
  DesignConstants._();

  // ============ Font Sizes ============
  static const double fontSizeXXS = 10.0;
  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeTitle = 30.0;

  // ============ Spacing (Padding/Margin) ============
  static const double spacing0 = 0.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing30 = 30.0;
  static const double spacing37 = 37.0;
  static const double spacing50 = 50.0;
  static const double spacing65 = 65.0;

  // ============ Border Radius ============
  static const double radiusXS = 4.0;
  static const double radiusS = 6.0;
  static const double radiusM = 10.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusCircle = 999.0;

  // ============ Icon Sizes ============
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 40.0;
  static const double iconSizeXXL = 60.0;
  static const double iconSizeMap = 64.0;

  // ============ Button Sizes ============
  static const double buttonHeightS = 32.0;
  static const double buttonHeightM = 40.0;
  static const double buttonHeightL = 48.0;
  static const double buttonHeightXL = 56.0;

  // ============ Line Heights ============
  static const double lineThickness0_5 = 0.5;
  static const double lineThickness1 = 1.0;
  static const double lineThickness2 = 2.0;

  // ============ Opacity Values ============
  static const double opacity10 = 0.1;
  static const double opacity30 = 0.3;
  static const double opacity50 = 0.5;
  static const double opacity70 = 0.7;
  static const double opacity90 = 0.9;
}
EOF

# 3. 애니메이션 상수 파일 생성
echo "📝 [3/6] 애니메이션 상수 생성..."
cat > lib/core/constants/animation_constants.dart << 'EOF'
/// 애니메이션 관련 상수
class AnimationConstants {
  AnimationConstants._();

  // ============ Duration ============
  static const Duration durationInstant = Duration(milliseconds: 100);
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationQuick = Duration(milliseconds: 300);
  static const Duration durationNormal = Duration(milliseconds: 500);
  static const Duration durationSlow = Duration(milliseconds: 700);
  static const Duration durationVerySlow = Duration(milliseconds: 1000);
  
  // 특수 용도
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration autoScrollDelay = Duration(seconds: 2);
  static const Duration weatherUpdateInterval = Duration(seconds: 30);
  static const Duration notificationDuration = Duration(seconds: 3);

  // ============ Curves ============
  static const String curveDefault = 'easeInOut';
  static const String curveLinear = 'linear';
  static const String curveEaseIn = 'easeIn';
  static const String curveEaseOut = 'easeOut';
  static const String curveBounce = 'bounceIn';
}
EOF

# 4. 맵 관련 상수 파일 생성
echo "📝 [4/6] 지도 상수 생성..."
cat > lib/core/constants/map_constants.dart << 'EOF'
/// 지도 관련 상수
class MapConstants {
  MapConstants._();

  // ============ Zoom Levels ============
  static const double zoomMin = 5.0;
  static const double zoomDefault = 13.0;
  static const double zoomMax = 18.0;
  static const double zoomCity = 10.0;
  static const double zoomStreet = 15.0;
  static const double zoomDetail = 17.0;

  // ============ Map Boundaries (대한민국) ============
  static const double latitudeMin = 33.0;
  static const double latitudeMax = 38.9;
  static const double longitudeMin = 124.5;
  static const double longitudeMax = 132.0;

  // ============ Default Locations ============
  static const double defaultLatitude = 36.5;  // 대한민국 중심
  static const double defaultLongitude = 127.5;
  
  // ============ Update Intervals ============
  static const int vesselUpdateSeconds = 2;
  static const int locationUpdateSeconds = 5;
  
  // ============ Marker Sizes ============
  static const double markerSizeSmall = 20.0;
  static const double markerSizeMedium = 30.0;
  static const double markerSizeLarge = 40.0;
}
EOF

# 5. 네트워크/API 상수 통합
echo "📝 [5/6] 네트워크 상수 통합..."
cat > lib/core/constants/network_constants.dart << 'EOF'
/// 네트워크 및 API 관련 상수
class NetworkConstants {
  NetworkConstants._();

  // ============ Timeouts (밀리초) ============
  static const int connectTimeoutMs = 30000;  // 30초
  static const int receiveTimeoutMs = 100000; // 100초
  static const int sendTimeoutMs = 30000;     // 30초

  // ============ Retry ============
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // ============ API Response Codes ============
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusServerError = 500;
  
  // ============ Pagination ============
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int initialPage = 1;
}
EOF

# 6. 데이터 포맷 상수 생성
echo "📝 [6/6] 데이터 포맷 상수 생성..."
cat > lib/core/constants/format_constants.dart << 'EOF'
/// 데이터 포맷 관련 상수
class FormatConstants {
  FormatConstants._();

  // ============ Date/Time Formats ============
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateFormatKr = 'yyyy년 MM월 dd일';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String dateTimeFormatKr = 'yyyy년 MM월 dd일 HH시 mm분';
  static const String timeFormat = 'HH:mm:ss';
  static const String timeFormatShort = 'HH:mm';
  static const String monthDayFormat = 'MM.dd';
  static const String yearMonthFormat = 'yyyy.MM';
  static const String dayOfWeekFormat = 'EEEE';

  // ============ Number Formats ============
  static const int decimalPlaces1 = 1;
  static const int decimalPlaces2 = 2;
  static const int coordinateDecimalPlaces = 6;
  
  // ============ Validation Patterns ============
  static const String mmsiPattern = r'^\d{9}$';
  static const String phonePattern = r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$';
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  // ============ Input Lengths ============
  static const int mmsiLength = 9;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 20;
  static const int maxShipNameLength = 50;
  static const int maxUserNameLength = 30;
}
EOF

# 7. barrel export 파일 생성
echo "📝 Barrel export 파일 생성..."
cat > lib/core/constants/constants.dart << 'EOF'
/// 모든 상수 파일 export
export 'animation_constants.dart';
export 'app_colors.dart';
export 'app_messages.dart';
export 'app_sizes.dart';
export 'design_constants.dart';
export 'format_constants.dart';
export 'map_constants.dart';
export 'network_constants.dart';
EOF

echo ""
echo "✅ 상수 추출 작업 완료!"
echo ""
echo "📊 생성된 상수 파일들:"
echo "  • design_constants.dart - 디자인 시스템 (폰트, 간격, 아이콘 크기 등)"
echo "  • animation_constants.dart - 애니메이션 (Duration, Curve)"
echo "  • map_constants.dart - 지도 관련 (줌 레벨, 기본 좌표 등)"
echo "  • network_constants.dart - 네트워크/API (타임아웃, 재시도 등)"
echo "  • format_constants.dart - 데이터 포맷 (날짜, 숫자, 검증 패턴)"
echo "  • constants.dart - 모든 상수 export"
echo ""
echo "🔧 다음 단계:"
echo "1. 프로젝트 전체에서 하드코딩된 값들을 상수로 교체"
echo "   예) fontSize: 16 → fontSize: DesignConstants.fontSizeM"
echo "   예) Duration(seconds: 30) → NetworkConstants.connectTimeoutMs"
echo "   예) EdgeInsets.all(20) → EdgeInsets.all(DesignConstants.spacing20)"
echo ""
echo "2. 사용 예시:"
echo "   import 'package:vms_app/core/constants/constants.dart';"
echo ""
echo "3. 검증:"
echo "   flutter analyze"
