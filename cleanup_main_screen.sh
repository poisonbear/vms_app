#!/bin/bash

# main_screen.dart 대대적 정리 스크립트
# 작성일: 2025-01-06

echo "======================================"
echo "🧹 main_screen.dart 대대적 정리"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 백업 생성
BACKUP_FILE="lib/presentation/screens/main/main_screen.dart.cleanup_backup_$(date +%Y%m%d_%H%M%S)"
cp lib/presentation/screens/main/main_screen.dart "$BACKUP_FILE"
echo -e "${GREEN}✅ 백업 생성: $BACKUP_FILE${NC}"

# 시작 라인 수
BEFORE_LINES=$(wc -l < lib/presentation/screens/main/main_screen.dart)
echo -e "시작 라인 수: ${RED}$BEFORE_LINES${NC}줄"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 1: 주석 처리된 코드 제거${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 주석 처리된 _infoRow 함수 제거
sed -i '/^[[:space:]]*\/\/ TableRow _infoRow/,/^[[:space:]]*\/\/ }/d' lib/presentation/screens/main/main_screen.dart
echo -e "${GREEN}✅ 주석 처리된 _infoRow 제거${NC}"

# 연속된 빈 줄 제거
sed -i '/^$/N;/^\n$/d' lib/presentation/screens/main/main_screen.dart
echo -e "${GREEN}✅ 연속된 빈 줄 제거${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 2: Import 추가 (누락된 것)${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# widgets 폴더의 import들 추가 (없으면)
if ! grep -q "import 'widgets/popup_dialogs.dart'" lib/presentation/screens/main/main_screen.dart; then
    sed -i "/import 'widgets\/vessel_info_table.dart';/a import 'widgets/popup_dialogs.dart';" lib/presentation/screens/main/main_screen.dart
    echo -e "${GREEN}✅ popup_dialogs.dart import 추가${NC}"
fi

if ! grep -q "import 'widgets/vessel_markers.dart'" lib/presentation/screens/main/main_screen.dart; then
    sed -i "/import 'widgets\/popup_dialogs.dart';/a import 'widgets/vessel_markers.dart';" lib/presentation/screens/main/main_screen.dart
    echo -e "${GREEN}✅ vessel_markers.dart import 추가${NC}"
fi

if ! grep -q "import 'widgets/map_widget.dart'" lib/presentation/screens/main/main_screen.dart; then
    sed -i "/import 'widgets\/vessel_markers.dart';/a import 'widgets/map_widget.dart';" lib/presentation/screens/main/main_screen.dart
    echo -e "${GREEN}✅ map_widget.dart import 추가${NC}"
fi

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 3: 팝업 함수들을 MainScreenPopups로 교체${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# _showRosPopup을 MainScreenPopups.showTurbineWarningPopup으로 교체
sed -i 's/_showRosPopup(/MainScreenPopups.showTurbineWarningPopup(/g' lib/presentation/screens/main/main_screen.dart
echo -e "${GREEN}✅ _showRosPopup → MainScreenPopups.showTurbineWarningPopup${NC}"

# _showWeatherPopup을 MainScreenPopups.showWeatherWarningPopup으로 교체
sed -i 's/_showWeatherPopup(/MainScreenPopups.showWeatherWarningPopup(/g' lib/presentation/screens/main/main_screen.dart
echo -e "${GREEN}✅ _showWeatherPopup → MainScreenPopups.showWeatherWarningPopup${NC}"

# _showMarinPopup을 MainScreenPopups.showSubmarineWarningPopup으로 교체
sed -i 's/_showMarinPopup(/MainScreenPopups.showSubmarineWarningPopup(/g' lib/presentation/screens/main/main_screen.dart
echo -e "${GREEN}✅ _showMarinPopup → MainScreenPopups.showSubmarineWarningPopup${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 4: 팝업 함수 정의 제거${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# Python 스크립트로 함수 제거
cat > remove_functions.py << 'PYTHON_EOF'
import re

with open('lib/presentation/screens/main/main_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 제거할 함수들 패턴
functions_to_remove = [
    r'void _showRosPopup\(.*?\n  \}\n',
    r'void _showWeatherPopup\(.*?\n  \}\n', 
    r'void _showMarinPopup\(.*?\n  \}\n',
    r'void _showCustomPopuplive\(.*?\n  \}\n',
    r'void _showCustomPopup\(.*?\n  \}\n'
]

for pattern in functions_to_remove:
    content = re.sub(pattern, '', content, flags=re.DOTALL)

# 연속된 빈 줄 제거
content = re.sub(r'\n\n+', '\n\n', content)

with open('lib/presentation/screens/main/main_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("함수 제거 완료")
PYTHON_EOF

python3 remove_functions.py
rm -f remove_functions.py
echo -e "${GREEN}✅ 중복 팝업 함수들 제거${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 5: _warningPopOn 함수들 제거${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# _warningPopOn과 _warningPopOnDetail 함수 제거
cat > remove_warning_functions.py << 'PYTHON_EOF'
import re

with open('lib/presentation/screens/main/main_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Widget _warningPopOn 함수 제거
content = re.sub(r'Widget _warningPopOn\(.*?\n\}\n', '', content, flags=re.DOTALL)

# Widget _warningPopOnDetail 함수 제거  
content = re.sub(r'Widget _warningPopOnDetail\(.*?\n\}\n', '', content, flags=re.DOTALL)

with open('lib/presentation/screens/main/main_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("warning 함수 제거 완료")
PYTHON_EOF

python3 remove_warning_functions.py
rm -f remove_warning_functions.py
echo -e "${GREEN}✅ warning 함수들 제거${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 6: 팝업 호출 부분 수정${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# MainScreenPopups 호출에 추가 파라미터 전달
cat > fix_popup_calls.py << 'PYTHON_EOF'
import re

with open('lib/presentation/screens/main/main_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# showTurbineWarningPopup 호출 수정
content = re.sub(
    r'MainScreenPopups\.showTurbineWarningPopup\(context, (.*?), (.*?)\)',
    r'MainScreenPopups.showTurbineWarningPopup(context, \1, \2, () { _stopFlashing(); _popupService.hidePopup(PopupService.TURBINE_ENTRY_ALERT); })',
    content
)

# showWeatherWarningPopup 호출 수정
content = re.sub(
    r'MainScreenPopups\.showWeatherWarningPopup\(context, (.*?), (.*?)\)',
    r'MainScreenPopups.showWeatherWarningPopup(context, \1, \2, () { _stopFlashing(); _popupService.hidePopup(PopupService.WEATHER_ALERT); })',
    content
)

# showSubmarineWarningPopup 호출 수정
content = re.sub(
    r'MainScreenPopups\.showSubmarineWarningPopup\(context, (.*?), (.*?)\)',
    r'MainScreenPopups.showSubmarineWarningPopup(context, \1, \2, () { _stopFlashing(); _popupService.hidePopup(PopupService.SUBMARINE_CABLE_ALERT); })',
    content
)

with open('lib/presentation/screens/main/main_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("팝업 호출 수정 완료")
PYTHON_EOF

python3 fix_popup_calls.py
rm -f fix_popup_calls.py
echo -e "${GREEN}✅ 팝업 호출 부분 수정${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 7: 결과 확인${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 최종 라인 수
AFTER_LINES=$(wc -l < lib/presentation/screens/main/main_screen.dart)
REDUCED=$((BEFORE_LINES - AFTER_LINES))

echo -e "\n${GREEN}📊 정리 결과:${NC}"
echo -e "  • 시작: ${RED}$BEFORE_LINES${NC}줄"
echo -e "  • 종료: ${GREEN}$AFTER_LINES${NC}줄"
echo -e "  • 감소: ${YELLOW}$REDUCED${NC}줄 ($(( REDUCED * 100 / BEFORE_LINES ))%)"

# Flutter analyze
echo -e "\n${BLUE}Flutter analyze 실행 중...${NC}"
flutter analyze lib/presentation/screens/main/main_screen.dart | head -10

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ 대대적 정리 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}💡 다음 단계:${NC}"
echo "1. ${BLUE}flutter analyze${NC} - 전체 에러 확인"
echo "2. ${BLUE}flutter run${NC} - 실행 테스트"
echo "3. 팝업 기능 테스트 - 정상 작동 확인"

if [ $AFTER_LINES -gt 1500 ]; then
    echo -e "\n${YELLOW}추가 분리 가능한 부분:${NC}"
    echo "• FlutterMap 빌드 부분 → map_widget.dart 활용"
    echo "• BottomNavigationBar → 별도 위젯"
    echo "• routePop 함수 → 별도 파일"
fi

echo -e "\n${GREEN}완료!${NC}"
