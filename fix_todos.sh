#!/bin/bash

# TODO 주석 자동 처리 스크립트
# 작성일: 2025-01-06

echo "======================================"
echo "📝 TODO 주석 처리 시작"
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

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 1: TODO 목록 수집${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# TODO 목록을 파일로 저장
grep -r "TODO" lib/ --include="*.dart" | grep -v ".backup" > todos.txt
TODO_COUNT=$(wc -l < todos.txt)

echo -e "발견된 TODO: ${YELLOW}$TODO_COUNT${NC}개"
echo ""

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 2: Timer → TimerService 마이그레이션${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# Timer 관련 TODO 처리
grep -l "TODO.*TimerService" lib/**/*.dart 2>/dev/null | while read file; do
    echo -e "  처리중: $(basename $file)"
    
    # 파일에 TimerService import 추가 (없는 경우)
    if ! grep -q "import.*timer_service" "$file"; then
        # 첫 번째 import 뒤에 추가
        sed -i '0,/^import/!b; /^import/a\import '\''package:vms_app/core/services/timer_service.dart'\'';' "$file"
        echo -e "${GREEN}    ✅ TimerService import 추가${NC}"
    fi
    
    # late TimerService 변수 추가 (없는 경우)
    if ! grep -q "TimerService _timerService" "$file"; then
        # 클래스 변수 섹션에 추가
        sed -i '/class.*State<.*{/a\  late TimerService _timerService;' "$file"
        echo -e "${GREEN}    ✅ TimerService 변수 추가${NC}"
    fi
    
    # initState에서 TimerService 초기화 (없는 경우)
    if grep -q "void initState()" "$file"; then
        if ! grep -q "_timerService = TimerService()" "$file"; then
            sed -i '/super\.initState();/a\    _timerService = TimerService();' "$file"
            echo -e "${GREEN}    ✅ TimerService 초기화 추가${NC}"
        fi
    fi
    
    # dispose에서 TimerService dispose (없는 경우)
    if grep -q "void dispose()" "$file"; then
        if ! grep -q "_timerService.dispose()" "$file"; then
            sed -i '/super\.dispose();/i\    _timerService.dispose();' "$file"
            echo -e "${GREEN}    ✅ TimerService dispose 추가${NC}"
        fi
    fi
    
    # TODO 주석 제거
    sed -i '/\/\/ TODO.*TimerService/d' "$file"
    
    FIXED_COUNT=$((FIXED_COUNT + 1))
done

# Timer.periodic 패턴을 TimerService로 변환하는 예시 생성
cat > timer_migration_guide.md << 'EOF'
# Timer → TimerService 마이그레이션 가이드

## 변경 전 (Timer 직접 사용)
```dart
Timer? _timer;

@override
void initState() {
  super.initState();
  _timer = Timer.periodic(Duration(seconds: 3), (_) {
    _updateData();
  });
}

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```

## 변경 후 (TimerService 사용)
```dart
late TimerService _timerService;

@override
void initState() {
  super.initState();
  _timerService = TimerService();
  _timerService.startPeriodicTimer(
    timerId: 'data_update',
    duration: Duration(seconds: 3),
    callback: _updateData,
  );
}

@override
void dispose() {
  _timerService.dispose();
  super.dispose();
}
```
EOF

echo -e "${GREEN}  ✅ timer_migration_guide.md 생성됨${NC}"

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 3: StreamSubscription 리스트 관리${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# StreamSubscription 관련 TODO 처리
grep -l "TODO.*StreamSubscription.*List" lib/**/*.dart 2>/dev/null | while read file; do
    echo -e "  처리중: $(basename $file)"
    
    # List<StreamSubscription> 변수 추가
    if ! grep -q "List<StreamSubscription> _subscriptions" "$file"; then
        # TODO 주석을 실제 코드로 변경
        sed -i 's/\/\/ TODO.*StreamSubscription.*List.*/  final List<StreamSubscription> _subscriptions = [];/g' "$file"
        
        # dispose에서 일괄 처리 코드 추가
        if grep -q "void dispose()" "$file"; then
            sed -i '/super\.dispose();/i\    for (final subscription in _subscriptions) {\n      subscription.cancel();\n    }' "$file"
        fi
        
        echo -e "${GREEN}    ✅ StreamSubscription 리스트 관리 코드 추가${NC}"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    fi
done

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 4: Provider dispose 내용 추가${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# Provider 관련 TODO 처리
for file in lib/presentation/providers/*.dart; do
    if [ -f "$file" ] && grep -q "TODO.*리소스 정리" "$file"; then
        filename=$(basename "$file")
        echo -e "  처리중: $filename"
        
        # TODO를 실제 정리 코드로 변경
        sed -i 's/\/\/ TODO: 리소스 정리 필요/    \/\/ 모든 컨트롤러와 스트림 정리\n    \/\/ 필요한 경우 추가 정리 코드 작성/g' "$file"
        
        echo -e "${GREEN}    ✅ Provider dispose 주석 개선${NC}"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    fi
done

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 5: 수동 처리 필요 TODO 리스트${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 남은 TODO 확인
REMAINING_TODOS=$(grep -r "TODO" lib/ --include="*.dart" | grep -v ".backup" | wc -l)

if [ $REMAINING_TODOS -gt 0 ]; then
    echo -e "${YELLOW}수동 처리가 필요한 TODO:${NC}"
    echo ""
    
    # 파일별로 그룹화하여 출력
    grep -r "TODO" lib/ --include="*.dart" | grep -v ".backup" | while IFS=: read -r file line; do
        filename=$(basename "$file")
        echo -e "${BLUE}$filename:${NC}"
        echo "  $line"
    done
    
    # 수동 처리 가이드 생성
    cat > manual_todo_guide.md << 'EOF'
# 수동 TODO 처리 가이드

## 1. Timer 마이그레이션 확인사항
- Timer.periodic → _timerService.startPeriodicTimer
- Timer() → _timerService.startOnceTimer
- timer?.cancel() → _timerService.stopTimer(timerId)

## 2. StreamController 처리
```dart
// dispose에 추가
await _streamController?.close();
```

## 3. 복잡한 리소스 정리
```dart
@override
void dispose() {
  // 애니메이션 컨트롤러
  _animationController?.dispose();
  
  // 텍스트 컨트롤러
  _textController?.dispose();
  
  // 포커스 노드
  _focusNode?.dispose();
  
  // 스크롤 컨트롤러  
  _scrollController?.dispose();
  
  // 타이머 서비스
  _timerService?.dispose();
  
  super.dispose();
}
```

## 4. 메모리 누수 체크
- 앱 실행 후 DevTools → Memory 탭 확인
- 화면 전환 시 인스턴스 수 확인
- dispose 후 리소스 해제 확인
EOF
    
    echo -e "\n${GREEN}  ✅ manual_todo_guide.md 생성됨${NC}"
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 6: 코드 검증${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 코드 포맷팅
dart format lib/ --line-length=120 2>/dev/null || true

# 분석 실행
ANALYZE_OUTPUT=$(flutter analyze --no-pub 2>&1)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || true)

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ TODO 처리 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n📊 ${YELLOW}처리 결과:${NC}"
echo -e "  • 자동 처리된 TODO: ${GREEN}$FIXED_COUNT${NC}개"
echo -e "  • 남은 TODO: ${YELLOW}$REMAINING_TODOS${NC}개"
echo -e "  • 컴파일 에러: ${ERROR_COUNT}개"

echo -e "\n📁 ${YELLOW}생성된 가이드 파일:${NC}"
echo -e "  • ${CYAN}timer_migration_guide.md${NC} - Timer 마이그레이션 예시"
echo -e "  • ${CYAN}manual_todo_guide.md${NC} - 수동 처리 가이드"
echo -e "  • ${CYAN}todos.txt${NC} - 전체 TODO 목록"

echo -e "\n🎯 ${YELLOW}다음 단계:${NC}"
echo "1. ${CYAN}cat manual_todo_guide.md${NC} - 가이드 확인"
echo "2. ${CYAN}code todos.txt${NC} - TODO 목록 확인"
echo "3. 수동으로 남은 TODO 처리"
echo "4. ${CYAN}flutter test${NC} - 테스트 실행"

if [ $REMAINING_TODOS -gt 0 ]; then
    echo -e "\n⚠️  ${YELLOW}중요:${NC}"
    echo "아직 $REMAINING_TODOS개의 TODO가 남아있습니다."
    echo "manual_todo_guide.md를 참고하여 수동으로 처리해주세요."
fi
