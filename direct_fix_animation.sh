#!/bin/bash

echo "🔧 AnimationConstants 직접 수정..."
echo "================================"
echo ""

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ========== 각 파일을 직접 수정 ==========

# 1. permission_manager.dart
echo -e "${YELLOW}[1/8]${NC} permission_manager.dart 수정..."
if [ -f "lib/core/utils/permission_manager.dart" ]; then
    # 백업
    cp lib/core/utils/permission_manager.dart lib/core/utils/permission_manager.dart.bak
    
    # 전체 파일에서 패턴 교체
    perl -i -pe 's/Future\.delayed\(AnimationConstants\s+autoScrollDelay/Future.delayed(AnimationConstants.autoScrollDelay/g' lib/core/utils/permission_manager.dart
    perl -i -pe 's/Timer\(AnimationConstants\s+autoScrollDelay/Timer(AnimationConstants.autoScrollDelay/g' lib/core/utils/permission_manager.dart
    
    echo "✓ 완료"
fi

# 2. main.dart
echo -e "${YELLOW}[2/8]${NC} main.dart 수정..."
if [ -f "lib/main.dart" ]; then
    perl -i -pe 's/Future\.delayed\(AnimationConstants\s+splashDuration/Future.delayed(AnimationConstants.splashDuration/g' lib/main.dart
    perl -i -pe 's/const AnimationConstants\s+splashDuration/const Duration(seconds: 3)/g' lib/main.dart
    echo "✓ 완료"
fi

# 3. login_screen.dart
echo -e "${YELLOW}[3/8]${NC} login_screen.dart 수정..."
if [ -f "lib/presentation/screens/auth/login_screen.dart" ]; then
    perl -i -pe 's/Duration\(AnimationConstants\s+durationInstant/Duration(milliseconds: 100/g' lib/presentation/screens/auth/login_screen.dart
    perl -i -pe 's/Timer\(AnimationConstants\s+durationInstant/Timer(AnimationConstants.durationInstant/g' lib/presentation/screens/auth/login_screen.dart
    echo "✓ 완료"
fi

# 4. main_screen.dart
echo -e "${YELLOW}[4/8]${NC} main_screen.dart 수정..."
if [ -f "lib/presentation/screens/main/main_screen.dart" ]; then
    perl -i -pe 's/Timer\.periodic\(AnimationConstants\s+autoScrollDelay/Timer.periodic(AnimationConstants.autoScrollDelay/g' lib/presentation/screens/main/main_screen.dart
    perl -i -pe 's/duration:\s*AnimationConstants\s+durationNormal/duration: AnimationConstants.durationNormal/g' lib/presentation/screens/main/main_screen.dart
    perl -i -pe 's/Future\.delayed\(AnimationConstants\s+durationVerySlow/Future.delayed(AnimationConstants.durationVerySlow/g' lib/presentation/screens/main/main_screen.dart
    perl -i -pe 's/Timer\.periodic\(AnimationConstants\s+weatherUpdateInterval/Timer.periodic(AnimationConstants.weatherUpdateInterval/g' lib/presentation/screens/main/main_screen.dart
    perl -i -pe 's/AnimationConstants\s+durationQuick/AnimationConstants.durationQuick/g' lib/presentation/screens/main/main_screen.dart
    echo "✓ 완료"
fi

# 5. navigation_calendar.dart
echo -e "${YELLOW}[5/8]${NC} navigation_calendar.dart 수정..."
if [ -f "lib/presentation/screens/main/tabs/navigation_calendar.dart" ]; then
    perl -i -pe 's/AnimationConstants\s+durationInstant/AnimationConstants.durationInstant/g' lib/presentation/screens/main/tabs/navigation_calendar.dart
    echo "✓ 완료"
fi

# 6. profile_screen.dart
echo -e "${YELLOW}[6/8]${NC} profile_screen.dart 수정..."
if [ -f "lib/presentation/screens/profile/profile_screen.dart" ]; then
    perl -i -pe 's/Duration\(AnimationConstants\s+durationQuick/Duration(milliseconds: 300/g' lib/presentation/screens/profile/profile_screen.dart
    perl -i -pe 's/AnimationConstants\s+durationQuick/AnimationConstants.durationQuick/g' lib/presentation/screens/profile/profile_screen.dart
    perl -i -pe 's/AnimationConstants\s+durationFast/AnimationConstants.durationFast/g' lib/presentation/screens/profile/profile_screen.dart
    echo "✓ 완료"
fi

# 7. edit_profile_screen.dart
echo -e "${YELLOW}[7/8]${NC} edit_profile_screen.dart 수정..."
if [ -f "lib/presentation/screens/profile/edit_profile_screen.dart" ]; then
    perl -i -pe 's/AnimationConstants\s+durationInstant/AnimationConstants.durationInstant/g' lib/presentation/screens/profile/edit_profile_screen.dart
    echo "✓ 완료"
fi

# 8. common_widgets.dart
echo -e "${YELLOW}[8/8]${NC} common_widgets.dart 수정..."
if [ -f "lib/presentation/widgets/common/common_widgets.dart" ]; then
    perl -i -pe 's/Future\.delayed\(AnimationConstants\s+splashDuration/Future.delayed(AnimationConstants.splashDuration/g' lib/presentation/widgets/common/common_widgets.dart
    perl -i -pe 's/AnimationConstants\s+notificationDuration/AnimationConstants.notificationDuration/g' lib/presentation/widgets/common/common_widgets.dart
    echo "✓ 완료"
fi

echo ""

# ========== weather_tab.dart 특별 처리 ==========
echo "🔨 weather_tab.dart 특별 처리..."
if [ -f "lib/presentation/screens/main/tabs/weather_tab.dart" ]; then
    # 237번 라인 근처의 문제 수정
    # Padding 내부의 잘못된 구조 수정
    perl -i -pe 's/DesignConstants\.spacing10\s*\.toDouble\(\)/DesignConstants.spacing10/g' lib/presentation/screens/main/tabs/weather_tab.dart
    perl -i -pe 's/padding:\s*EdgeInsets\.only\(.*?DesignConstants\.spacing10\)/padding: EdgeInsets.only(top: DesignConstants.spacing10, bottom: DesignConstants.spacing37, left: DesignConstants.spacing8, right: DesignConstants.spacing8)/g' lib/presentation/screens/main/tabs/weather_tab.dart
    echo "✓ 완료"
fi

echo ""
echo "================================"
echo -e "${GREEN}✅ 직접 수정 완료!${NC}"
echo ""
echo "🔍 최종 검증 실행 중..."

# 에러 카운트
ERROR_COUNT=$(flutter analyze 2>&1 | grep -c "error" || true)

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo -e "${GREEN}✅ 모든 에러가 해결되었습니다!${NC}"
else
    echo -e "${YELLOW}⚠️ 아직 $ERROR_COUNT개의 에러가 있습니다.${NC}"
    echo ""
    echo "남은 에러 확인:"
    echo "  flutter analyze | grep error | head -10"
    echo ""
    echo "💡 남은 에러가 있다면 수동으로 확인해주세요:"
    echo "  1. AnimationConstants 뒤에 점(.)이 빠진 곳"
    echo "  2. Duration() 생성자 내부의 잘못된 문법"
    echo "  3. import 누락"
fi

echo ""
echo "📁 백업 파일이 .bak 확장자로 생성되었습니다."
echo "  복원: cp lib/core/utils/permission_manager.dart.bak lib/core/utils/permission_manager.dart"
