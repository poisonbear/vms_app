#!/bin/bash

echo "=== print() 문 검사 스크립트 ==="
echo "검사 시간: $(date +%H:%M:%S)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 전체 print() 개수 확인
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 전체 통계"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 주석 처리되지 않은 print() 찾기
TOTAL_PRINTS=$(grep -r "print(" lib/ --include="*.dart" | grep -v "//" | wc -l)
COMMENTED_PRINTS=$(grep -r "//.*print(" lib/ --include="*.dart" | wc -l)
ALL_PRINTS=$(grep -r "print(" lib/ --include="*.dart" | wc -l)

echo "전체 print() 발견: ${ALL_PRINTS}건"
echo "활성 print(): ${TOTAL_PRINTS}건"
echo "주석 처리된 print(): ${COMMENTED_PRINTS}건"

if [ "$TOTAL_PRINTS" -eq 0 ]; then
    echo -e "${GREEN}✅ 활성 print() 문이 없습니다!${NC}"
    echo ""
    echo "프로젝트가 깨끗합니다! 🎉"
    exit 0
fi

echo ""
echo -e "${YELLOW}⚠️ ${TOTAL_PRINTS}개의 print() 문이 발견되었습니다${NC}"

# 파일별 상세 내역
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 파일별 print() 사용 현황"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# print()가 있는 파일 목록
FILES_WITH_PRINT=$(grep -rl "print(" lib/ --include="*.dart" | while read file; do
    COUNT=$(grep "print(" "$file" | grep -v "//" | wc -l)
    if [ "$COUNT" -gt 0 ]; then
        echo "$file:$COUNT"
    fi
done | sort -t: -k2 -rn)

if [ ! -z "$FILES_WITH_PRINT" ]; then
    echo ""
    echo "파일명 | print() 개수"
    echo "--------------------------------"
    echo "$FILES_WITH_PRINT" | while IFS=: read -r file count; do
        printf "%-50s | %s건\n" "$file" "$count"
    done
fi

# 상세 위치 표시
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 print() 문 위치 (상위 10개)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

grep -rn "print(" lib/ --include="*.dart" | grep -v "//" | head -10 | while IFS=: read -r file line content; do
    echo ""
    echo -e "${BLUE}파일:${NC} $file"
    echo -e "${YELLOW}라인:${NC} $line"
    echo -e "${RED}내용:${NC} $(echo "$content" | sed 's/^[[:space:]]*//')"
done

# AppLogger 사용 통계
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 AppLogger 사용 통계"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

APPLOGGER_COUNT=$(grep -r "AppLogger\." lib/ --include="*.dart" | wc -l)
echo "AppLogger 사용: ${APPLOGGER_COUNT}건"

# 권장사항
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 권장사항"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TOTAL_PRINTS" -gt 0 ]; then
    echo "1. print() 문을 AppLogger로 변환하세요:"
    echo "   - print('message') → AppLogger.d('message')"
    echo "   - print(variable) → AppLogger.d(variable.toString())"
    echo ""
    echo "2. 자동 변환 스크립트 실행:"
    echo "   ./complete_print_to_applogger_migration.sh"
    echo ""
    echo "3. 특정 파일만 수정:"
    echo "   sed -i 's/print(/AppLogger.d(/g' [파일명]"
fi

# CSV 리포트 생성 옵션
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 상세 리포트 생성"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > print_report.txt << EOF
print() 문 검사 리포트
생성 시간: $(date)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

총 print() 문: ${TOTAL_PRINTS}개
주석 처리된 print(): ${COMMENTED_PRINTS}개
AppLogger 사용: ${APPLOGGER_COUNT}개

파일별 상세 내역:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$(echo "$FILES_WITH_PRINT")

상세 위치:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$(grep -rn "print(" lib/ --include="*.dart" | grep -v "//")
EOF

echo -e "${GREEN}✅ print_report.txt 파일이 생성되었습니다${NC}"

# 요약
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 요약"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TOTAL_PRINTS" -eq 0 ]; then
    echo -e "${GREEN}✅ 프로젝트에 print() 문이 없습니다!${NC}"
elif [ "$TOTAL_PRINTS" -lt 10 ]; then
    echo -e "${YELLOW}⚠️ ${TOTAL_PRINTS}개의 print() 문 발견 - 정리 권장${NC}"
else
    echo -e "${RED}❌ ${TOTAL_PRINTS}개의 print() 문 발견 - 즉시 정리 필요${NC}"
fi

echo ""
echo "완료 시간: $(date +%H:%M:%S)"
