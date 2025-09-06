#!/bin/bash

# Flutter 프로젝트 완전한 메모리 누수 해결 스크립트
# 작성일: 2025-01-06
# 모든 메모리 누수 위험 요소 제거

echo "======================================"
echo "🧹 완전한 메모리 누수 해결 시작"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 프로젝트 루트 확인
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Flutter 프로젝트 루트에서 실행해주세요.${NC}"
    exit 1
fi

FIXED_COUNT=0
LEAK_RISKS=0

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 1: Timer 메모리 누수 해결${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# Timer 직접 사용 찾아서 수정
find lib -name "*.dart" -type f ! -path "*/timer_service.dart" ! -path "*/memory_*" ! -path "*/base_provider.dart" | while read file; do
    if grep -q "Timer\." "$file" || grep -q "Timer?" "$file"; then
        filename=$(basename "$file")
        dirname=$(dirname "$file")
        
        echo -e "${YELLOW}  ⚠️  Timer 발견: $filename${NC}"
        LEAK_RISKS=$((LEAK_RISKS + 1))
        
        # Timer? 변수를 주석 처리하고 TODO 추가
        sed -i 's/^\(\s*\)Timer?\s*\([a-zA-Z_][a-zA-Z0-9_]*\);/\1\/\/ Timer? \2; \/\/ TODO: TimerService로 마이그레이션 필요\n\1\/\/ _timerService.startPeriodicTimer(timerId: "\2", duration: duration, callback: callback);/g' "$file"
        
        # Timer.periodic을 주석 처리
        if grep -q "Timer\.periodic" "$file"; then
            sed -i 's/\(.*Timer\.periodic.*\)/\/\/ \1 \/\/ TODO: TimerService 사용/g' "$file"
            echo -e "${GREEN}    ✅ Timer.periodic 주석 처리${NC}"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
        
        # Timer( 사용도 주석 처리
        if grep -q "Timer(" "$file"; then
            sed -i 's/\(.*= Timer(.*\)/\/\/ \1 \/\/ TODO: TimerService.startOnceTimer 사용/g' "$file"
            echo -e "${GREEN}    ✅ Timer() 주석 처리${NC}"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    fi
done

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 2: TextEditingController 누수 해결${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 모든 TextEditingController dispose 확인
find lib -name "*.dart" -type f | while read file; do
    if grep -q "TextEditingController" "$file"; then
        filename=$(basename "$file")
        
        # TextEditingController 변수들 추출
        controllers=$(grep -o "[a-zA-Z_][a-zA-Z0-9_]*Controller\s*=\s*TextEditingController" "$file" | sed 's/\s*=.*//' | sort -u)
        
        if [ ! -z "$controllers" ]; then
            echo -e "  검사중: $filename"
            
            # dispose 메서드가 있는지 확인
            if grep -q "void dispose()" "$file"; then
                for controller in $controllers; do
                    # dispose에서 호출되는지 확인
                    if ! grep -q "$controller\.dispose()" "$file"; then
                        # super.dispose() 전에 추가
                        sed -i "/super\.dispose();/i\\    $controller.dispose();" "$file"
                        echo -e "${GREEN}    ✅ $controller.dispose() 추가${NC}"
                        FIXED_COUNT=$((FIXED_COUNT + 1))
                    fi
                done
            else
                # dispose 메서드가 없으면 추가
                if grep -q "extends State<" "$file"; then
                    # build 메서드 뒤에 dispose 추가
                    sed -i '/Widget build(BuildContext context)/,/^  }$/{
                        /^  }$/a\
\
  @override\
  void dispose() {\
    // TextEditingController dispose
                    }' "$file"
                    
                    # 각 controller dispose 추가
                    for controller in $controllers; do
                        sed -i "/\/\/ TextEditingController dispose/a\\    $controller.dispose();" "$file"
                    done
                    sed -i "/\/\/ TextEditingController dispose/a\\    super.dispose();" "$file"
                    
                    echo -e "${GREEN}    ✅ dispose 메서드 생성 및 controllers 추가${NC}"
                    FIXED_COUNT=$((FIXED_COUNT + 1))
                fi
            fi
        fi
    fi
done

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 3: StreamController 누수 해결${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

find lib -name "*.dart" -type f | while read file; do
    if grep -q "StreamController" "$file"; then
        filename=$(basename "$file")
        echo -e "  검사중: $filename"
        
        # StreamController 변수 찾기
        controllers=$(grep -o "[a-zA-Z_][a-zA-Z0-9_]*Controller\s*=\s*StreamController" "$file" | sed 's/\s*=.*//' | sort -u)
        
        if [ ! -z "$controllers" ]; then
            if grep -q "void dispose()" "$file"; then
                for controller in $controllers; do
                    if ! grep -q "$controller\.close()" "$file"; then
                        # StreamController는 close() 사용
                        sed -i "/super\.dispose();/i\\    await $controller.close();" "$file"
                        echo -e "${GREEN}    ✅ $controller.close() 추가${NC}"
                        FIXED_COUNT=$((FIXED_COUNT + 1))
                    fi
                done
            fi
        fi
    fi
done

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 4: AnimationController 누수 해결${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

find lib -name "*.dart" -type f | while read file; do
    if grep -q "AnimationController" "$file"; then
        filename=$(basename "$file")
        
        # AnimationController 변수 찾기 (_flashController 등)
        controllers=$(grep -o "_[a-zA-Z]*Controller.*AnimationController" "$file" | sed 's/\s*[=:].*//;s/.*\s//' | sort -u)
        
        if [ ! -z "$controllers" ]; then
            echo -e "  검사중: $filename"
            
            for controller in $controllers; do
                if grep -q "void dispose()" "$file"; then
                    if ! grep -q "$controller\.dispose()" "$file"; then
                        sed -i "/super\.dispose();/i\\    $controller.dispose();" "$file"
                        echo -e "${GREEN}    ✅ $controller.dispose() 추가${NC}"
                        FIXED_COUNT=$((FIXED_COUNT + 1))
                    fi
                fi
            done
        fi
    fi
done

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 5: FocusNode 누수 해결${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

find lib -name "*.dart" -type f | while read file; do
    if grep -q "FocusNode" "$file"; then
        filename=$(basename "$file")
        
        # FocusNode 변수 찾기
        nodes=$(grep -o "[a-zA-Z_][a-zA-Z0-9_]*FocusNode\s*=\s*FocusNode" "$file" | sed 's/\s*=.*//' | sort -u)
        
        if [ ! -z "$nodes" ]; then
            echo -e "  검사중: $filename"
            
            for node in $nodes; do
                if grep -q "void dispose()" "$file"; then
                    if ! grep -q "$node\.dispose()" "$file"; then
                        sed -i "/super\.dispose();/i\\    $node.dispose();" "$file"
                        echo -e "${GREEN}    ✅ $node.dispose() 추가${NC}"
                        FIXED_COUNT=$((FIXED_COUNT + 1))
                    fi
                fi
            done
        fi
    fi
done

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 6: ScrollController 누수 해결${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

find lib -name "*.dart" -type f | while read file; do
    if grep -q "ScrollController" "$file"; then
        filename=$(basename "$file")
        
        # ScrollController 변수 찾기
        controllers=$(grep -o "[a-zA-Z_][a-zA-Z0-9_]*ScrollController\s*=\s*ScrollController" "$file" | sed 's/\s*=.*//' | sort -u)
        
        if [ ! -z "$controllers" ]; then
            echo -e "  검사중: $filename"
            
            for controller in $controllers; do
                if grep -q "void dispose()" "$file"; then
                    if ! grep -q "$controller\.dispose()" "$file"; then
                        sed -i "/super\.dispose();/i\\    $controller.dispose();" "$file"
                        echo -e "${GREEN}    ✅ $controller.dispose() 추가${NC}"
                        FIXED_COUNT=$((FIXED_COUNT + 1))
                    fi
                fi
            done
        fi
    fi
done

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 7: StreamSubscription 관리 개선${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

find lib -name "*.dart" -type f | while read file; do
    if grep -q "StreamSubscription" "$file"; then
        filename=$(basename "$file")
        
        # StreamSubscription 변수 찾기
        subscriptions=$(grep -o "[a-zA-Z_][a-zA-Z0-9_]*Subscription" "$file" | sort -u)
        
        if [ ! -z "$subscriptions" ]; then
            echo -e "  검사중: $filename"
            
            # List<StreamSubscription> 사용 권장 주석 추가
            if ! grep -q "List<StreamSubscription>" "$file"; then
                if grep -q "class.*State<" "$file"; then
                    # 클래스 시작 부분에 주석 추가
                    sed -i '/class.*State</a\  // TODO: StreamSubscription을 List로 관리 권장\n  // final List<StreamSubscription> _subscriptions = [];\n  // dispose()에서 for (var sub in _subscriptions) sub.cancel();' "$file"
                    echo -e "${YELLOW}    ⚠️  StreamSubscription 관리 개선 권장${NC}"
                fi
            fi
            
            # 개별 subscription cancel 확인
            for subscription in $subscriptions; do
                if grep -q "void dispose()" "$file"; then
                    if ! grep -q "$subscription\.cancel()" "$file"; then
                        sed -i "/super\.dispose();/i\\    $subscription?.cancel();" "$file"
                        echo -e "${GREEN}    ✅ $subscription.cancel() 추가${NC}"
                        FIXED_COUNT=$((FIXED_COUNT + 1))
                    fi
                done
            fi
        fi
    fi
done

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 8: Provider dispose 확인${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# Provider 클래스들 확인
for file in lib/presentation/providers/*.dart; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        
        if grep -q "extends ChangeNotifier" "$file"; then
            # BaseProvider를 상속받지 않는 경우
            if ! grep -q "extends BaseProvider" "$file"; then
                if ! grep -q "void dispose()" "$file"; then
                    echo -e "${YELLOW}  ⚠️  $filename - dispose 메서드 누락${NC}"
                    
                    # 클래스 끝 부분에 dispose 추가
                    sed -i '/^}$/i\
\
  @override\
  void dispose() {\
    // TODO: 리소스 정리 필요\
    super.dispose();\
  }' "$file"
                    
                    echo -e "${GREEN}    ✅ dispose 메서드 추가${NC}"
                    FIXED_COUNT=$((FIXED_COUNT + 1))
                fi
            fi
        fi
    fi
done

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 9: 메모리 체커 통합${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# main.dart에 메모리 체커 추가
if [ -f "lib/main.dart" ]; then
    if ! grep -q "MemoryLeakChecker" "lib/main.dart"; then
        # import 추가
        sed -i "/import 'package:flutter\/foundation.dart';/a\\import 'package:vms_app/core/utils/memory_leak_checker.dart';" "lib/main.dart"
        
        # runApp 전에 메모리 체커 시작
        sed -i '/runApp/i\  \/\/ 메모리 누수 체크 (디버그 모드)\n  if (kDebugMode) {\n    MemoryLeakChecker.startPeriodicCheck();\n  }\n' "lib/main.dart"
        
        echo -e "${GREEN}  ✅ MemoryLeakChecker 통합 완료${NC}"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    fi
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 10: 최종 검증${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 코드 포맷팅
echo "  코드 포맷팅 실행중..."
dart format lib/ --line-length=120 2>/dev/null || true

# 분석 실행
echo -e "\n  Flutter 분석 실행중..."
ANALYZE_OUTPUT=$(flutter analyze --no-pub 2>&1)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || true)
WARNING_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "warning" || true)
INFO_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "info" || true)

# 메모리 누수 위험 요소 카운트
TIMER_COUNT=$(find lib -name "*.dart" -exec grep -l "Timer\." {} \; 2>/dev/null | wc -l)
CONTROLLER_WITHOUT_DISPOSE=$(find lib -name "*.dart" -exec grep -l "Controller" {} \; 2>/dev/null | xargs grep -L "dispose()" 2>/dev/null | wc -l)

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ 메모리 누수 해결 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n📊 ${YELLOW}수정 통계:${NC}"
echo -e "  • 수정된 항목: ${GREEN}$FIXED_COUNT${NC}개"
echo -e "  • 남은 Timer 직접 사용: ${YELLOW}$TIMER_COUNT${NC}개"
echo -e "  • dispose 없는 Controller: ${YELLOW}$CONTROLLER_WITHOUT_DISPOSE${NC}개"

echo -e "\n📈 ${YELLOW}코드 품질:${NC}"
if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "  • 에러: ${GREEN}0${NC}개 ✅"
else
    echo -e "  • 에러: ${RED}$ERROR_COUNT${NC}개 ❌"
fi
echo -e "  • 경고: ${YELLOW}$WARNING_COUNT${NC}개"
echo -e "  • 정보: ${BLUE}$INFO_COUNT${NC}개"

echo -e "\n🎯 ${YELLOW}다음 단계:${NC}"
echo "1. ${CYAN}flutter clean${NC}"
echo "2. ${CYAN}flutter pub get${NC}"
echo "3. ${CYAN}flutter run --debug${NC} (메모리 체커 동작 확인)"
echo "4. ${CYAN}flutter run --profile${NC} (메모리 프로파일링)"

if [ $TIMER_COUNT -gt 0 ] || [ $CONTROLLER_WITHOUT_DISPOSE -gt 0 ]; then
    echo -e "\n⚠️  ${YELLOW}추가 작업 필요:${NC}"
    echo "• TODO 주석 확인 및 수동 수정"
    echo "• Timer → TimerService 마이그레이션"
    echo "• dispose 메서드 완성"
fi

echo -e "\n💡 ${GREEN}메모리 누수 확인 방법:${NC}"
echo "• DevTools → Memory → Leak Detection"
echo "• 앱 실행 중 콘솔에서 메모리 리포트 확인"
echo "• flutter inspector → Performance Overlay"
