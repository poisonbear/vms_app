#!/bin/bash

echo "=== AppLogger 타입 오류 수정 ==="
echo ""

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. load_location.dart 수정
echo "[1/3] load_location.dart 수정 중..."

# Position 타입 오류 수정 (line 196)
sed -i '196s/AppLogger\.d(currentPosition)/AppLogger.d("Current Position: \$currentPosition")/' lib/core/utils/load_location.dart

# Stream<Position> 타입 오류 수정 (line 322)
sed -i '322s/AppLogger\.d(positionStream)/AppLogger.d("Position Stream: \$positionStream")/' lib/core/utils/load_location.dart

echo "✅ load_location.dart 수정 완료"

# 2. login_screen.dart 수정
echo "[2/3] login_screen.dart 수정 중..."

# int? 타입 오류 수정 (line 126)
sed -i '126s/AppLogger\.d(mmsi)/AppLogger.d("MMSI: \$mmsi")/' lib/presentation/screens/auth/login_screen.dart

echo "✅ login_screen.dart 수정 완료"

# 3. 추가 타입 오류 검색 및 수정
echo "[3/3] 추가 타입 오류 검색 중..."

# AppLogger.d가 객체를 직접 받는 경우 찾기
PROBLEM_FILES=$(grep -rn "AppLogger\.[deiw]([^\"'\`]" lib/ --include="*.dart" | grep -v "\$" | cut -d: -f1 | sort -u)

if [ -n "$PROBLEM_FILES" ]; then
    echo -e "${YELLOW}추가 수정이 필요한 파일:${NC}"
    for file in $PROBLEM_FILES; do
        echo "  - $file"
    done
fi

echo ""
echo "=== ✅ 수정 완료 ==="
