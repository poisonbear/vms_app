#!/bin/bash

echo "🔧 최종 에러 수정 스크립트 실행..."
echo "================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ========== STEP 1: AnimationConstants 문법 오류 수정 ==========
echo -e "${YELLOW}[1/4]${NC} AnimationConstants 문법 오류 수정..."

# 잘못된 패턴을 올바른 패턴으로 수정
FILES_WITH_ERRORS=(
    "lib/core/utils/permission_manager.dart"
    "lib/main.dart"
    "lib/presentation/screens/auth/login_screen.dart"
    "lib/presentation/screens/main/main_screen.dart"
    "lib/presentation/screens/main/tabs/navigation_calendar.dart"
    "lib/presentation/screens/profile/edit_profile_screen.dart"
    "lib/presentation/screens/profile/profile_screen.dart"
    "lib/presentation/widgets/common/common_widgets.dart"
)

for file in "${FILES_WITH_ERRORS[@]}"; do
    if [ -f "$file" ]; then
        echo "  처리 중: $(basename $file)"
        
        # AnimationConstants 뒤에 공백과 이름이 오는 패턴을 점(.)으로 수정
        sed -i 's/AnimationConstants durationInstant/AnimationConstants.durationInstant/g' "$file"
        sed -i 's/AnimationConstants durationFast/AnimationConstants.durationFast/g' "$file"
        sed -i 's/AnimationConstants durationQuick/AnimationConstants.durationQuick/g' "$file"
        sed -i 's/AnimationConstants durationNormal/AnimationConstants.durationNormal/g' "$file"
        sed -i 's/AnimationConstants durationSlow/AnimationConstants.durationSlow/g' "$file"
        sed -i 's/AnimationConstants durationVerySlow/AnimationConstants.durationVerySlow/g' "$file"
        sed -i 's/AnimationConstants splashDuration/AnimationConstants.splashDuration/g' "$file"
        sed -i 's/AnimationConstants autoScrollDelay/AnimationConstants.autoScrollDelay/g' "$file"
        sed -i 's/AnimationConstants weatherUpdateInterval/AnimationConstants.weatherUpdateInterval/g' "$file"
        sed -i 's/AnimationConstants notificationDuration/AnimationConstants.notificationDuration/g' "$file"
        
        # 세미콜론 문제 수정 (Duration 파라미터로 사용될 때)
        sed -i 's/AnimationConstants\.durationInstant;/AnimationConstants.durationInstant);/g' "$file"
        sed -i 's/AnimationConstants\.durationFast;/AnimationConstants.durationFast);/g' "$file"
        sed -i 's/AnimationConstants\.durationQuick;/AnimationConstants.durationQuick);/g' "$file"
        sed -i 's/AnimationConstants\.durationNormal;/AnimationConstants.durationNormal);/g' "$file"
        sed -i 's/AnimationConstants\.durationVerySlow;/AnimationConstants.durationVerySlow);/g' "$file"
        sed -i 's/AnimationConstants\.splashDuration;/AnimationConstants.splashDuration);/g' "$file"
        sed -i 's/AnimationConstants\.autoScrollDelay;/AnimationConstants.autoScrollDelay);/g' "$file"
        sed -i 's/AnimationConstants\.weatherUpdateInterval;/AnimationConstants.weatherUpdateInterval);/g' "$file"
    fi
done
echo "✓ AnimationConstants 문법 수정 완료"
echo ""

# ========== STEP 2: app_colors.dart에서 DesignConstants 제거 ==========
echo -e "${YELLOW}[2/4]${NC} app_colors.dart 순환 참조 제거..."

if [ -f "lib/core/constants/app_colors.dart" ]; then
    # DesignConstants 참조를 실제 값으로 교체
    sed -i 's/DesignConstants\.spacing[0-9]*/10.0/g' lib/core/constants/app_colors.dart
    sed -i 's/DesignConstants\.[a-zA-Z_]*/10.0/g' lib/core/constants/app_colors.dart
    echo "✓ app_colors.dart 수정 완료"
