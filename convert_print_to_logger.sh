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
