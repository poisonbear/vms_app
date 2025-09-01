#!/bin/bash

echo "========================================="
echo "warningPopdetail 수정 검증"
echo "========================================="

# 1. 함수 정의 확인
echo ""
echo "1. warningPopdetail 함수 정의 확인:"
if grep -q "Future<void> warningPopdetail(" lib/core/network/dio_client.dart; then
    echo "✅ 함수 정의 있음"
    # 매개변수 개수 확인
    PARAMS=$(grep -A 8 "Future<void> warningPopdetail(" lib/core/network/dio_client.dart | grep -c "^\s*[A-Z]")
    echo "   매개변수 개수: $PARAMS"
else
    echo "❌ 함수 정의 없음"
fi

# 2. 함수 호출 확인
echo ""
echo "2. main_screen.dart에서 warningPopdetail 호출:"
grep -n "warningPopdetail(" lib/presentation/screens/main/main_screen.dart | head -3

# 3. Flutter analyze 실행
echo ""
echo "3. Flutter analyze 결과:"
flutter analyze | grep -e "warningPopdetail" -e "not_enough_positional_arguments"

if [ $? -ne 0 ]; then
    echo "✅ warningPopdetail 관련 에러 없음"
else
    echo "⚠️  아직 에러가 있습니다"
fi

echo ""
echo "========================================="