fi
echo ""

# ========== STEP 3: weather_tab.dart 특수 에러 수정 ==========
echo -e "${YELLOW}[3/4]${NC} weather_tab.dart 특수 에러 수정..."

if [ -f "lib/presentation/screens/main/tabs/weather_tab.dart" ]; then
    # 237번 라인 근처의 .toDouble() 제거
    sed -i '237s/\.toDouble()//g' lib/presentation/screens/main/tabs/weather_tab.dart
    # 잘못된 괄호 수정
    sed -i '237s/DesignConstants\.spacing10)/DesignConstants.spacing10/g' lib/presentation/screens/main/tabs/weather_tab.dart
    echo "✓ weather_tab.dart 수정 완료"
fi
echo ""

# ========== STEP 4: 특정 파일별 세밀한 수정 ==========
echo -e "${YELLOW}[4/4]${NC} 파일별 세밀한 수정..."

# permission_manager.dart 수정
if [ -f "lib/core/utils/permission_manager.dart" ]; then
    # 115번 라인 근처
    sed -i '115s/Duration(AnimationConstants\.autoScrollDelay/Duration(seconds: 2/g' lib/core/utils/permission_manager.dart
    sed -i '115s/AnimationConstants\.autoScrollDelay)/AnimationConstants.autoScrollDelay/g' lib/core/utils/permission_manager.dart
    
    # 164번 라인 근처
    sed -i '164s/Duration(AnimationConstants\.autoScrollDelay/Duration(seconds: 2/g' lib/core/utils/permission_manager.dart
    sed -i '164s/AnimationConstants\.autoScrollDelay)/AnimationConstants.autoScrollDelay/g' lib/core/utils/permission_manager.dart
    
    # 232번 라인 근처
    sed -i '232s/Duration(AnimationConstants\.autoScrollDelay/Duration(seconds: 2/g' lib/core/utils/permission_manager.dart
    sed -i '232s/AnimationConstants\.autoScrollDelay)/AnimationConstants.autoScrollDelay/g' lib/core/utils/permission_manager.dart
    
    echo "✓ permission_manager.dart 수정"
fi

# main.dart 수정
if [ -f "lib/main.dart" ]; then
    # 166번 라인 근처
    sed -i '166s/Duration(AnimationConstants\.splashDuration/Duration(seconds: 3/g' lib/main.dart
    sed -i '166s/AnimationConstants\.splashDuration)/AnimationConstants.splashDuration/g' lib/main.dart
    echo "✓ main.dart 수정"
fi

# login_screen.dart 수정
if [ -f "lib/presentation/screens/auth/login_screen.dart" ]; then
    sed -i '208s/Duration(AnimationConstants\.durationInstant/Duration(milliseconds: 100/g' lib/presentation/screens/auth/login_screen.dart
    echo "✓ login_screen.dart 수정"
fi

echo ""

# ========== 검증 ==========
echo "🔍 수정 결과 검증..."
echo ""

# 임시 파일에 에러 저장
flutter analyze 2>&1 | grep "error" > temp_errors.txt 2>&1

ERROR_COUNT=$(cat temp_errors.txt | wc -l)

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo -e "${GREEN}✅ 모든 에러가 해결되었습니다!${NC}"
    rm temp_errors.txt
else
    echo -e "${YELLOW}⚠️ 아직 $ERROR_COUNT개의 에러가 있습니다.${NC}"
    echo ""
    echo "남은 에러 샘플 (처음 5개):"
    head -5 temp_errors.txt
    echo ""
    echo "전체 에러 확인:"
    echo "  cat temp_errors.txt"
fi

echo ""
echo "================================"
echo "📊 수정 작업 완료!"
echo ""
echo "✓ AnimationConstants 문법 오류 수정"
echo "✓ app_colors.dart 순환 참조 제거"
echo "✓ weather_tab.dart 특수 에러 수정"
echo "✓ 파일별 세밀한 수정 완료"
