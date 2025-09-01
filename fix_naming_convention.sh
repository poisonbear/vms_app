#!/bin/bash

echo "네이밍 컨벤션 수정 중..."

# CmdList -> cmdList 변경
find lib -name "*.dart" -type f -exec sed -i 's/CmdList/cmdList/g' {} \;

# RosList -> rosList 변경  
find lib -name "*.dart" -type f -exec sed -i 's/RosList/rosList/g' {} \;

# 기타 대문자로 시작하는 변수명 찾기
echo ""
echo "대문자로 시작하는 변수명 검색 중..."
grep -r "^\s*[A-Z][a-zA-Z]*\s*=" lib --include="*.dart" | grep -v "class\|static\|const"

echo "✅ 네이밍 컨벤션 수정 완료"
