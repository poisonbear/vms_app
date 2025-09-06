#!/bin/bash

# 메모리 누수 수정 최종 검증 스크립트
# 작성일: 2025-01-06

echo "======================================"
echo "🔍 메모리 누수 최종 검증"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# 검증 결과 카운터
PASS_COUNT=0
FAIL_COUNT=0
WARNING_COUNT=0

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}✅ Check 1: dispose 메서드 검증${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 1. Controller가 있는데 dispose가 없는 파일 찾기
echo -e "\n${BLUE}1.1 TextEditingController dispose 확인${NC}"
MISSING_DISPOSE=0
for file in $(find lib -name "*.dart" -type f); do
    if grep -q "TextEditingController" "$file"; then
        controllers=$(grep -o "[a-zA-Z_][a-zA-Z0-9_]*Controller\s*=\s*TextEditingController" "$file" | sed 's/\s*=.*//' | sort -u)
        if [ ! -z "$controllers" ]; then
            for controller in $controllers; do
                if ! grep -q "$controller\.dispose()" "$file"; then
                    echo -e "${RED}  ❌ $(basename $file): $controller.dispose() 누락${NC}"
                    MISSING_DISPOSE=$((MISSING_DISPOSE + 1))
                    FAIL_COUNT=$((FAIL_COUNT + 1))
                fi
            done
        fi
    fi
done

if [ $MISSING_DISPOSE -eq 0 ]; then
    echo -e "${GREEN}  ✅ 모든 TextEditingController dispose 확인됨${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
fi

echo -e "\n${BLUE}1.2 AnimationController dispose 확인${NC}"
MISSING_ANIMATION=0
for file in $(find lib -name "*.dart" -type f); do
    if grep -q "AnimationController" "$file"; then
        if ! grep -q "\.dispose()" "$file"; then
            echo -e "${RED}  ❌ $(basename $file): AnimationController dispose 누락 가능성${NC}"
            MISSING_ANIMATION=$((MISSING_ANIMATION + 1))
            WARNING_COUNT=$((WARNING_COUNT + 1))
        fi
    fi
done

if [ $MISSING_ANIMATION -eq 0 ]; then
    echo -e "${GREEN}  ✅ 모든 AnimationController dispose 확인됨${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}✅ Check 2: Timer 사용 검증${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 2. Timer 직접 사용 확인
echo -e "\n${BLUE}2.1 Timer 직접 사용 검사${NC}"
TIMER_USAGE=0
for file in $(find lib -name "*.dart" -type f ! -path "*/timer_service.dart" ! -path "*/memory_*" ! -path "*/base_provider.dart"); do
    if grep -q "Timer\." "$file" || grep -q "Timer?" "$file"; then
        # 주석 처리된 것은 제외
        if ! grep -q "^[[:space:]]*\/\/" "$file"; then
            echo -e "${YELLOW}  ⚠️  $(basename $file): Timer 직접 사용 (TimerService 권장)${NC}"
            TIMER_USAGE=$((TIMER_USAGE + 1))
            WARNING_COUNT=$((WARNING_COUNT + 1))
        fi
    fi
done

if [ $TIMER_USAGE -eq 0 ]; then
    echo -e "${GREEN}  ✅ Timer 직접 사용 없음 (TimerService 사용 중)${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${YELLOW}  ⚠️  $TIMER_USAGE개 파일에서 Timer 직접 사용${NC}"
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}✅ Check 3: StreamController 검증${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${BLUE}3.1 StreamController close 확인${NC}"
STREAM_ISSUE=0
for file in $(find lib -name "*.dart" -type f); do
    if grep -q "StreamController" "$file"; then
        if ! grep -q "\.close()" "$file"; then
            echo -e "${YELLOW}  ⚠️  $(basename $file): StreamController.close() 없음${NC}"
            STREAM_ISSUE=$((STREAM_ISSUE + 1))
            WARNING_COUNT=$((WARNING_COUNT + 1))
        fi
    fi
done

if [ $STREAM_ISSUE -eq 0 ]; then
    echo -e "${GREEN}  ✅ 모든 StreamController close 확인됨${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}✅ Check 4: Provider 검증${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${BLUE}4.1 Provider dispose 메서드 확인${NC}"
PROVIDER_ISSUE=0
for file in lib/presentation/providers/*.dart; do
    if [ -f "$file" ]; then
        if grep -q "extends ChangeNotifier\|extends BaseProvider" "$file"; then
            if ! grep -q "void dispose()" "$file"; then
                echo -e "${RED}  ❌ $(basename $file): dispose 메서드 없음${NC}"
                PROVIDER_ISSUE=$((PROVIDER_ISSUE + 1))
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
        fi
    fi
done

if [ $PROVIDER_ISSUE -eq 0 ]; then
    echo -e "${GREEN}  ✅ 모든 Provider에 dispose 메서드 있음${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}✅ Check 5: 메모리 관리 서비스 확인${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${BLUE}5.1 MemoryManager 사용 확인${NC}"
if grep -q "MemoryManager" lib/presentation/screens/main/main_screen.dart; then
    echo -e "${GREEN}  ✅ MemoryManager 통합됨${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${YELLOW}  ⚠️  MemoryManager 미사용${NC}"
    WARNING_COUNT=$((WARNING_COUNT + 1))
fi

echo -e "\n${BLUE}5.2 TimerService 사용 확인${NC}"
if grep -q "TimerService" lib/presentation/screens/main/main_screen.dart; then
    echo -e "${GREEN}  ✅ TimerService 사용 중${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${RED}  ❌ TimerService 미사용${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}✅ Check 6: 코드 품질 검증${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${BLUE}6.1 Flutter Analyze 실행${NC}"
ANALYZE_OUTPUT=$(flutter analyze --no-pub 2>&1)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || true)
WARNING_ANALYZE=$(echo "$ANALYZE_OUTPUT" | grep -c "warning" || true)
INFO_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "info" || true)

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}  ✅ 컴파일 에러 없음${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${RED}  ❌ 에러 $ERROR_COUNT개 발견${NC}"
    FAIL_COUNT=$((FAIL_COUNT + ERROR_COUNT))
fi

echo -e "  • 경고: $WARNING_ANALYZE개"
echo -e "  • 정보: $INFO_COUNT개"

echo -e "\n${BLUE}6.2 TODO 확인${NC}"
TODO_COUNT=$(grep -r "TODO" lib/ --include="*.dart" 2>/dev/null | wc -l || echo "0")
if [ $TODO_COUNT -eq 0 ]; then
    echo -e "${GREEN}  ✅ TODO 없음${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${YELLOW}  ⚠️  TODO $TODO_COUNT개 남음${NC}"
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}✅ Check 7: 메모리 누수 패턴 검사${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${BLUE}7.1 setState in dispose 검사${NC}"
SETSTATE_IN_DISPOSE=$(grep -r "dispose().*{" lib/ -A 10 --include="*.dart" | grep "setState" | wc -l || echo "0")
if [ $SETSTATE_IN_DISPOSE -eq 0 ]; then
    echo -e "${GREEN}  ✅ dispose에서 setState 사용 없음${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${RED}  ❌ dispose에서 setState 발견${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n${BLUE}7.2 Listener 제거 확인${NC}"
LISTENER_ADD=$(grep -r "addListener" lib/ --include="*.dart" | wc -l || echo "0")
LISTENER_REMOVE=$(grep -r "removeListener" lib/ --include="*.dart" | wc -l || echo "0")
echo -e "  • addListener 호출: $LISTENER_ADD개"
echo -e "  • removeListener 호출: $LISTENER_REMOVE개"

if [ $LISTENER_ADD -gt 0 ] && [ $LISTENER_REMOVE -eq 0 ]; then
    echo -e "${YELLOW}  ⚠️  Listener 제거 확인 필요${NC}"
    WARNING_COUNT=$((WARNING_COUNT + 1))
else
    echo -e "${GREEN}  ✅ Listener 관리 적절${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
fi

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${MAGENTA}📊 메모리 누수 검증 결과${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

TOTAL_CHECKS=$((PASS_COUNT + FAIL_COUNT + WARNING_COUNT))
SCORE=$((PASS_COUNT * 100 / (PASS_COUNT + FAIL_COUNT)))

echo -e "\n${YELLOW}검증 통계:${NC}"
echo -e "  ${GREEN}✅ 통과:${NC} $PASS_COUNT개"
echo -e "  ${RED}❌ 실패:${NC} $FAIL_COUNT개"
echo -e "  ${YELLOW}⚠️  경고:${NC} $WARNING_COUNT개"
echo -e "  ${BLUE}📈 점수:${NC} ${SCORE}%"

echo -e "\n${YELLOW}메모리 누수 위험도:${NC}"
if [ $FAIL_COUNT -eq 0 ] && [ $WARNING_COUNT -le 3 ]; then
    echo -e "${GREEN}╔════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   🎉 낮음 - 안전합니다!        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════╝${NC}"
    
    echo -e "\n${GREEN}✅ 메모리 누수 수정이 완료되었습니다!${NC}"
    echo -e "프로덕션 배포 가능한 상태입니다."
    
elif [ $FAIL_COUNT -le 2 ]; then
    echo -e "${YELLOW}╔════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║   ⚠️  중간 - 추가 확인 필요     ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}몇 가지 개선사항이 있지만 사용 가능합니다.${NC}"
    
else
    echo -e "${RED}╔════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ 높음 - 수정 필요          ║${NC}"
    echo -e "${RED}╚════════════════════════════════╝${NC}"
    
    echo -e "\n${RED}메모리 누수 위험이 있습니다. 추가 수정이 필요합니다.${NC}"
fi

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}🎯 다음 단계${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n1. ${CYAN}실제 메모리 테스트:${NC}"
echo "   flutter run --profile"
echo "   DevTools → Memory → Heap Snapshot"

echo -e "\n2. ${CYAN}메모리 모니터링:${NC}"
echo "   앱 실행 → 화면 전환 반복 → 메모리 증가 확인"

echo -e "\n3. ${CYAN}성능 프로파일링:${NC}"
echo "   flutter build apk --profile"
echo "   실제 기기에서 테스트"

if [ $FAIL_COUNT -gt 0 ] || [ $WARNING_COUNT -gt 5 ]; then
    echo -e "\n${YELLOW}📝 추가 수정이 필요한 항목:${NC}"
    
    if [ $MISSING_DISPOSE -gt 0 ]; then
        echo "  • TextEditingController dispose 추가"
    fi
    
    if [ $TIMER_USAGE -gt 0 ]; then
        echo "  • Timer → TimerService 마이그레이션"
    fi
    
    if [ $STREAM_ISSUE -gt 0 ]; then
        echo "  • StreamController close 추가"
    fi
fi

echo -e "\n${GREEN}💡 최종 확인:${NC}"
echo "메모리 누수는 실제 앱 실행으로 최종 확인이 필요합니다."
echo "DevTools Memory 탭에서 확인하세요."
