#!/bin/bash

echo "========================================="
echo "코드 품질 검사 시작"
echo "========================================="

# 1. Flutter analyze
echo ""
echo "1. Flutter Analyze 실행 중..."
flutter analyze --no-fatal-infos

# 2. 하드코딩된 값 검색
echo ""
echo "2. 하드코딩된 값 검색 중..."
echo "   - 타임아웃 값:"
grep -r "Duration(seconds: [0-9]\+)" lib --include="*.dart" | grep -v "constants"

echo "   - 하드코딩된 크기:"
grep -r "[0-9]\{2,\}\.0\|[0-9]\{2,\}\.toDouble()" lib --include="*.dart" | grep -v "constants"

# 3. TODO/FIXME 검색
echo ""
echo "3. TODO/FIXME 코멘트:"
grep -r "TODO\|FIXME" lib --include="*.dart"

# 4. 빈 catch 블록 검색
echo ""
echo "4. 빈 catch 블록 검색:"
grep -A 1 "catch.*{$" lib -r --include="*.dart" | grep -B 1 "^[[:space:]]*}$"

# 5. print 문 검색
echo ""
echo "5. print 문 검색 (logger 사용 권장):"
grep -r "print(" lib --include="*.dart"

echo ""
echo "========================================="
echo "코드 품질 검사 완료"
echo "========================================="
