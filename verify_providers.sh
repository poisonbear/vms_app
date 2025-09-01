#!/bin/bash

echo "Provider 수정 검증 중..."
echo ""

# Flutter analyze 실행
echo "Flutter analyze 실행 중..."
flutter analyze | grep -e 'error.*provider' -i

if [ $? -eq 0 ]; then
    echo ""
    echo "⚠️  Provider 관련 에러가 발견되었습니다."
else
    echo ""
    echo "✅ Provider 관련 에러가 없습니다!"
fi

# 특정 파일들 검사
echo ""
echo "수정된 파일 확인:"
for file in lib/presentation/providers/terms/*.dart; do
    if grep -q "extends BaseProvider" "$file"; then
        echo "✅ $(basename $file) - BaseProvider 적용됨"
    else
        echo "❌ $(basename $file) - BaseProvider 미적용"
    fi
done
