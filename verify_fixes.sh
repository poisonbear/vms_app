#!/bin/bash

echo "========================================="
echo "에러 수정 검증 중..."
echo "========================================="

# Flutter analyze 실행
echo ""
echo "Flutter analyze 실행 중..."
flutter analyze | grep -e "error"

if [ $? -eq 0 ]; then
    echo ""
    echo "⚠️  아직 에러가 남아있습니다."
else
    echo ""
    echo "✅ 모든 에러가 해결되었습니다!"
fi

# Warning 확인
echo ""
echo "Warning 확인 중..."
flutter analyze | grep -e "warning" | head -5

echo ""
echo "========================================="
echo "검증 완료"
echo "========================================="
