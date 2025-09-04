#!/bin/bash

# ================================================
#    중복 정의 에러 수정 스크립트
# ================================================

echo "🧹 중복 변수 정의 정리 스크립트"
echo "==============================="

MAIN_SCREEN="lib/presentation/screens/main/main_screen.dart"
BACKUP_DIR="duplicate_fix_backup_$(date +%Y%m%d_%H%M%S)"

# 백업 생성
mkdir -p $BACKUP_DIR
cp $MAIN_SCREEN $BACKUP_DIR/main_screen.dart.backup
echo "📁 백업 생성: $BACKUP_DIR/main_screen.dart.backup"

# Python 스크립트로 중복 제거
cat > remove_duplicates.py << 'EOF'
import sys
import re

def remove_duplicate_variables(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # 변수 정의를 추적하기 위한 딕셔너리
    variable_definitions = {
        '_activePopups': [],
        '_timerService': [],
        '_popupService': [],
        '_locationFocusService': [],
        '_stateManager': [],
        '_memoryManager': [],
        '_timer': [],
        '_vesselUpdateTimer': [],
        '_routeUpdateTimer': []
    }
    
    # 각 변수의 라인 번호 저장
    for i, line in enumerate(lines):
        for var_name in variable_definitions.keys():
            # 주석이 아닌 실제 변수 선언 찾기
            if var_name in line and not line.strip().startswith('//'):
                # 변수 선언 패턴 확인
                if ('Timer? ' + var_name in line or 
                    'TimerService? ' + var_name in line or
                    'TimerService ' + var_name in line or
                    'PopupService? ' + var_name in line or
                    'PopupService ' + var_name in line or
                    'LocationFocusService? ' + var_name in line or
                    'LocationFocusService ' + var_name in line or
                    'StateManager? ' + var_name in line or
                    'StateManager ' + var_name in line or
                    'MemoryManager? ' + var_name in line or
                    'MemoryManager ' + var_name in line or
                    'final MemoryManager ' + var_name in line or
                    'Map<String, bool> ' + var_name in line or
                    'final Map<String, bool> ' + var_name in line):
                    variable_definitions[var_name].append(i)
    
    # 중복 제거 - 첫 번째 정의만 유지
    lines_to_remove = set()
    for var_name, line_numbers in variable_definitions.items():
        if len(line_numbers) > 1:
            print(f"  • {var_name}: {len(line_numbers)}개 발견 (라인: {line_numbers})")
            # 첫 번째를 제외한 나머지 제거
            for line_num in line_numbers[1:]:
                lines_to_remove.add(line_num)
                
                # _activePopups의 경우 여러 줄에 걸쳐 있을 수 있음
                if var_name == '_activePopups':
                    # Map 정의가 여러 줄에 걸쳐 있는 경우 처리
                    j = line_num
                    while j < len(lines):
                        lines_to_remove.add(j)
                        if '};' in lines[j]:
                            break
                        j += 1
    
    # 새로운 파일 내용 생성
    new_lines = []
    skip_until = -1
    
    for i, line in enumerate(lines):
        if i <= skip_until:
            continue
            
        if i in lines_to_remove:
            # _activePopups Map인 경우 전체 블록 건너뛰기
            if '_activePopups' in line and 'Map<' in line:
                skip_until = i
                while skip_until < len(lines) and '};' not in lines[skip_until]:
                    skip_until += 1
            continue
        
        new_lines.append(line)
    
    # 파일 저장
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    return len(lines_to_remove) > 0

# 실행
if __name__ == "__main__":
    print("\n🔍 중복 변수 검색 중...")
    if remove_duplicate_variables(sys.argv[1]):
        print("\n✅ 중복 변수 제거 완료!")
    else:
        print("\n✅ 중복 변수 없음!")
EOF

python3 remove_duplicates.py $MAIN_SCREEN
rm remove_duplicates.py

# 서비스 변수 타입 정리 (optional을 non-optional로 변경 필요시)
echo ""
echo "📝 서비스 변수 타입 확인 중..."

cat > fix_service_types.py << 'EOF'
import sys

def fix_service_variable_types(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    modified = False
    for i in range(len(lines)):
        line = lines[i]
        
        # late final 형태로 통일 (initState에서 초기화)
        if 'TimerService? _timerService' in line:
            lines[i] = line.replace('TimerService?', 'late final TimerService')
            modified = True
        elif 'PopupService? _popupService' in line:
            lines[i] = line.replace('PopupService?', 'late final PopupService')
            modified = True
        elif 'LocationFocusService? _locationFocusService' in line:
            lines[i] = line.replace('LocationFocusService?', 'late final LocationFocusService')
            modified = True
        elif 'StateManager? _stateManager' in line:
            lines[i] = line.replace('StateManager?', 'late final StateManager')
            modified = True
        elif 'MemoryManager? _memoryManager' in line:
            lines[i] = line.replace('MemoryManager?', 'final MemoryManager').replace(' _memoryManager;', ' _memoryManager = MemoryManager();')
            modified = True
    
    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        return True
    return False

if __name__ == "__main__":
    if fix_service_variable_types(sys.argv[1]):
        print("✅ 서비스 변수 타입 정리 완료")
    else:
        print("ℹ️  서비스 변수 타입 변경 없음")
EOF

python3 fix_service_types.py $MAIN_SCREEN
rm fix_service_types.py

# 최종 검증
echo ""
echo "🔍 최종 검증 중..."

# 각 변수가 정확히 한 번만 정의되었는지 확인
echo "변수 정의 횟수 확인:"
for var in "_activePopups" "_timerService" "_popupService" "_locationFocusService" "_stateManager" "_memoryManager" "_timer" "_vesselUpdateTimer" "_routeUpdateTimer"; do
    COUNT=$(grep -c "^\s*[a-zA-Z]*\s*$var[;=]" $MAIN_SCREEN 2>/dev/null || echo 0)
    if [ "$COUNT" -eq 1 ]; then
        echo "  ✅ $var: 1개 (정상)"
    elif [ "$COUNT" -eq 0 ]; then
        echo "  ⚠️  $var: 0개 (없음)"
    else
        echo "  ❌ $var: ${COUNT}개 (중복)"
    fi
done

# 컴파일 체크
echo ""
echo "🔍 컴파일 체크 중..."
ERROR_COUNT=$(flutter analyze --no-fatal-warnings 2>&1 | grep -c "duplicate_definition" || echo 0)

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo ""
    echo "✅ 모든 중복 정의 에러가 해결되었습니다!"
else
    echo ""
    echo "⚠️  아직 ${ERROR_COUNT}개의 중복 정의 에러가 있습니다."
    echo ""
    echo "수동 확인이 필요합니다:"
    flutter analyze --no-fatal-warnings 2>&1 | grep "duplicate_definition" | head -5
fi

echo ""
echo "================================"
echo "       중복 제거 완료!"
echo "================================"
echo ""
echo "🚀 다음 단계:"
echo "  1. flutter clean"
echo "  2. flutter pub get"
echo "  3. flutter run"
echo ""
echo "📁 백업: $BACKUP_DIR/main_screen.dart.backup"
echo ""
echo "⚠️  initState에서 서비스 초기화 확인:"
echo "  _timerService = TimerService();"
echo "  _popupService = PopupService();"
echo "  등..."
