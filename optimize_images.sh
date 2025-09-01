#!/bin/bash

echo "========================================="
echo "이미지 최적화 작업"
echo "========================================="

# 1. 이미지 파일 목록 확인
echo ""
echo "📸 현재 이미지 파일들:"
find assets -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -exec ls -lh {} \; | awk '{print $9, $5}'

# 2. 큰 이미지 파일 찾기 (100KB 이상)
echo ""
echo "⚠️  최적화가 필요한 큰 이미지 파일 (100KB 이상):"
find assets -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -size +100k -exec ls -lh {} \;

# 3. 이미지 해상도별 폴더 구조 생성
echo ""
echo "📁 해상도별 폴더 구조 생성..."
mkdir -p assets/images/1.0x
mkdir -p assets/images/2.0x
mkdir -p assets/images/3.0x

# 4. WebP 변환 가이드
echo ""
echo "💡 WebP 변환 권장사항:"
echo "1. PNG 이미지를 WebP로 변환하면 50-70% 크기 감소"
echo "2. 변환 도구:"
echo "   - 온라인: https://squoosh.app/"
echo "   - CLI: cwebp input.png -o output.webp -q 80"
echo ""
echo "3. Flutter에서 WebP 사용:"
echo "   Image.asset('assets/images/logo.webp')"

# 5. 사용하지 않는 이미지 찾기
echo ""
echo "🔍 사용하지 않는 이미지 파일 검색..."
for file in assets/**/*.{png,jpg,jpeg,svg}; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if ! grep -r "$filename" lib/ --include="*.dart" > /dev/null 2>&1; then
            echo "  ❌ $file (사용되지 않음 - 삭제 가능)"
        fi
    fi
done 2>/dev/null

echo ""
echo "========================================="
echo "이미지 최적화 작업 완료"
echo "========================================="
