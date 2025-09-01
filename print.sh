#!/bin/bash

echo "========================================="
echo "    print() → AppLogger 통일 작업"
echo "========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 백업 디렉토리 생성
BACKUP_DIR="backup_print_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# 1. 현재 상태 분석
echo -e "${BLUE}[1/6] 현재 로그 사용 현황 분석${NC}"
echo "----------------------------------------"

# print() 사용 파일 찾기
PRINT_FILES=$(grep -rl "print(" lib/ --include="*.dart" 2>/dev/null | grep -v "app_logger.dart")
PRINT_COUNT=$(echo "$PRINT_FILES" | wc -l)
PRINT_TOTAL=$(grep -r "print(" lib/ --include="*.dart" 2>/dev/null | wc -l)

echo -e "${YELLOW}📊 현재 상태:${NC}"
echo "   - print() 사용: ${PRINT_TOTAL}건 (${PRINT_COUNT}개 파일)"
echo "   - AppLogger 사용: $(grep -r "AppLogger\." lib/ --include="*.dart" | wc -l)건"
echo ""

# 2. print문 카테고리 분석
echo -e "${BLUE}[2/6] print문 카테고리 분석${NC}"
echo "----------------------------------------"

# 카테고리별 분류
DEBUG_PRINTS=$(grep -r "print.*[Dd]ebug\|print.*로그\|print.*테스트" lib/ --include="*.dart" 2>/dev/null | wc -l)
ERROR_PRINTS=$(grep -r "print.*[Ee]rror\|print.*오류\|print.*실패" lib/ --include="*.dart" 2>/dev/null | wc -l)
INFO_PRINTS=$(grep -r "print.*성공\|print.*완료\|print.*시작" lib/ --include="*.dart" 2>/dev/null | wc -l)
WARNING_PRINTS=$(grep -r "print.*경고\|print.*[Ww]arning" lib/ --include="*.dart" 2>/dev/null | wc -l)

echo "   🐛 Debug 성격: ${DEBUG_PRINTS}건"
echo "   ❌ Error 성격: ${ERROR_PRINTS}건"
echo "   ℹ️  Info 성격: ${INFO_PRINTS}건"
echo "   ⚠️  Warning 성격: ${WARNING_PRINTS}건"
echo "   ❓ 기타: $((PRINT_TOTAL - DEBUG_PRINTS - ERROR_PRINTS - INFO_PRINTS - WARNING_PRINTS))건"
echo ""

# 3. 백업 생성
echo -e "${BLUE}[3/6] 백업 생성${NC}"
echo "----------------------------------------"
echo "백업 위치: $BACKUP_DIR"

for file in $PRINT_FILES; do
    if [ -f "$file" ]; then
        # 디렉토리 구조 유지하며 백업
        dir=$(dirname "$file")
        mkdir -p "$BACKUP_DIR/$dir"
        cp "$file" "$BACKUP_DIR/$file"
        echo -n "."
    fi
done
echo ""
echo -e "${GREEN}✅ 백업 완료${NC}"
echo ""

# 4. 자동 변환 스크립트 생성
echo -e "${BLUE}[4/6] 자동 변환 규칙 생성${NC}"
echo "----------------------------------------"

cat > convert_print_to_logger.sh << 'EOF'
#!/bin/bash

# 파일별 print문 변환 함수
convert_file() {
    local file=$1
    local temp_file="${file}.tmp"
    local modified=false
    
    # AppLogger import 확인 및 추가
    if ! grep -q "import 'package:vms_app/core/utils/app_logger.dart';" "$file"; then
        # 첫 번째 import 문 찾아서 그 다음에 추가
        if grep -q "^import " "$file"; then
            sed -i "/^import /a import 'package:vms_app/core/utils/app_logger.dart';" "$file"
            modified=true
        fi
    fi
    
    # 임시 파일 생성
    cp "$file" "$temp_file"
    
    # 변환 규칙 적용
    # 1. Error 패턴
    sed -i "s/print('\(.*[Ee]rror.*\)')/AppLogger.e('\1')/g" "$temp_file"
    sed -i "s/print(\"\(.*[Ee]rror.*\)\")/AppLogger.e('\1')/g" "$temp_file"
    sed -i "s/print('\(.*실패.*\)')/AppLogger.e('\1')/g" "$temp_file"
    sed -i "s/print('\(.*오류.*\)')/AppLogger.e('\1')/g" "$temp_file"
    
    # 2. Warning 패턴
    sed -i "s/print('\(.*[Ww]arning.*\)')/AppLogger.w('\1')/g" "$temp_file"
    sed -i "s/print('\(.*경고.*\)')/AppLogger.w('\1')/g" "$temp_file"
    
    # 3. Info 패턴
    sed -i "s/print('\(.*성공.*\)')/AppLogger.i('\1')/g" "$temp_file"
    sed -i "s/print('\(.*완료.*\)')/AppLogger.i('\1')/g" "$temp_file"
    sed -i "s/print('\(.*시작.*\)')/AppLogger.i('\1')/g" "$temp_file"
    
    # 4. Debug 패턴 (나머지 모두)
    sed -i "s/print(/AppLogger.d(/g" "$temp_file"
    
    # 변경사항 확인
    if ! diff -q "$file" "$temp_file" > /dev/null; then
        mv "$temp_file" "$file"
        echo "✅ 변환 완료: $file"
        modified=true
    else
        rm "$temp_file"
    fi
    
    echo $modified
}

