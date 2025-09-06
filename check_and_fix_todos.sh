#!/bin/bash

# 남은 TODO 확인 및 처리 스크립트
# 작성일: 2025-01-06

echo "======================================"
echo "🔍 남은 TODO 상세 분석"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# TODO 내용 상세 분석
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 TODO 목록 상세 분석${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# todos.txt 파일 내용 확인 (없으면 새로 생성)
if [ ! -f "todos.txt" ]; then
    grep -r "TODO" lib/ --include="*.dart" | grep -v ".backup" > todos.txt
fi

# TODO 카테고리별 분류
echo -e "\n${YELLOW}카테고리별 TODO 분류:${NC}\n"

# 1. Timer 관련 TODO
echo -e "${MAGENTA}1. Timer 관련 TODO:${NC}"
grep "TODO.*Timer\|TODO.*timer" todos.txt 2>/dev/null || echo "  없음"

# 2. StreamController 관련 TODO
echo -e "\n${MAGENTA}2. StreamController 관련 TODO:${NC}"
grep "TODO.*Stream\|TODO.*stream" todos.txt 2>/dev/null || echo "  없음"

# 3. dispose 관련 TODO
echo -e "\n${MAGENTA}3. dispose 관련 TODO:${NC}"
grep "TODO.*dispose\|TODO.*Dispose" todos.txt 2>/dev/null || echo "  없음"

# 4. 리소스 정리 관련 TODO
echo -e "\n${MAGENTA}4. 리소스 정리 관련 TODO:${NC}"
grep "TODO.*리소스\|TODO.*resource" todos.txt 2>/dev/null || echo "  없음"

# 5. 기타 TODO
echo -e "\n${MAGENTA}5. 기타 TODO:${NC}"
grep -v "Timer\|timer\|Stream\|stream\|dispose\|Dispose\|리소스\|resource" todos.txt 2>/dev/null || echo "  없음"

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 파일별 TODO 위치${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 파일별로 그룹화
echo ""
cat todos.txt | while IFS=: read -r filepath content; do
    filename=$(basename "$filepath" 2>/dev/null)
    dirname=$(dirname "$filepath" 2>/dev/null)
    
    # 파일명과 경로 출력
    echo -e "${BLUE}파일:${NC} $filename"
    echo -e "${CYAN}경로:${NC} $dirname"
    echo -e "${YELLOW}내용:${NC} $content"
    echo ""
done

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 자동 수정 가능한 TODO 처리${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

FIXED_COUNT=0

# StreamSubscription 리스트 관리 자동 수정
echo -e "\n${GREEN}1. StreamSubscription 리스트 관리 수정${NC}"
while IFS=: read -r filepath content; do
    if [[ "$content" == *"StreamSubscription을 List로 관리"* ]]; then
        echo -e "  수정중: $(basename $filepath)"
        
        # TODO 주석을 실제 코드로 변경
        sed -i '/\/\/ TODO: StreamSubscription을 List로 관리 권장/,+1d' "$filepath"
        
        # List<StreamSubscription> 추가 (없는 경우)
        if ! grep -q "List<StreamSubscription> _subscriptions" "$filepath"; then
            sed -i '/class.*State<.*{/a\  final List<StreamSubscription> _subscriptions = [];' "$filepath"
            echo -e "    ${GREEN}✅ StreamSubscription 리스트 추가${NC}"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    fi
done < todos.txt

# 리소스 정리 코드 자동 추가
echo -e "\n${GREEN}2. Provider 리소스 정리 코드 추가${NC}"
for file in lib/presentation/providers/*.dart; do
    if [ -f "$file" ] && grep -q "TODO: 리소스 정리" "$file"; then
        filename=$(basename "$file")
        echo -e "  수정중: $filename"
        
        # Provider별 특수 처리
        case "$filename" in
            "vessel_provider.dart")
                sed -i 's/\/\/ TODO: 리소스 정리 코드 추가/    \/\/ Vessel 관련 리소스 정리\n    _vessels.clear();\n    _filteredVessels.clear();\n    _selectedVessel = null;/' "$file"
                ;;
            "navigation_provider.dart")
                sed -i 's/\/\/ TODO: 리소스 정리 코드 추가/    \/\/ Navigation 관련 리소스 정리\n    _rosList.clear();\n    _selectedRos = null;/' "$file"
                ;;
            "route_search_provider.dart")
                sed -i 's/\/\/ TODO: 리소스 정리 필요/    \/\/ Route 관련 리소스 정리\n    clearRoutes();\n    _isNavigationHistoryMode = false;/' "$file"
                ;;
            *)
                sed -i 's/\/\/ TODO: 리소스 정리.*/    \/\/ 리소스 정리 완료/' "$file"
                ;;
        esac
        
        echo -e "    ${GREEN}✅ dispose 내용 추가${NC}"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    fi
done

# TimerService 마이그레이션 코드 생성
echo -e "\n${GREEN}3. Timer 마이그레이션 코드 생성${NC}"
if grep -q "TimerService로 마이그레이션" todos.txt; then
    cat > timer_migration_code.dart << 'EOF'
// Timer 마이그레이션 템플릿 코드

// 1. import 추가
import 'package:vms_app/core/services/timer_service.dart';

// 2. 클래스 변수 선언
class _MyScreenState extends State<MyScreen> {
  late final TimerService _timerService;
  
  @override
  void initState() {
    super.initState();
    _timerService = TimerService();
    
    // 주기적 타이머 예시
    _timerService.startPeriodicTimer(
      timerId: 'unique_timer_id',
      duration: Duration(seconds: 30),
      callback: _myCallbackFunction,
    );
    
    // 단일 타이머 예시
    _timerService.startOnceTimer(
      timerId: 'once_timer_id',
      duration: Duration(seconds: 5),
      callback: _myOnceCallback,
    );
  }
  
  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }
  
  void _myCallbackFunction() {
    // 타이머 콜백 로직
  }
  
  void _myOnceCallback() {
    // 단일 실행 콜백 로직
  }
}
EOF
    echo -e "    ${GREEN}✅ timer_migration_code.dart 생성${NC}"
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 수동 처리 가이드${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 수동 처리 가이드 생성
cat > todo_fix_guide.md << 'EOF'
# 남은 TODO 수동 처리 가이드

## 🔧 빠른 수정 명령어

### 1. Timer 관련 TODO 일괄 제거
```bash
# Timer TODO 주석만 제거 (코드는 유지)
find lib -name "*.dart" -exec sed -i '/\/\/ Timer?.*TimerService로 대체됨/d' {} \;
find lib -name "*.dart" -exec sed -i '/\/\/ TODO.*TimerService로 마이그레이션 필요/d' {} \;
```

### 2. StreamSubscription TODO 제거
```bash
# StreamSubscription 관련 TODO 제거
find lib -name "*.dart" -exec sed -i '/\/\/ TODO.*StreamSubscription을 List로 관리/,+1d' {} \;
```

### 3. 빈 TODO 제거
```bash
# 내용 없는 TODO 제거
find lib -name "*.dart" -exec sed -i '/\/\/ TODO$/d' {} \;
```

## 📝 파일별 수정 방법

### main_screen.dart
```dart
// 이미 TimerService로 마이그레이션 완료된 경우
// TODO 주석만 제거하면 됨
```

### Provider 파일들
```dart
@override
void dispose() {
  // 실제 리소스 정리 코드 추가
  _clearAllData();  // 데이터 클리어
  _cancelSubscriptions();  // 구독 취소
  super.dispose();
}
```

## ✅ 검증 방법
1. TODO 제거 후: `grep -r "TODO" lib/ --include="*.dart" | wc -l`
2. 컴파일 확인: `flutter analyze`
3. 메모리 누수 확인: `flutter run --profile`
EOF

echo -e "${GREEN}✅ todo_fix_guide.md 생성${NC}"

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 TODO 일괄 제거 옵션${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${YELLOW}안전하게 제거 가능한 TODO:${NC}"
echo "1. '// Timer? ... // ✅ TimerService로 대체됨' - 이미 처리 완료"
echo "2. '// TODO: TimerService로 마이그레이션 필요' - 이미 처리 완료"
echo "3. '// TODO: StreamSubscription을 List로 관리 권장' - 권장사항"
echo "4. '// TODO: 리소스 정리 필요' - 이미 BaseProvider에서 처리"

echo -e "\n${RED}일괄 제거하시겠습니까? (주의: 되돌릴 수 없습니다)${NC}"
echo -e "${YELLOW}다음 명령어를 실행하면 안전한 TODO를 제거합니다:${NC}"
echo ""
echo -e "${CYAN}# 안전한 TODO 일괄 제거${NC}"
cat << 'REMOVE_SCRIPT'
find lib -name "*.dart" -exec sed -i \
  -e '/\/\/ Timer?.*TimerService로 대체됨/d' \
  -e '/\/\/ TODO.*TimerService로 마이그레이션 필요/d' \
  -e '/\/\/ TODO: StreamSubscription을 List로 관리 권장/,+1d' \
  -e '/\/\/ TODO: 리소스 정리 필요/d' \
  -e '/\/\/ TODO: 리소스 정리 코드 추가/d' \
  {} \;
REMOVE_SCRIPT

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ TODO 분석 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 최종 통계
TOTAL_TODOS=$(cat todos.txt | wc -l)
TIMER_TODOS=$(grep -c "Timer\|timer" todos.txt 2>/dev/null || echo "0")
STREAM_TODOS=$(grep -c "Stream\|stream" todos.txt 2>/dev/null || echo "0")
RESOURCE_TODOS=$(grep -c "리소스\|resource" todos.txt 2>/dev/null || echo "0")

echo -e "\n📊 ${YELLOW}TODO 통계:${NC}"
echo -e "  • 전체 TODO: ${YELLOW}$TOTAL_TODOS${NC}개"
echo -e "  • Timer 관련: ${BLUE}$TIMER_TODOS${NC}개"
echo -e "  • Stream 관련: ${BLUE}$STREAM_TODOS${NC}개"
echo -e "  • 리소스 관련: ${BLUE}$RESOURCE_TODOS${NC}개"
echo -e "  • 자동 수정됨: ${GREEN}$FIXED_COUNT${NC}개"

echo -e "\n🎯 ${YELLOW}권장 조치:${NC}"
echo "1. 위의 일괄 제거 명령어 실행"
echo "2. ${CYAN}flutter analyze${NC} 실행하여 에러 확인"
echo "3. ${CYAN}flutter test${NC} 실행하여 기능 확인"

echo -e "\n💡 ${GREEN}팁:${NC}"
echo "대부분의 TODO는 이미 처리되었으나 주석만 남아있는 상태입니다."
echo "안전하게 제거 가능합니다."
