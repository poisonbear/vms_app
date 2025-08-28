#!/bin/bash

echo "🔧 상수 교체 에러 수정 시작..."
echo "================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ========== STEP 1: animation_constants.dart 파일 수정 ==========
echo -e "${YELLOW}[1/5]${NC} animation_constants.dart 파일 수정..."
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
}
EOF
echo "✓ animation_constants.dart 수정 완료"
echo ""

# ========== STEP 2: 잘못된 Duration 교체 패턴 수정 ==========
echo -e "${YELLOW}[2/5]${NC} 잘못된 Duration 교체 패턴 수정..."

# AnimationConstants 잘못된 사용 수정
declare -A FIX_DURATION=(
    ["AnimationConstants.durationInstant;"]="AnimationConstants.durationInstant);"
    ["AnimationConstants.durationFast;"]="AnimationConstants.durationFast);"
    ["AnimationConstants.durationQuick;"]="AnimationConstants.durationQuick);"
    ["AnimationConstants.durationNormal;"]="AnimationConstants.durationNormal);"
    ["AnimationConstants.durationSlow;"]="AnimationConstants.durationSlow);"
    ["AnimationConstants.durationVerySlow;"]="AnimationConstants.durationVerySlow);"
    ["AnimationConstants.splashDuration;"]="AnimationConstants.splashDuration);"
    ["AnimationConstants.autoScrollDelay;"]="AnimationConstants.autoScrollDelay);"
    ["AnimationConstants.weatherUpdateInterval;"]="AnimationConstants.weatherUpdateInterval);"
    
    ["AnimationConstants durationInstant"]="AnimationConstants.durationInstant"
    ["AnimationConstants durationFast"]="AnimationConstants.durationFast"
    ["AnimationConstants durationQuick"]="AnimationConstants.durationQuick"
    ["AnimationConstants durationNormal"]="AnimationConstants.durationNormal"
    ["AnimationConstants durationVerySlow"]="AnimationConstants.durationVerySlow"
    ["AnimationConstants autoScrollDelay"]="AnimationConstants.autoScrollDelay"
    ["AnimationConstants weatherUpdateInterval"]="AnimationConstants.weatherUpdateInterval"
    ["AnimationConstants splashDuration"]="AnimationConstants.splashDuration"
    
    ["durationInstant;"]="AnimationConstants.durationInstant);"
    ["durationQuick;"]="AnimationConstants.durationQuick);"
    ["durationNormal;"]="AnimationConstants.durationNormal);"
    ["durationFast;"]="AnimationConstants.durationFast);"
    ["durationVerySlow;"]="AnimationConstants.durationVerySlow);"
    ["autoScrollDelay;"]="AnimationConstants.autoScrollDelay);"
    ["weatherUpdateInterval;"]="AnimationConstants.weatherUpdateInterval);"
    ["splashDuration;"]="AnimationConstants.splashDuration);"
)

for original in "${!FIX_DURATION[@]}"; do
    replacement="${FIX_DURATION[$original]}"
    find lib -name "*.dart" -type f -exec grep -l "$original" {} \; | while read file; do
        sed -i "s/$original/$replacement/g" "$file"
        echo "  ✓ 수정: $file"
    done
done
echo ""

# ========== STEP 3: network_constants.dart 수정 ==========
echo -e "${YELLOW}[3/5]${NC} network_constants.dart 파일 수정..."
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
echo "✓ network_constants.dart 수정 완료"
echo ""

# ========== STEP 4: app_constants.dart 및 app_config.dart 수정 ==========
echo -e "${YELLOW}[4/5]${NC} app_constants.dart 및 app_config.dart 수정..."

# app_constants.dart 수정
if [ -f "lib/core/constants/app_constants.dart" ]; then
    sed -i 's/static const Duration apiTimeout = AnimationConstants.*/static const Duration apiTimeout = Duration(seconds: 30);/g' lib/core/constants/app_constants.dart
    echo "✓ app_constants.dart 수정 완료"
fi

# app_config.dart 수정
if [ -f "lib/core/config/app_config.dart" ]; then
    sed -i 's/static const Duration retryDelay = AnimationConstants.*/static const Duration retryDelay = Duration(seconds: 2);/g' lib/core/config/app_config.dart
    echo "✓ app_config.dart 수정 완료"
fi
echo ""

# ========== STEP 5: 특수 케이스 수정 ==========
echo -e "${YELLOW}[5/5]${NC} 특수 케이스 수정..."

# weather_tab.dart의 잘못된 구문 수정
if [ -f "lib/presentation/screens/main/tabs/weather_tab.dart" ]; then
    # 236번 라인 근처의 에러 수정
    sed -i '236s/DesignConstants.spacing10.toDouble()/DesignConstants.spacing10/g' lib/presentation/screens/main/tabs/weather_tab.dart
    echo "✓ weather_tab.dart 수정 완료"
fi

# app_colors.dart의 DesignConstants 참조 제거 (순환 참조 방지)
if [ -f "lib/core/constants/app_colors.dart" ]; then
    sed -i 's/DesignConstants.spacing/10/g' lib/core/constants/app_colors.dart
    echo "✓ app_colors.dart 수정 완료"
fi

# dio_client.dart의 DesignConstants 참조 수정
if [ -f "lib/core/network/dio_client.dart" ]; then
    sed -i 's/DesignConstants.spacing10/10.0/g' lib/core/network/dio_client.dart
    echo "✓ dio_client.dart 수정 완료"
fi
echo ""

# ========== 검증 ==========
echo "🔍 수정 결과 검증 중..."
echo ""

# 에러 카운트
ERROR_COUNT=$(flutter analyze 2>/dev/null | grep -c "error" || true)

if [ "$ERROR_COUNT" -gt "0" ]; then
    echo -e "${YELLOW}⚠️ 아직 $ERROR_COUNT개의 에러가 남아있습니다.${NC}"
    echo "상세 내용은 다음 명령어로 확인하세요:"
    echo "  flutter analyze | grep error"
else
    echo -e "${GREEN}✅ 모든 에러가 수정되었습니다!${NC}"
fi

echo ""
echo "================================"
echo "📊 수정 완료 내역:"
echo "  • animation_constants.dart - Duration 타입 수정"
echo "  • network_constants.dart - Duration 타입 수정"
echo "  • 잘못된 Duration 패턴 교체"
echo "  • 순환 참조 제거"
echo "  • 특수 케이스 수정"
echo ""
echo "🔧 남은 에러가 있다면:"
echo "1. flutter analyze | grep error 로 확인"
echo "2. 수동으로 수정하거나"
echo "3. 백업에서 복원: cp backup_*/lib/path/to/file.dart lib/path/to/"
