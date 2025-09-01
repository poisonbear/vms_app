#!/bin/bash

echo "========================================="
echo "성능 최적화 에러 수정 검증"
echo "========================================="

# 1. 파일 존재 확인
echo ""
echo "1. 필수 파일 확인:"

if [ -f "lib/core/cache/cache_manager.dart" ]; then
    echo "✅ cache_manager.dart 존재"
else
    echo "❌ cache_manager.dart 없음"
fi

if [ -f "lib/presentation/widgets/common/optimized_widgets.dart" ]; then
    echo "✅ optimized_widgets.dart 존재"
else
    echo "❌ optimized_widgets.dart 없음"
fi

# 2. Flutter analyze 실행
echo ""
echo "2. Flutter analyze 실행:"
flutter analyze lib/core/cache/cache_manager.dart 2>&1 | grep -E "error|warning" || echo "✅ cache_manager.dart 에러 없음"
flutter analyze lib/presentation/widgets/common/optimized_widgets.dart 2>&1 | grep -E "error|warning" || echo "✅ optimized_widgets.dart 에러 없음"

# 3. Import 확인
echo ""
echo "3. Import 체크:"
echo "vessel_remote_datasource_cached.dart의 cache_manager import:"
grep "cache_manager" lib/data/datasources/remote/vessel_remote_datasource_cached.dart 2>/dev/null || echo "파일 없음"

# 4. 전체 에러 확인
echo ""
echo "4. 전체 에러 확인:"
flutter analyze | grep -E "error.*cache_manager|error.*optimized_widgets|recursive_compile_time"

if [ $? -ne 0 ]; then
    echo "✅ 관련 에러 없음"
fi

echo ""
echo "========================================="
echo "검증 완료"
echo "========================================="
