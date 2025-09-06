#!/bin/bash

# 정리 후 발생한 에러 수정 스크립트
# 작성일: 2025-01-06

echo "======================================"
echo "🔧 에러 수정 시작"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 백업
cp lib/presentation/screens/main/main_screen.dart lib/presentation/screens/main/main_screen.dart.error_backup
echo -e "${GREEN}✅ 백업 생성 완료${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 1: 팝업 함수 호출 수정 (4번째 파라미터 추가)${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# Python 스크립트로 팝업 호출 수정
cat > fix_popup_calls.py << 'PYTHON_EOF'
import re

with open('lib/presentation/screens/main/main_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 284번 줄 근처 수정 (showTurbineWarningPopup)
for i in range(283, min(286, len(lines))):
    if 'MainScreenPopups.showTurbineWarningPopup' in lines[i]:
        # 3개 파라미터만 있는 경우 4번째 추가
        if lines[i].count(',') == 2:
            lines[i] = lines[i].rstrip(')\n') + ', () { _stopFlashing(); _popupService.hidePopup(PopupService.TURBINE_ENTRY_ALERT); });\n'
        print(f"✅ {i+1}번 줄 수정: showTurbineWarningPopup")
        break

# 289번 줄 근처 수정 (showWeatherWarningPopup)
for i in range(288, min(291, len(lines))):
    if 'MainScreenPopups.showWeatherWarningPopup' in lines[i]:
        if lines[i].count(',') == 2:
            lines[i] = lines[i].rstrip(')\n') + ', () { _stopFlashing(); _popupService.hidePopup(PopupService.WEATHER_ALERT); });\n'
        print(f"✅ {i+1}번 줄 수정: showWeatherWarningPopup")
        break

# 295번 줄 근처 수정 (showSubmarineWarningPopup)
for i in range(294, min(297, len(lines))):
    if 'MainScreenPopups.showSubmarineWarningPopup' in lines[i]:
        if lines[i].count(',') == 2:
            lines[i] = lines[i].rstrip(')\n') + ', () { _stopFlashing(); _popupService.hidePopup(PopupService.SUBMARINE_CABLE_ALERT); });\n'
        print(f"✅ {i+1}번 줄 수정: showSubmarineWarningPopup")
        break

with open('lib/presentation/screens/main/main_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
PYTHON_EOF

python3 fix_popup_calls.py
rm -f fix_popup_calls.py
echo -e "${GREEN}✅ 팝업 호출 수정 완료${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 2: Constructor 에러 수정${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 65번 줄 에러 확인
echo -e "\n${BLUE}65번 줄 확인:${NC}"
sed -n '64,66p' lib/presentation/screens/main/main_screen.dart

# 721, 823, 925번 줄 근처 확인 및 수정
cat > fix_constructors.py << 'PYTHON_EOF'
import re

with open('lib/presentation/screens/main/main_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# void 또는 Future<void>가 잘못 남아있는 경우 제거
# 예: void _someFunction이 함수 중간에 잘못 남아있는 경우

# 721번 줄 근처 문제 해결
lines = content.split('\n')

problematic_lines = [720, 822, 924]  # 0-based index
for line_num in problematic_lines:
    if line_num < len(lines):
        line = lines[line_num]
        # void 또는 Future<void>로 시작하는 잘못된 줄 찾기
        if re.match(r'^\s*(void|Future<void>)\s+\w+\s*$', line):
            print(f"문제 발견 {line_num+1}번 줄: {line}")
            # 해당 줄을 주석 처리
            lines[line_num] = '  // ' + line.strip() + ' // TODO: 이 줄 확인 필요'

content = '\n'.join(lines)

with open('lib/presentation/screens/main/main_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Constructor 문제 수정 시도 완료")
PYTHON_EOF

python3 fix_constructors.py
rm -f fix_constructors.py

echo -e "${GREEN}✅ Constructor 에러 수정 시도${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 3: 문제가 있는 줄 직접 확인${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 문제 줄들 확인
echo -e "\n${BLUE}721번 줄 근처:${NC}"
sed -n '719,723p' lib/presentation/screens/main/main_screen.dart

echo -e "\n${BLUE}823번 줄 근처:${NC}"
sed -n '821,825p' lib/presentation/screens/main/main_screen.dart

echo -e "\n${BLUE}925번 줄 근처:${NC}"
sed -n '923,927p' lib/presentation/screens/main/main_screen.dart

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 4: 깨진 함수 정의 수정${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 깨진 함수 정의 찾아서 수정
cat > fix_broken_functions.py << 'PYTHON_EOF'
import re

with open('lib/presentation/screens/main/main_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

fixed_count = 0

for i in range(len(lines)):
    line = lines[i].strip()
    
    # void functionName 형태로 남아있는 불완전한 함수 정의
    if re.match(r'^(void|Future<void>)\s+\w+\s*$', line):
        # 이런 줄들은 아마 잘못 잘린 함수들일 것
        print(f"불완전한 함수 정의 발견: {i+1}번 줄: {line}")
        # 주석 처리
        lines[i] = '  // REMOVED: ' + line + '\n'
        fixed_count += 1
    
    # 클래스 내부에서 갑자기 나타나는 return type이 있는 메서드 선언
    elif re.match(r'^\s*(void|Future<void>|Widget)\s+_\w+\s*$', line):
        print(f"깨진 메서드 선언 발견: {i+1}번 줄: {line}")
        lines[i] = '  // REMOVED: ' + line + '\n'
        fixed_count += 1

with open('lib/presentation/screens/main/main_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print(f"총 {fixed_count}개 줄 수정")
PYTHON_EOF

python3 fix_broken_functions.py
rm -f fix_broken_functions.py

echo -e "${GREEN}✅ 깨진 함수 정의 수정${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 5: Flutter Analyze 재실행${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n${BLUE}분석 중...${NC}"
ANALYZE_OUTPUT=$(flutter analyze lib/presentation/screens/main/main_screen.dart 2>&1)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || true)

echo -e "\n수정 후 에러: ${RED}$ERROR_COUNT${NC}개"

if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "\n${YELLOW}남은 에러 (상위 5개):${NC}"
    echo "$ANALYZE_OUTPUT" | grep "error" | head -5
    
    echo -e "\n${YELLOW}💡 수동 수정이 필요할 수 있습니다:${NC}"
    echo "1. 에러가 있는 줄로 이동:"
    echo "   vim +721 lib/presentation/screens/main/main_screen.dart"
    echo ""
    echo "2. 불완전한 함수 정의가 있다면 삭제"
    echo "3. 복구가 필요하면:"
    echo "   cp lib/presentation/screens/main/main_screen.dart.error_backup lib/presentation/screens/main/main_screen.dart"
else
    echo -e "${GREEN}✅ 모든 에러 해결!${NC}"
fi

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ 에러 수정 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n${GREEN}완료!${NC}"
