#!/bin/bash

echo "=== load_location.dart 완전 수정 ==="
echo ""

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 백업 생성
echo "백업 생성 중..."
cp lib/core/utils/load_location.dart lib/core/utils/load_location.dart.complete_fix_backup

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 AppLogger import 추가"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# AppLogger import 추가 (geolocator import 다음에 추가)
if ! grep -q "import 'package:vms_app/core/utils/app_logger.dart';" lib/core/utils/load_location.dart; then
    # geolocator import 다음 줄에 AppLogger import 추가
    sed -i "/import 'package:geolocator\/geolocator.dart';/a import 'package:vms_app/core/utils/app_logger.dart';" lib/core/utils/load_location.dart
    echo -e "${GREEN}✅ AppLogger import 추가 완료${NC}"
else
    echo -e "${YELLOW}ℹ️ AppLogger import가 이미 존재합니다${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 print() → AppLogger 변환"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Python 스크립트로 정확한 라인 수정
cat > fix_prints.py << 'EOF'
#!/usr/bin/env python3
import re

# 파일 읽기
with open('lib/core/utils/load_location.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 수정 카운터
modified = 0

# 각 라인 검사 및 수정
for i, line in enumerate(lines):
    original_line = line
    
    # AppLogger가 이미 있는 라인은 건너뛰기
    if 'AppLogger' in line:
        continue
    
    # print() 문 찾기 및 변환
    if 'print(' in line and '//' not in line[:line.find('print(') if 'print(' in line else 0]:
        # 들여쓰기 유지
        indent = len(line) - len(line.lstrip())
        
        # 다양한 print 패턴 처리
        if "print('위치 권한이 없습니다.');" in line:
            lines[i] = ' ' * indent + "AppLogger.d('위치 권한이 없습니다.');\n"
            modified += 1
            print(f"✅ Line {i+1}: print → AppLogger.d")
            
        elif "print('현재 위치 - 위도:" in line:
            lines[i] = line.replace('print(', 'AppLogger.d(')
            modified += 1
            print(f"✅ Line {i+1}: print → AppLogger.d")
            
        elif "print('반환할 위치값');" in line:
            lines[i] = ' ' * indent + "AppLogger.d('반환할 위치값');\n"
            modified += 1
            print(f"✅ Line {i+1}: print → AppLogger.d")
            
        elif "print(position);" in line:
            # Position 객체를 문자열로 변환
            lines[i] = ' ' * indent + "AppLogger.d('Position: lat=\${position.latitude}, lng=\${position.longitude}');\n"
            modified += 1
            print(f"✅ Line {i+1}: print(position) → AppLogger.d (객체 변환)")
            
        elif "print('실시간 위치 업데이트" in line:
            lines[i] = line.replace('print(', 'AppLogger.d(')
            modified += 1
            print(f"✅ Line {i+1}: print → AppLogger.d")
            
        elif "print('실시간 좌표');" in line:
            lines[i] = ' ' * indent + "AppLogger.d('실시간 좌표');\n"
            modified += 1
            print(f"✅ Line {i+1}: print → AppLogger.d")
            
        elif "print(_geolocatorPlatform.getPositionStream());" in line:
            # Stream 객체를 문자열로 변환
            lines[i] = ' ' * indent + "AppLogger.d('Position stream started');\n"
            modified += 1
            print(f"✅ Line {i+1}: print(stream) → AppLogger.d (Stream 변환)")
            
        else:
            # 기타 print() 문
            lines[i] = line.replace('print(', 'AppLogger.d(')
            modified += 1
            print(f"✅ Line {i+1}: print → AppLogger.d")

# 파일 저장
with open('lib/core/utils/load_location.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print(f"\n총 {modified}개의 print() 문을 수정했습니다.")
EOF

python3 fix_prints.py
rm fix_prints.py

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 검증"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# import 확인
echo "1. Import 확인:"
if grep -q "import 'package:vms_app/core/utils/app_logger.dart';" lib/core/utils/load_location.dart; then
    echo -e "${GREEN}✅ AppLogger import 존재${NC}"
else
    echo -e "${RED}❌ AppLogger import 누락${NC}"
fi

# 남은 print() 확인
echo ""
echo "2. 남은 print() 문 확인:"
REMAINING_PRINTS=$(grep -c "print(" lib/core/utils/load_location.dart 2>/dev/null || echo "0")

if [ "$REMAINING_PRINTS" == "0" ]; then
    echo -e "${GREEN}✅ 모든 print() 문이 제거되었습니다!${NC}"
else
    echo -e "${YELLOW}⚠️ ${REMAINING_PRINTS}개의 print() 문이 남아있습니다:${NC}"
    grep -n "print(" lib/core/utils/load_location.dart | grep -v "//"
fi

# AppLogger 사용 확인
echo ""
echo "3. AppLogger 사용 확인:"
APPLOGGER_COUNT=$(grep -c "AppLogger\." lib/core/utils/load_location.dart 2>/dev/null || echo "0")
echo "AppLogger 사용: ${APPLOGGER_COUNT}개"

# Flutter 분석
echo ""
echo "4. Flutter 분석:"
flutter analyze lib/core/utils/load_location.dart --no-fatal-warnings 2>&1 | grep -E "error|warning" | head -10

ERROR_COUNT=$(flutter analyze lib/core/utils/load_location.dart --no-fatal-warnings 2>&1 | grep -c "error" || echo "0")

if [ "$ERROR_COUNT" == "0" ]; then
    echo -e "${GREEN}✅ 컴파일 오류 없음${NC}"
else
    echo -e "${RED}❌ ${ERROR_COUNT}개의 오류 발견${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 전체 프로젝트 상태"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL_PRINTS=$(grep -r "print(" lib/ --include="*.dart" | grep -v "//" | wc -l)
TOTAL_APPLOGGER=$(grep -r "AppLogger\." lib/ --include="*.dart" | wc -l)

echo "전체 print() 남은 개수: ${TOTAL_PRINTS}개"
echo "전체 AppLogger 사용: ${TOTAL_APPLOGGER}개"

if [ "$TOTAL_PRINTS" -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 축하합니다! 프로젝트에서 모든 print() 문이 제거되었습니다!${NC}"
else
    echo ""
    echo "남은 print() 위치:"
    grep -rn "print(" lib/ --include="*.dart" | grep -v "//" | head -5
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 수정 완료"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "백업 파일: lib/core/utils/load_location.dart.complete_fix_backup"
echo ""
