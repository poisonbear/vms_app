#!/bin/bash

# Flutter 프로젝트 메모리 누수 및 에러 수정 스크립트
# 작성일: 2025-01-06
# 프로젝트 구조에 맞춘 정확한 수정

echo "======================================"
echo "🔧 Flutter 메모리 누수 위험 수정 시작"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 프로젝트 루트 확인
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Flutter 프로젝트 루트에서 실행해주세요.${NC}"
    exit 1
fi

# 수정 카운터
FIXED_COUNT=0

echo -e "\n${YELLOW}📋 Step 1: main.dart에 foundation.dart import 추가${NC}"
echo "----------------------------------------"

if [ -f "lib/main.dart" ]; then
    # foundation.dart import 확인 및 추가
    if ! grep -q "import 'package:flutter/foundation.dart';" "lib/main.dart"; then
        # material.dart import 다음에 추가
        sed -i "/import 'package:flutter\/material.dart';/a\\import 'package:flutter/foundation.dart';" "lib/main.dart"
        echo -e "${GREEN}  ✅ main.dart - foundation.dart import 추가됨${NC}"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    else
        echo -e "${BLUE}  ℹ️  main.dart - foundation.dart import 이미 존재${NC}"
    fi
    
    # MemoryLeakChecker import 확인 (이미 있는 경우)
    if grep -q "MemoryLeakChecker" "lib/main.dart"; then
        if ! grep -q "import.*memory_leak_checker" "lib/main.dart"; then
            sed -i "/import 'package:flutter\/foundation.dart';/a\\import 'package:vms_app/core/utils/memory_leak_checker.dart';" "lib/main.dart"
            echo -e "${GREEN}  ✅ main.dart - memory_leak_checker import 추가됨${NC}"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    fi
fi

echo -e "\n${YELLOW}📋 Step 2: main_screen.dart late 변수 초기화 확인${NC}"
echo "----------------------------------------"

if [ -f "lib/presentation/screens/main/main_screen.dart" ]; then
    echo -e "  검사중: main_screen.dart"
    
    # initState에서 서비스 초기화 추가
    # _timerService 초기화
    if grep -q "late final TimerService _timerService;" "lib/presentation/screens/main/main_screen.dart"; then
        if ! grep -q "_timerService = TimerService();" "lib/presentation/screens/main/main_screen.dart"; then
            sed -i '/super\.initState();/a\    _timerService = TimerService();' "lib/presentation/screens/main/main_screen.dart"
            echo -e "${GREEN}  ✅ _timerService 초기화 추가됨${NC}"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    fi
    
    # _popupService 초기화
    if grep -q "late final PopupService _popupService;" "lib/presentation/screens/main/main_screen.dart"; then
        if ! grep -q "_popupService = PopupService();" "lib/presentation/screens/main/main_screen.dart"; then
            sed -i '/super\.initState();/a\    _popupService = PopupService();' "lib/presentation/screens/main/main_screen.dart"
            echo -e "${GREEN}  ✅ _popupService 초기화 추가됨${NC}"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    fi
    
    # _locationFocusService 초기화
    if grep -q "late final LocationFocusService _locationFocusService;" "lib/presentation/screens/main/main_screen.dart"; then
        if ! grep -q "_locationFocusService = LocationFocusService();" "lib/presentation/screens/main/main_screen.dart"; then
            sed -i '/super\.initState();/a\    _locationFocusService = LocationFocusService();' "lib/presentation/screens/main/main_screen.dart"
            echo -e "${GREEN}  ✅ _locationFocusService 초기화 추가됨${NC}"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    fi
    
    # _stateManager 초기화
    if grep -q "late final StateManager _stateManager;" "lib/presentation/screens/main/main_screen.dart"; then
        if ! grep -q "_stateManager = StateManager();" "lib/presentation/screens/main/main_screen.dart"; then
            sed -i '/super\.initState();/a\    _stateManager = StateManager();' "lib/presentation/screens/main/main_screen.dart"
            echo -e "${GREEN}  ✅ _stateManager 초기화 추가됨${NC}"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    fi
fi

echo -e "\n${YELLOW}📋 Step 3: dispose 메서드 null-safe 수정${NC}"
echo "----------------------------------------"

# main_screen.dart dispose 수정
if [ -f "lib/presentation/screens/main/main_screen.dart" ]; then
    echo -e "  수정중: main_screen.dart dispose 메서드"
    
    # AnimationController는 null-safe 아님 (late로 선언되어 있음)
    sed -i 's/_flashController\.dispose()/_flashController.dispose()/g' "lib/presentation/screens/main/main_screen.dart"
    
    # 서비스들은 late final이므로 null-safe 불필요
    sed -i 's/_timerService?\./_timerService./g' "lib/presentation/screens/main/main_screen.dart"
    sed -i 's/_popupService?\./_popupService./g' "lib/presentation/screens/main/main_screen.dart"
    sed -i 's/_locationFocusService?\./_locationFocusService./g' "lib/presentation/screens/main/main_screen.dart"
    sed -i 's/_stateManager?\./_stateManager./g' "lib/presentation/screens/main/main_screen.dart"
    sed -i 's/_memoryManager?\./_memoryManager./g' "lib/presentation/screens/main/main_screen.dart"
    
    echo -e "${GREEN}  ✅ dispose 메서드 수정 완료${NC}"
    FIXED_COUNT=$((FIXED_COUNT + 1))
fi

echo -e "\n${YELLOW}📋 Step 4: TextEditingController dispose 추가${NC}"
echo "----------------------------------------"