# 메인 실행
echo "print() → AppLogger 변환 시작..."

# 변환할 파일 목록
FILES=$(grep -rl "print(" lib/ --include="*.dart" | grep -v "app_logger.dart")

CONVERTED_COUNT=0
for file in $FILES; do
    convert_file "$file"
    ((CONVERTED_COUNT++))
done

echo ""
echo "✅ 변환 완료: ${CONVERTED_COUNT}개 파일"
EOF

chmod +x convert_print_to_logger.sh

# 5. 수동 검토 필요 항목 찾기
echo -e "${BLUE}[5/6] 수동 검토 필요 항목${NC}"
echo "----------------------------------------"

# 복잡한 print문 찾기 (변수 포함)
echo -e "${YELLOW}⚠️  수동 검토 필요한 복잡한 print문:${NC}"
grep -rn "print.*\$\|print.*\${" lib/ --include="*.dart" | head -10

echo ""

# debugPrint 사용 확인
DEBUG_PRINT_COUNT=$(grep -r "debugPrint(" lib/ --include="*.dart" 2>/dev/null | wc -l)
if [ $DEBUG_PRINT_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠️  debugPrint() 사용: ${DEBUG_PRINT_COUNT}건${NC}"
    grep -rn "debugPrint(" lib/ --include="*.dart" | head -5
fi

echo ""

# 6. 실행 옵션 제공
echo -e "${BLUE}[6/6] 실행 옵션${NC}"
echo "----------------------------------------"
echo "변환 방법을 선택하세요:"
echo "1) 자동 변환 실행 (권장)"
echo "2) 파일별 수동 확인 후 변환"
echo "3) 변환 미리보기만"
echo "4) 취소"
echo ""
read -p "선택 (1/2/3/4): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}자동 변환 시작...${NC}"
        ./convert_print_to_logger.sh
        
        # 결과 확인
        echo ""
        echo -e "${GREEN}=== 변환 결과 ===${NC}"
        NEW_PRINT_COUNT=$(grep -r "print(" lib/ --include="*.dart" 2>/dev/null | wc -l)
        NEW_LOGGER_COUNT=$(grep -r "AppLogger\." lib/ --include="*.dart" 2>/dev/null | wc -l)
        
        echo "변환 전: print() ${PRINT_TOTAL}건"
        echo "변환 후: print() ${NEW_PRINT_COUNT}건"
        echo "AppLogger 사용: ${NEW_LOGGER_COUNT}건"
        echo ""
        echo -e "${GREEN}✅ ${((PRINT_TOTAL - NEW_PRINT_COUNT))}건 변환 완료${NC}"
        ;;
        
    2)
        echo ""
        echo -e "${YELLOW}파일별 수동 확인 모드${NC}"
        
        for file in $PRINT_FILES; do
            echo ""
            echo "파일: $file"
            echo "print문 개수: $(grep -c "print(" "$file")개"
            grep -n "print(" "$file" | head -5
            echo ""
            read -p "이 파일을 변환하시겠습니까? (y/n): " confirm
            
            if [ "$confirm" = "y" ]; then
                ./convert_print_to_logger.sh "$file"
            fi
        done
        ;;
        
    3)
        echo ""
        echo -e "${BLUE}변환 미리보기${NC}"
        echo "----------------------------------------"
        
        # 샘플 파일 하나만 미리보기
        SAMPLE_FILE=$(echo "$PRINT_FILES" | head -1)
        if [ -f "$SAMPLE_FILE" ]; then
            echo "샘플 파일: $SAMPLE_FILE"
            echo ""
            echo "변환 전:"
            grep "print(" "$SAMPLE_FILE" | head -3
            echo ""
            echo "변환 후 (예상):"
            grep "print(" "$SAMPLE_FILE" | head -3 | sed 's/print(/AppLogger.d(/g'
        fi
        ;;
        
    4)
        echo -e "${YELLOW}취소되었습니다.${NC}"
        ;;
        
    *)
        echo -e "${RED}잘못된 선택입니다.${NC}"
        ;;
esac

echo ""
echo "========================================="
echo -e "${GREEN}         작업 완료${NC}"
echo "========================================="
echo ""
echo "💡 추가 작업:"
echo "1. flutter analyze 실행하여 오류 확인"
echo "2. 수동 검토 필요한 복잡한 print문 확인"
echo "3. 테스트 실행"
echo ""
echo "백업 위치: $BACKUP_DIR"
echo "복원 명령: cp -r $BACKUP_DIR/* ."
