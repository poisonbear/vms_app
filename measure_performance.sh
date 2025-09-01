#!/bin/bash

echo "========================================="
echo "Flutter 앱 성능 측정"
echo "========================================="

# 1. 앱 크기 측정
echo ""
echo "📦 앱 크기 측정..."
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "Release APK 크기: $APK_SIZE"
else
    echo "Release APK가 없습니다. 빌드를 먼저 실행하세요:"
    echo "flutter build apk --release"
fi

# 2. 번들 크기 분석
echo ""
echo "📊 번들 크기 분석..."
flutter build apk --analyze-size

# 3. 의존성 크기 확인
echo ""
echo "📚 의존성 크기 확인..."
flutter pub deps --json | python -c "
import json
import sys
data = json.load(sys.stdin)
packages = data.get('packages', [])
print(f'총 패키지 수: {len(packages)}')
for pkg in packages[:10]:
    print(f'  - {pkg.get(\"name\", \"unknown\")}: {pkg.get(\"version\", \"unknown\")}')
"

# 4. 사용하지 않는 리소스 찾기
echo ""
echo "🔍 사용하지 않는 리소스 검색..."
echo "assets 폴더의 이미지 중 코드에서 참조되지 않는 파일:"
for file in assets/**/*.{png,jpg,jpeg,svg}; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if ! grep -r "$filename" lib/ --include="*.dart" > /dev/null; then
            echo "  - $file (사용되지 않음)"
        fi
    fi
done

echo ""
echo "========================================="
echo "성능 측정 완료"
echo "========================================="
