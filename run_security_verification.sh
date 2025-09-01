#!/bin/bash

echo "=== 보안 검증 시작 ==="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 코드 정리
echo "코드 정리 중..."
flutter clean
flutter pub get

# 2. 분석 실행
echo ""
echo "코드 분석 중..."
flutter analyze --no-fatal-warnings

# 3. 보안 테스트 실행
echo ""
echo "보안 테스트 실행 중..."
flutter test test/security/secure_api_test.dart

# 4. 결과 요약
echo ""
echo "========================================="
echo "           보안 검증 결과"
echo "========================================="

# 비밀번호 로깅 재검사
PASSWORD_LOGS=$(grep -r "password\|user_pwd" lib/ --include="*.dart" | grep -v "//" | grep -i "print\|log" | wc -l)
if [ "$PASSWORD_LOGS" -eq 0 ]; then
  echo -e "${GREEN}✅ 비밀번호 로깅: 없음${NC}"
else
  echo -e "${RED}❌ 비밀번호 로깅: ${PASSWORD_LOGS}건 발견${NC}"
fi

# API 하드코딩 검사
HARDCODED_URLS=$(grep -r "118\.40\.116\.129" lib/ --include="*.dart" | grep -v "secure" | wc -l)
if [ "$HARDCODED_URLS" -eq 0 ]; then
  echo -e "${GREEN}✅ API 하드코딩: 없음${NC}"
else
  echo -e "${YELLOW}⚠️  API 하드코딩: ${HARDCODED_URLS}건${NC}"
fi

# AppLogger 사용 검사
APPLOGGER_COUNT=$(grep -r "AppLogger\." lib/ --include="*.dart" | wc -l)
if [ "$APPLOGGER_COUNT" -gt 0 ]; then
  echo -e "${GREEN}✅ AppLogger 사용: ${APPLOGGER_COUNT}건${NC}"
else
  echo -e "${RED}❌ AppLogger 미사용${NC}"
fi

# ProGuard 확인
if grep -q "minifyEnabled true" android/app/build.gradle; then
  echo -e "${GREEN}✅ ProGuard: 활성화${NC}"
else
  echo -e "${YELLOW}⚠️  ProGuard: 비활성화${NC}"
fi

echo "========================================="