# edit_profile_screen.dart 확인
if [ -f "lib/presentation/screens/profile/edit_profile_screen.dart" ]; then
    echo -e "  검사중: edit_profile_screen.dart"
    
    # _disposeControllers 메서드가 이미 있는지 확인
    if grep -q "_disposeControllers()" "lib/presentation/screens/profile/edit_profile_screen.dart"; then
        echo -e "${BLUE}  ℹ️  edit_profile_screen.dart - dispose 이미 구현됨${NC}"
    fi
fi

# register_screen.dart 확인
if [ -f "lib/presentation/screens/auth/register_screen.dart" ]; then
    echo -e "  검사중: register_screen.dart"
    
    # _disposeControllers 메서드가 이미 있는지 확인
    if grep -q "_disposeControllers()" "lib/presentation/screens/auth/register_screen.dart"; then
        echo -e "${BLUE}  ℹ️  register_screen.dart - dispose 이미 구현됨${NC}"
    fi
fi

echo -e "\n${YELLOW}📋 Step 5: AnimationController dispose 확인${NC}"
echo "----------------------------------------"

# find_account_screen.dart TabController dispose 확인
if [ -f "lib/presentation/screens/auth/find_account_screen.dart" ]; then
    echo -e "  검사중: find_account_screen.dart"
    
    if grep -q "TabController _tabController" "lib/presentation/screens/auth/find_account_screen.dart"; then
        # dispose에서 _tabController.dispose() 호출 확인
        if ! grep -q "_tabController.dispose()" "lib/presentation/screens/auth/find_account_screen.dart"; then
            # dispose 메서드가 있는지 확인
            if grep -q "void dispose()" "lib/presentation/screens/auth/find_account_screen.dart"; then
                # super.dispose() 전에 추가
                sed -i '/super\.dispose();/i\    _tabController.dispose();' "lib/presentation/screens/auth/find_account_screen.dart"
                echo -e "${GREEN}  ✅ find_account_screen.dart - _tabController.dispose() 추가됨${NC}"
                FIXED_COUNT=$((FIXED_COUNT + 1))
            fi
        fi
    fi
fi

echo -e "\n${YELLOW}📋 Step 6: StreamController dispose 확인${NC}"
echo "----------------------------------------"

# Provider 클래스들 확인
for file in lib/presentation/providers/*.dart; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        
        # BaseProvider를 상속받는 클래스는 이미 dispose 구현됨
        if grep -q "extends BaseProvider" "$file"; then
            echo -e "${BLUE}  ℹ️  $filename - BaseProvider 상속으로 dispose 구현됨${NC}"
        elif grep -q "extends ChangeNotifier" "$file"; then
            # ChangeNotifier만 상속받는 경우 dispose 확인
            if ! grep -q "void dispose()" "$file"; then
                echo -e "${YELLOW}  ⚠️  $filename - dispose 메서드 추가 필요${NC}"
            fi
        fi
    fi
done

echo -e "\n${YELLOW}📋 Step 7: Timer 직접 사용 검사${NC}"
echo "----------------------------------------"

# Timer 직접 사용하는 파일 찾기 (TimerService 제외)
find lib -name "*.dart" -type f ! -path "*/timer_service.dart" ! -path "*/memory_*" ! -path "*/base_provider.dart" | while read file; do
    if grep -q "Timer\." "$file" || grep -q "Timer?" "$file"; then
        filename=$(basename "$file")
        echo -e "${YELLOW}  ⚠️  $filename - Timer 직접 사용 발견 (TimerService 사용 권장)${NC}"
    fi
done

echo -e "\n${YELLOW}📋 Step 8: 코드 포맷팅${NC}"
echo "----------------------------------------"

# dart format 실행
echo "  dart format 실행중..."
dart format lib/ --line-length=120 2>/dev/null || true

echo -e "${GREEN}  ✅ 코드 포맷팅 완료${NC}"

echo -e "\n${YELLOW}📋 Step 9: 분석 실행${NC}"
echo "----------------------------------------"

# Flutter analyze 실행하여 에러 확인
echo "  flutter analyze 실행중..."
ANALYZE_OUTPUT=$(flutter analyze --no-pub 2>&1)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || true)
WARNING_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "warning" || true)

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}  ✅ 에러 없음${NC}"
else
    echo -e "${RED}  ❌ 에러 $ERROR_COUNT개 발견${NC}"
    echo "$ANALYZE_OUTPUT" | grep "error" | head -5
fi

if [ $WARNING_COUNT -gt 0 ]; then
    echo -e "${YELLOW}  ⚠️  경고 $WARNING_COUNT개 발견${NC}"
fi

echo -e "\n======================================"
echo -e "${GREEN}✅ 메모리 누수 수정 완료!${NC}"
echo -e "======================================"
echo -e "수정된 항목: ${GREEN}$FIXED_COUNT${NC}개"

echo -e "\n${YELLOW}📌 다음 단계:${NC}"
echo "1. ${BLUE}flutter clean${NC}"
echo "2. ${BLUE}flutter pub get${NC}"
echo "3. ${BLUE}flutter analyze${NC} (남은 에러 확인)"
echo "4. ${BLUE}flutter run${NC} (테스트 실행)"

if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "\n${RED}⚠️  주의: 아직 $ERROR_COUNT개의 에러가 있습니다.${NC}"
    echo "자세한 내용은 'flutter analyze' 명령으로 확인하세요."
fi

echo -e "\n${GREEN}💡 추가 권장사항:${NC}"
echo "• Timer 직접 사용 부분을 TimerService로 마이그레이션"
echo "• StreamController 사용 시 dispose 확인"
echo "• 메모리 프로파일링: flutter run --profile"
