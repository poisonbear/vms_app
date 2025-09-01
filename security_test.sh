#!/bin/bash

echo "========================================="
echo "   VMS 앱 보안 테스트 검증 스크립트"
echo "========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 테스트 결과 카운터
PASS=0
FAIL=0
WARN=0

# 1. 파일 존재 여부 확인
echo "=== [1/7] 보안 파일 존재 여부 확인 ==="
echo "----------------------------------------"

FILES_TO_CHECK=(
  "lib/core/security/secure_api_manager.dart"
  "lib/core/security/app_initializer.dart"
  "lib/core/utils/app_logger.dart"
  "lib/core/services/secure_api_service.dart"
  "android/app/proguard-rules.pro"
)

for file in "${FILES_TO_CHECK[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}✅ $file${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ $file (없음)${NC}"
    ((FAIL++))
  fi
done

echo ""

# 2. 민감한 정보 노출 검사
echo "=== [2/7] 민감한 정보 노출 검사 ==="
echo "------------------------------------"

# API URL 하드코딩 검사
echo "🔍 API URL 하드코딩 검사..."
HARDCODED_URLS=$(grep -r "118\.40\.116\.129" lib/ --include="*.dart" 2>/dev/null | grep -v "secure" | wc -l)
if [ "$HARDCODED_URLS" -eq 0 ]; then
  echo -e "${GREEN}✅ 하드코딩된 API URL 없음${NC}"
  ((PASS++))
else
  echo -e "${YELLOW}⚠️  하드코딩된 API URL 발견: ${HARDCODED_URLS}건${NC}"
  grep -r "118\.40\.116\.129" lib/ --include="*.dart" | grep -v "secure" | head -3
  ((WARN++))
fi

# 비밀번호 로깅 검사
echo "🔍 비밀번호 로깅 검사..."
PASSWORD_LOGS=$(grep -r "password\|user_pwd" lib/ --include="*.dart" | grep -i "print\|log" | wc -l)
if [ "$PASSWORD_LOGS" -eq 0 ]; then
  echo -e "${GREEN}✅ 비밀번호 로깅 없음${NC}"
  ((PASS++))
else
  echo -e "${RED}❌ 비밀번호 로깅 발견: ${PASSWORD_LOGS}건${NC}"
  ((FAIL++))
fi

echo ""

# 3. 로그 시스템 검사
echo "=== [3/7] 로그 시스템 검사 ==="
echo "-------------------------------"

PRINT_COUNT=$(grep -r "print(" lib/ --include="*.dart" 2>/dev/null | wc -l)
APPLOGGER_COUNT=$(grep -r "AppLogger\." lib/ --include="*.dart" 2>/dev/null | wc -l)

echo "📊 로그 사용 통계:"
echo "   print() 사용: ${PRINT_COUNT}건"
echo "   AppLogger 사용: ${APPLOGGER_COUNT}건"

if [ "$APPLOGGER_COUNT" -gt 0 ]; then
  echo -e "${GREEN}✅ AppLogger 사용 중${NC}"
  ((PASS++))
else
  echo -e "${RED}❌ AppLogger 미사용${NC}"
  ((FAIL++))
fi

if [ "$PRINT_COUNT" -lt 50 ]; then
  echo -e "${GREEN}✅ print() 사용 최소화됨${NC}"
  ((PASS++))
else
  echo -e "${YELLOW}⚠️  print() 과다 사용: ${PRINT_COUNT}건${NC}"
  ((WARN++))
fi

echo ""

# 4. ProGuard 설정 확인
echo "=== [4/7] ProGuard 설정 확인 ==="
echo "---------------------------------"

if [ -f "android/app/build.gradle" ]; then
  MINIFY_ENABLED=$(grep "minifyEnabled true" android/app/build.gradle | wc -l)
  if [ "$MINIFY_ENABLED" -gt 0 ]; then
    echo -e "${GREEN}✅ ProGuard 난독화 활성화${NC}"
    ((PASS++))
  else
    echo -e "${YELLOW}⚠️  ProGuard 난독화 비활성화${NC}"
    ((WARN++))
  fi
fi

echo ""

# 5. 보안 초기화 확인
echo "=== [5/7] 보안 초기화 확인 ==="
echo "-------------------------------"

if grep -q "AppInitializer.initializeSecurity" lib/main.dart 2>/dev/null; then
  echo -e "${GREEN}✅ main.dart에 보안 초기화 있음${NC}"
  ((PASS++))
else
  echo -e "${RED}❌ main.dart에 보안 초기화 없음${NC}"
  echo "   → main.dart에 다음 코드 추가 필요:"
  echo "     await AppInitializer.initializeSecurity();"
  ((FAIL++))
fi

echo ""

