#!/bin/bash

echo "=== load_location.dart print() 문 제거 ==="
echo ""

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 백업 생성
echo "백업 생성 중..."
cp lib/core/utils/load_location.dart lib/core/utils/load_location.dart.print_fix_backup

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 print() → AppLogger 변환"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Line 174: print('위치 권한이 없습니다.')
sed -i "174s/print('위치 권한이 없습니다.');/AppLogger.d('위치 권한이 없습니다.');/" lib/core/utils/load_location.dart
echo "✅ Line 174 수정"

# Line 182: print('현재 위치 - 위도: ${position.latitude}, 경도: ${position.longitude}')
sed -i "182s/print('현재 위치 - 위도: \${position.latitude}, 경도: \${position.longitude}');/AppLogger.d('현재 위치 - 위도: \${position.latitude}, 경도: \${position.longitude}');/" lib/core/utils/load_location.dart
echo "✅ Line 182 수정"

# Line 190: print('반환할 위치값')
sed -i "190s/print('반환할 위치값');/AppLogger.d('반환할 위치값');/" lib/core/utils/load_location.dart
echo "✅ Line 190 수정"

# Line 191: print(position) - Position 객체를 문자열로 변환
sed -i "191s/print(position);/AppLogger.d('Position: lat=\${position.latitude}, lng=\${position.longitude}');/" lib/core/utils/load_location.dart
echo "✅ Line 191 수정 (Position 객체 처리)"

# Line 301: print('실시간 위치 업데이트 - 위도: ${position.latitude}, 경도: ${position.longitude}')
sed -i "301s/print('실시간 위치 업데이트 - 위도: \${position.latitude}, 경도: \${position.longitude}');/AppLogger.d('실시간 위치 업데이트 - 위도: \${position.latitude}, 경도: \${position.longitude}');/" lib/core/utils/load_location.dart
echo "✅ Line 301 수정"

# Line 316: print('실시간 좌표')
sed -i "316s/print('실시간 좌표');/AppLogger.d('실시간 좌표');/" lib/core/utils/load_location.dart
echo "✅ Line 316 수정"

# Line 317: print(_geolocatorPlatform.getPositionStream()) - Stream 객체를 문자열로 변환
sed -i "317s/print(_geolocatorPlatform.getPositionStream());/AppLogger.d('Position stream started');/" lib/core/utils/load_location.dart
echo "✅ Line 317 수정 (Stream 객체 처리)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 검증"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 남은 print() 확인
REMAINING_PRINTS=$(grep -c "print(" lib/core/utils/load_location.dart | grep -v "//")

if [ "$REMAINING_PRINTS" == "0" ]; then
    echo -e "${GREEN}✅ load_location.dart의 모든 print() 문이 제거되었습니다!${NC}"
else
    echo -e "${YELLOW}⚠️ 아직 ${REMAINING_PRINTS}개의 print() 문이 남아있습니다${NC}"
    echo "남은 print() 위치:"
    grep -n "print(" lib/core/utils/load_location.dart | grep -v "//"
fi

# 타입 오류 확인
echo ""
echo "타입 오류 확인 중..."
flutter analyze lib/core/utils/load_location.dart --no-fatal-warnings 2>&1 | grep "error" | head -5

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 변환 완료"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "백업 파일: lib/core/utils/load_location.dart.print_fix_backup"
echo ""

# 전체 프로젝트 print() 상태
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
fi
