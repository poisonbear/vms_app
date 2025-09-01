#!/bin/bash

echo "========================================="
echo "메모리 누수 체크 파일 검증"
echo "========================================="

# 1. 파일 존재 확인
echo ""
echo "1. 파일 존재 확인:"
if [ -f "lib/core/utils/memory_leak_checker.dart" ]; then
    echo "✅ memory_leak_checker.dart 파일 존재"
else
    echo "❌ memory_leak_checker.dart 파일 없음"
fi

if [ -f "lib/presentation/screens/example/memory_optimized_screen.dart" ]; then
    echo "✅ memory_optimized_screen.dart 예제 파일 존재"
else
    echo "❌ memory_optimized_screen.dart 예제 파일 없음"
fi

# 2. Flutter analyze 실행
echo ""
echo "2. Flutter analyze 실행:"
flutter analyze lib/core/utils/memory_leak_checker.dart

if [ $? -eq 0 ]; then
    echo "✅ 에러 없음"
else
    echo "❌ 에러 발견"
fi

# 3. import 확인
echo ""
echo "3. 필요한 import 확인:"
echo "memory_leak_checker.dart의 import:"
head -5 lib/core/utils/memory_leak_checker.dart

echo ""
echo "========================================="
echo "검증 완료"
echo "========================================="