# 6. Git 보안 확인
echo "=== [6/7] Git 보안 확인 ==="
echo "---------------------------"

if [ -f ".gitignore" ]; then
  echo "🔍 .gitignore 확인 중..."
  
  # google-services.json 확인
  if grep -q "google-services.json" .gitignore; then
    echo -e "${GREEN}✅ google-services.json이 .gitignore에 포함됨${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ google-services.json이 .gitignore에 없음${NC}"
    ((FAIL++))
  fi
  
  # .env 파일 확인
  if grep -q "\.env" .gitignore; then
    echo -e "${GREEN}✅ .env 파일이 .gitignore에 포함됨${NC}"
    ((PASS++))
  else
    echo -e "${YELLOW}⚠️  .env 파일이 .gitignore에 없음${NC}"
    ((WARN++))
  fi
fi

echo ""

# 7. 유닛 테스트 실행
echo "=== [7/7] 보안 테스트 실행 ==="
echo "------------------------------"

if [ -f "test/security/secure_api_test.dart" ]; then
  echo "🧪 보안 유닛 테스트 실행 중..."
  flutter test test/security/secure_api_test.dart --reporter compact
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 보안 테스트 통과${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ 보안 테스트 실패${NC}"
    ((FAIL++))
  fi
else
  echo -e "${YELLOW}⚠️  보안 테스트 파일 없음${NC}"
  ((WARN++))
fi

echo ""
echo "========================================="
echo "            테스트 결과 요약"
echo "========================================="
echo -e "${GREEN}✅ 통과: ${PASS}개${NC}"
echo -e "${YELLOW}⚠️  경고: ${WARN}개${NC}"
echo -e "${RED}❌ 실패: ${FAIL}개${NC}"
echo ""

# 보안 등급 평가
TOTAL=$((PASS + WARN + FAIL))
SCORE=$((PASS * 100 / TOTAL))

echo "보안 점수: ${SCORE}/100"
echo -n "보안 등급: "

if [ $SCORE -ge 90 ]; then
  echo -e "${GREEN}A (우수)${NC} 🏆"
elif [ $SCORE -ge 70 ]; then
  echo -e "${GREEN}B (양호)${NC} ✨"
elif [ $SCORE -ge 50 ]; then
  echo -e "${YELLOW}C (보통)${NC} 📈"
elif [ $SCORE -ge 30 ]; then
  echo -e "${YELLOW}D (미흡)${NC} ⚠️"
else
  echo -e "${RED}F (위험)${NC} 🚨"
fi

echo ""
echo "========================================="

# 개선 제안
if [ $FAIL -gt 0 ]; then
  echo ""
  echo "📋 필수 개선 사항:"
  
  if ! grep -q "AppInitializer.initializeSecurity" lib/main.dart 2>/dev/null; then
    echo "  1. main.dart에 보안 초기화 추가"
  fi
  
  if [ "$HARDCODED_URLS" -gt 0 ]; then
    echo "  2. 하드코딩된 API URL을 SecureApiService로 변경"
  fi
  
  if [ "$PASSWORD_LOGS" -gt 0 ]; then
    echo "  3. 비밀번호 로깅 제거"
  fi
  
  echo ""
fi

# 상세 리포트 생성
cat > security_test_report.txt << EOF
===========================================
    VMS 앱 보안 테스트 리포트
    생성 시간: $(date)
===========================================

1. 파일 구조 검사
-----------------
$(for file in "${FILES_TO_CHECK[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file"
  else
    echo "❌ $file (없음)"
  fi
done)

2. 코드 보안 검사
-----------------
- 하드코딩된 API URL: ${HARDCODED_URLS}건
- 비밀번호 로깅: ${PASSWORD_LOGS}건
- print() 사용: ${PRINT_COUNT}건
- AppLogger 사용: ${APPLOGGER_COUNT}건

3. 빌드 설정
------------
- ProGuard: $([ "$MINIFY_ENABLED" -gt 0 ] && echo "활성화" || echo "비활성화")
- 보안 초기화: $(grep -q "AppInitializer" lib/main.dart && echo "설정됨" || echo "미설정")

4. 테스트 결과
--------------
통과: ${PASS}개
경고: ${WARN}개
실패: ${FAIL}개

보안 점수: ${SCORE}/100
보안 등급: $(
  if [ $SCORE -ge 90 ]; then echo "A (우수)"
  elif [ $SCORE -ge 70 ]; then echo "B (양호)"
  elif [ $SCORE -ge 50 ]; then echo "C (보통)"
  elif [ $SCORE -ge 30 ]; then echo "D (미흡)"
  else echo "F (위험)"
  fi
)

===========================================
EOF

echo "📄 상세 리포트가 security_test_report.txt에 저장되었습니다."
