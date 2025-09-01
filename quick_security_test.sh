#!/bin/bash

echo "=== 빠른 보안 검증 (30초 이내) ==="
echo "시작 시간: $(date +%H:%M:%S)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

# 1. 파일 검사 (1초)
echo "[1/5] 보안 파일 확인..."
if [ -f "lib/core/security/secure_api_manager.dart" ] && 
   [ -f "lib/core/utils/app_logger.dart" ] && 
   [ -f "android/app/proguard-rules.pro" ]; then
    echo -e "${GREEN}✅ 필수 보안 파일 존재${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ 보안 파일 누락${NC}"
    ((FAIL++))
fi

# 2. 비밀번호 로깅 검사 (2초)
echo ""
echo "[2/5] 비밀번호 로깅 검사..."
PASSWORD_LOGS=$(grep -r "password\|user_pwd" lib/ --include="*.dart" 2>/dev/null | grep -v "//" | grep -i "print\|log" | wc -l)
if [ "$PASSWORD_LOGS" -eq 0 ]; then
    echo -e "${GREEN}✅ 비밀번호 로깅 없음${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ 비밀번호 로깅 ${PASSWORD_LOGS}건 발견${NC}"
    echo "위치:"
    grep -r "password\|user_pwd" lib/ --include="*.dart" | grep -v "//" | grep -i "print\|log" | head -3
    ((FAIL++))
fi

# 3. API 하드코딩 검사 (2초)
echo ""
echo "[3/5] API 하드코딩 검사..."
HARDCODED=$(grep -r "118\.40\.116\.129" lib/ --include="*.dart" 2>/dev/null | grep -v "secure" | wc -l)
if [ "$HARDCODED" -eq 0 ]; then
    echo -e "${GREEN}✅ API 하드코딩 없음${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠️  API 하드코딩 ${HARDCODED}건${NC}"
    ((WARN++))
fi

# 4. 로그 시스템 검사 (1초)
echo ""
echo "[4/5] 로그 시스템 검사..."
PRINT_COUNT=$(grep -r "print(" lib/ --include="*.dart" 2>/dev/null | wc -l)
APPLOGGER_COUNT=$(grep -r "AppLogger\." lib/ --include="*.dart" 2>/dev/null | wc -l)

echo "   print() 사용: ${PRINT_COUNT}건"
echo "   AppLogger 사용: ${APPLOGGER_COUNT}건"

if [ "$APPLOGGER_COUNT" -gt 20 ]; then
    echo -e "${GREEN}✅ AppLogger 적극 사용 중${NC}"
    ((PASS++))
elif [ "$APPLOGGER_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  AppLogger 부분 사용${NC}"
    ((WARN++))
else
    echo -e "${RED}❌ AppLogger 미사용${NC}"
    ((FAIL++))
fi

# 5. 빌드 설정 검사 (1초)
echo ""
echo "[5/5] 빌드 설정 검사..."
if grep -q "minifyEnabled true" android/app/build.gradle 2>/dev/null; then
    echo -e "${GREEN}✅ ProGuard 난독화 활성화${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠️  ProGuard 난독화 비활성화${NC}"
    ((WARN++))
fi

# 결과 출력
echo ""
echo "========================================="
echo "         빠른 보안 검증 결과"
echo "========================================="
echo -e "${GREEN}통과: ${PASS}개${NC}"
echo -e "${YELLOW}경고: ${WARN}개${NC}"
echo -e "${RED}실패: ${FAIL}개${NC}"

# 점수 계산
TOTAL=$((PASS + WARN + FAIL))
if [ $TOTAL -gt 0 ]; then
    SCORE=$((PASS * 100 / TOTAL))
else
    SCORE=0
fi

echo ""
echo "보안 점수: ${SCORE}/100"
echo -n "보안 등급: "

if [ $SCORE -ge 80 ]; then
    echo -e "${GREEN}A (우수)${NC} 🏆"
elif [ $SCORE -ge 60 ]; then
    echo -e "${GREEN}B (양호)${NC} ✨"
elif [ $SCORE -ge 40 ]; then
    echo -e "${YELLOW}C (보통)${NC} 📈"
else
    echo -e "${RED}D (개선 필요)${NC} ⚠️"
fi

echo "========================================="
echo "완료 시간: $(date +%H:%M:%S)"
echo ""

# 개선 제안
if [ "$FAIL" -gt 0 ] || [ "$WARN" -gt 0 ]; then
    echo "📋 개선 제안:"
    
    if [ "$PASSWORD_LOGS" -gt 0 ]; then
        echo "  1. 비밀번호 로깅 제거 필요"
        echo "     → grep -r 'password' lib/ 로 위치 확인"
    fi
    
    if [ "$PRINT_COUNT" -gt 50 ]; then
        echo "  2. print()를 AppLogger로 교체"
        echo "     → 릴리즈 빌드에서 자동 제거됨"
    fi
    
    if [ "$HARDCODED" -gt 0 ]; then
        echo "  3. 하드코딩된 API를 SecureApiService로 이동"
    fi
fi
