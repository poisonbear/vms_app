#!/bin/bash

echo "========================================="
echo "     VMS 프로젝트 백업 파일 정리"
echo "========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 백업 디렉토리 생성
BACKUP_DIR="backup_archive_$(date +%Y%m%d_%H%M%S)"
TOTAL_SIZE=0
FILE_COUNT=0

# 1. 백업 파일 찾기
echo -e "${BLUE}[1/5] 백업 파일 검색 중...${NC}"
echo "----------------------------------------"

# 백업 파일 패턴들
BACKUP_PATTERNS=(
    "*.backup"
    "*.bak"
    "*_backup.*"
    "*_secure.*"
    "*_patch.*"
    "*_template.*"
    "*.dart.backup"
    "backup_*"
)

# 임시 파일에 백업 파일 목록 저장
TEMP_FILE="backup_files_list.txt"
> $TEMP_FILE

for pattern in "${BACKUP_PATTERNS[@]}"; do
    find . -name "$pattern" -type f 2>/dev/null | grep -v "node_modules\|.git\|build" >> $TEMP_FILE
done

# 중복 제거
sort -u $TEMP_FILE -o $TEMP_FILE

# 파일 개수 계산
FILE_COUNT=$(wc -l < $TEMP_FILE)

if [ $FILE_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ 정리할 백업 파일이 없습니다.${NC}"
    rm -f $TEMP_FILE
    exit 0
fi

echo -e "${YELLOW}📁 발견된 백업 파일: ${FILE_COUNT}개${NC}"
echo ""

# 2. 백업 파일 목록 표시
echo -e "${BLUE}[2/5] 백업 파일 목록${NC}"
echo "----------------------------------------"

# 카테고리별로 분류
echo -e "${YELLOW}📌 Dart 백업 파일:${NC}"
grep "\.dart\." $TEMP_FILE | head -10

echo ""
echo -e "${YELLOW}📌 패치/템플릿 파일:${NC}"
grep -E "_patch\.|_secure\.|_template\." $TEMP_FILE | head -10

echo ""
echo -e "${YELLOW}📌 기타 백업 파일:${NC}"
grep -vE "\.dart\.|_patch\.|_secure\.|_template\." $TEMP_FILE | head -10

if [ $FILE_COUNT -gt 30 ]; then
    echo ""
    echo -e "${YELLOW}... 외 $((FILE_COUNT - 30))개 파일${NC}"
fi

# 3. 전체 크기 계산
echo ""
echo -e "${BLUE}[3/5] 백업 파일 크기 계산${NC}"
echo "----------------------------------------"

while IFS= read -r file; do
    if [ -f "$file" ]; then
        size=$(du -b "$file" 2>/dev/null | cut -f1)
        TOTAL_SIZE=$((TOTAL_SIZE + size))
    fi
done < $TEMP_FILE

# 크기를 읽기 쉬운 형식으로 변환
if [ $TOTAL_SIZE -gt 1048576 ]; then
    SIZE_MB=$((TOTAL_SIZE / 1048576))
    echo -e "${YELLOW}📊 총 크기: ${SIZE_MB} MB${NC}"
elif [ $TOTAL_SIZE -gt 1024 ]; then
    SIZE_KB=$((TOTAL_SIZE / 1024))
    echo -e "${YELLOW}📊 총 크기: ${SIZE_KB} KB${NC}"
else
    echo -e "${YELLOW}📊 총 크기: ${TOTAL_SIZE} bytes${NC}"
fi

# 4. 사용자 확인
echo ""
echo -e "${BLUE}[4/5] 백업 파일 처리 옵션${NC}"
echo "----------------------------------------"
echo "1) 아카이브 폴더로 이동 (추천)"
echo "2) 완전 삭제"
echo "3) 취소"
echo ""
read -p "선택하세요 (1/2/3): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}✅ 아카이브 폴더로 이동 선택${NC}"
        
        # 아카이브 디렉토리 생성
        mkdir -p $BACKUP_DIR
        
        echo "백업 파일을 $BACKUP_DIR 로 이동 중..."
        
        # 파일별로 디렉토리 구조 유지하며 이동
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                # 원본 디렉토리 구조 유지
                dir=$(dirname "$file")
                mkdir -p "$BACKUP_DIR/$dir"
                mv "$file" "$BACKUP_DIR/$file" 2>/dev/null
                
                # 진행 상황 표시
                echo -n "."
            fi
        done < $TEMP_FILE
        
        echo ""
        echo -e "${GREEN}✅ 백업 파일이 $BACKUP_DIR 로 이동되었습니다.${NC}"
        
        # 아카이브 정보 파일 생성
        cat > "$BACKUP_DIR/README.txt" << EOF
========================================
VMS 프로젝트 백업 파일 아카이브
========================================
생성 일시: $(date)
파일 개수: $FILE_COUNT
총 크기: $((TOTAL_SIZE / 1024)) KB

이 폴더는 보안 강화 작업 중 생성된
백업 파일들을 보관하고 있습니다.

필요하지 않다면 이 폴더 전체를
안전하게 삭제하셔도 됩니다.
========================================
EOF
        
        echo ""
        echo -e "${YELLOW}💡 팁: 나중에 필요없다면 다음 명령으로 삭제하세요:${NC}"
        echo "   rm -rf $BACKUP_DIR"
        ;;
        
    2)
        echo ""
        echo -e "${RED}⚠️  경고: 백업 파일을 완전히 삭제합니다.${NC}"
        read -p "정말 삭제하시겠습니까? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            echo "백업 파일 삭제 중..."
            
            while IFS= read -r file; do
                if [ -f "$file" ]; then
                    rm -f "$file"
                    echo -n "."
                fi
            done < $TEMP_FILE
            
            echo ""
            echo -e "${GREEN}✅ 백업 파일이 삭제되었습니다.${NC}"
        else
            echo -e "${YELLOW}❌ 삭제가 취소되었습니다.${NC}"
        fi
        ;;
        
    3)
        echo -e "${YELLOW}❌ 작업이 취소되었습니다.${NC}"
        ;;
        
    *)
        echo -e "${RED}❌ 잘못된 선택입니다.${NC}"
        ;;
esac

# 5. 추가 정리 제안
echo ""
echo -e "${BLUE}[5/5] 추가 정리 제안${NC}"
echo "----------------------------------------"

# 테스트 관련 임시 파일 확인
TEST_FILES=$(find . -name "*_test_report.txt" -o -name "security_test_report.txt" 2>/dev/null | wc -l)
if [ $TEST_FILES -gt 0 ]; then
    echo -e "${YELLOW}📌 테스트 리포트 파일: ${TEST_FILES}개${NC}"
fi

# 빌드 캐시 확인
if [ -d "build" ]; then
    BUILD_SIZE=$(du -sh build 2>/dev/null | cut -f1)
    echo -e "${YELLOW}📌 빌드 캐시: ${BUILD_SIZE}${NC}"
    echo "   정리: flutter clean"
fi

# .gitignore 제안
echo ""
echo -e "${GREEN}💡 .gitignore에 추가 권장:${NC}"
cat << EOF
*.backup
*.bak
*_backup.*
*_secure.*
*_patch.*
*_template.*
backup_*/
backup_archive_*/
security_test_report.txt
*.dart.backup
EOF

# 임시 파일 삭제
rm -f $TEMP_FILE

echo ""
echo "========================================="
echo -e "${GREEN}          정리 완료!${NC}"
echo "========================================="
