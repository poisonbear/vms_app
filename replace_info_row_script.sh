#!/bin/bash

# _infoRow를 VesselInfoTable로 교체하는 스크립트
# 작성일: 2025-01-06

echo "======================================"
echo "📝 _infoRow → VesselInfoTable 교체"
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

# 백업 생성
BACKUP_FILE="lib/presentation/screens/main/main_screen.dart.backup_$(date +%Y%m%d_%H%M%S)"
cp lib/presentation/screens/main/main_screen.dart "$BACKUP_FILE"
echo -e "${GREEN}✅ 백업 생성: $BACKUP_FILE${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 1: _infoRow 함수 찾기${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# _infoRow 함수 위치 찾기
INFO_ROW_LINE=$(grep -n "TableRow _infoRow" lib/presentation/screens/main/main_screen.dart | cut -d: -f1)

if [ -n "$INFO_ROW_LINE" ]; then
    echo -e "${GREEN}✅ _infoRow 함수 발견: ${INFO_ROW_LINE}번 줄${NC}"
else
    echo -e "${YELLOW}⚠️  _infoRow 함수를 찾을 수 없습니다${NC}"
fi

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 2: routePop 함수 내 Table 교체${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# Python 스크립트로 복잡한 교체 작업 수행
cat > replace_table.py << 'PYTHON_EOF'
import re
import sys

def replace_table_with_widget(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Table 위젯을 VesselInfoTable로 교체하는 패턴
    # Table( ... children: [ _infoRow(...), ... ] ) 패턴을 찾아서 교체
    pattern = r'Table\s*\(\s*columnWidths:.*?\[(.*?)\],\s*\)'
    
    # 더 정확한 패턴: routePop 함수 내의 Table 찾기
    route_pop_pattern = r'(Future<void> routePop.*?{.*?)(Container\s*\(\s*child:\s*Table\s*\(.*?columnWidths:.*?children:\s*\[.*?_infoRow.*?\],\s*\),\s*\))'
    
    def replacement(match):
        before = match.group(1)
        # VesselInfoTable로 교체
        replacement_widget = '''Container(
                          child: VesselInfoTable(
                            shipName: vessel.ship_nm,
                            mmsi: vessel.mmsi,
                            vesselType: vessel.cd_nm,
                            draft: vessel.draft,
                            sog: vessel.sog,
                            cog: vessel.cog,
                          ),
                        )'''
        return before + replacement_widget
    
    # 먼저 백업 확인용 출력
    if re.search(route_pop_pattern, content, re.DOTALL):
        print("Table 위젯을 찾았습니다. 교체 중...")
        # 실제 교체
        content = re.sub(route_pop_pattern, replacement, content, flags=re.DOTALL)
        
        # 파일 저장
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("교체 완료!")
        return True
    else:
        print("routePop 함수 내 Table 위젯을 찾을 수 없습니다.")
        return False

if __name__ == "__main__":
    file_path = "lib/presentation/screens/main/main_screen.dart"
    if replace_table_with_widget(file_path):
        sys.exit(0)
    else:
        sys.exit(1)
PYTHON_EOF

# Python 스크립트 실행
python3 replace_table.py
PYTHON_RESULT=$?

if [ $PYTHON_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Table 위젯이 VesselInfoTable로 교체되었습니다${NC}"
else
    echo -e "${YELLOW}⚠️  자동 교체 실패. 수동 교체 필요${NC}"
    echo -e "\n${YELLOW}수동 교체 방법:${NC}"
    echo "1. routePop 함수 찾기 (약 265번 줄)"
    echo "2. Table( ... ) 부분을 다음으로 교체:"
    echo ""
    echo "VesselInfoTable("
    echo "  shipName: vessel.ship_nm,"
    echo "  mmsi: vessel.mmsi,"
    echo "  vesselType: vessel.cd_nm,"
    echo "  draft: vessel.draft,"
    echo "  sog: vessel.sog,"
    echo "  cog: vessel.cog,"
    echo ")"
fi

# Python 스크립트 삭제
rm -f replace_table.py

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 3: _infoRow 함수 제거${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# _infoRow 함수 제거 (함수 전체를 주석 처리)
if [ -n "$INFO_ROW_LINE" ]; then
    # _infoRow 함수의 시작과 끝 찾기
    START_LINE=$INFO_ROW_LINE
    # 함수 끝 찾기 (다음 함수 시작 또는 클래스 끝)
    END_LINE=$(awk "NR>$START_LINE && /^[[:space:]]*TableRow|^[[:space:]]*Future|^[[:space:]]*void|^[[:space:]]*Widget|^}[[:space:]]*$/ {print NR; exit}" lib/presentation/screens/main/main_screen.dart)
    
    if [ -n "$END_LINE" ]; then
        # 함수를 주석 처리
        sed -i "${START_LINE},${END_LINE}s/^/\/\/ /" lib/presentation/screens/main/main_screen.dart
        echo -e "${GREEN}✅ _infoRow 함수가 주석 처리되었습니다 (${START_LINE}-${END_LINE}번 줄)${NC}"
    else
        echo -e "${YELLOW}⚠️  _infoRow 함수 끝을 찾을 수 없습니다${NC}"
    fi
fi

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 4: Flutter Analyze 실행${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# Flutter analyze 실행
echo -e "\n${BLUE}분석 중...${NC}"
ANALYZE_OUTPUT=$(flutter analyze lib/presentation/screens/main/main_screen.dart 2>&1)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || true)

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ 에러 없음! 교체 성공${NC}"
else
    echo -e "${RED}❌ 에러 $ERROR_COUNT개 발견${NC}"
    echo "$ANALYZE_OUTPUT" | grep "error" | head -5
    
    echo -e "\n${YELLOW}💡 일반적인 문제 해결:${NC}"
    echo "1. import 확인:"
    echo "   import 'widgets/vessel_info_table.dart';"
    echo ""
    echo "2. vessel 변수 확인:"
    echo "   routePop 함수에서 vessel 파라미터가 제대로 전달되는지 확인"
    echo ""
    echo "3. 복구 방법:"
    echo "   cp $BACKUP_FILE lib/presentation/screens/main/main_screen.dart"
fi

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ _infoRow → VesselInfoTable 교체 작업 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}📝 다음 확인사항:${NC}"
echo "1. ${BLUE}flutter analyze${NC} - 에러 확인"
echo "2. ${BLUE}flutter run${NC} - 실행 테스트"
echo "3. 선박 정보 팝업 열어보기 - 정상 표시 확인"

echo -e "\n${GREEN}완료!${NC}"
