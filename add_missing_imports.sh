#!/bin/bash

echo "📦 누락된 import 문 추가 작업..."
echo "================================"
echo ""

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# DesignConstants나 AnimationConstants를 사용하지만 import가 없는 파일 찾기
echo -e "${YELLOW}[1/2]${NC} import가 필요한 파일 검색..."

FILES_NEEDING_IMPORT=()

# DesignConstants를 사용하는 파일 찾기
while IFS= read -r file; do
    if [ -f "$file" ]; then
        # 이미 import가 있는지 확인
        if ! grep -q "import.*constants.dart" "$file" && \
           ! grep -q "import.*design_constants.dart" "$file"; then
            FILES_NEEDING_IMPORT+=("$file")
        fi
    fi
done < <(grep -r "DesignConstants\." lib --include="*.dart" -l 2>/dev/null)

# AnimationConstants를 사용하는 파일 찾기
while IFS= read -r file; do
    if [ -f "$file" ]; then
        # 이미 import가 있는지 확인
        if ! grep -q "import.*constants.dart" "$file" && \
           ! grep -q "import.*animation_constants.dart" "$file"; then
            # 중복 체크
            if [[ ! " ${FILES_NEEDING_IMPORT[@]} " =~ " ${file} " ]]; then
                FILES_NEEDING_IMPORT+=("$file")
            fi
        fi
    fi
done < <(grep -r "AnimationConstants\." lib --include="*.dart" -l 2>/dev/null)

# FormatConstants를 사용하는 파일 찾기
while IFS= read -r file; do
    if [ -f "$file" ]; then
        if ! grep -q "import.*constants.dart" "$file" && \
           ! grep -q "import.*format_constants.dart" "$file"; then
            # 중복 체크
            if [[ ! " ${FILES_NEEDING_IMPORT[@]} " =~ " ${file} " ]]; then
                FILES_NEEDING_IMPORT+=("$file")
            fi
        fi
    fi
done < <(grep -r "FormatConstants\." lib --include="*.dart" -l 2>/dev/null)

# MapConstants를 사용하는 파일 찾기
while IFS= read -r file; do
    if [ -f "$file" ]; then
        if ! grep -q "import.*constants.dart" "$file" && \
           ! grep -q "import.*map_constants.dart" "$file"; then
            # 중복 체크
            if [[ ! " ${FILES_NEEDING_IMPORT[@]} " =~ " ${file} " ]]; then
                FILES_NEEDING_IMPORT+=("$file")
            fi
        fi
    fi
done < <(grep -r "MapConstants\." lib --include="*.dart" -l 2>/dev/null)

# NetworkConstants를 사용하는 파일 찾기
while IFS= read -r file; do
    if [ -f "$file" ]; then
        if ! grep -q "import.*constants.dart" "$file" && \
           ! grep -q "import.*network_constants.dart" "$file"; then
            # 중복 체크
            if [[ ! " ${FILES_NEEDING_IMPORT[@]} " =~ " ${file} " ]]; then
                FILES_NEEDING_IMPORT+=("$file")
            fi
        fi
    fi
done < <(grep -r "NetworkConstants\." lib --include="*.dart" -l 2>/dev/null)

echo "  발견된 파일: ${#FILES_NEEDING_IMPORT[@]}개"
echo ""

# ========== STEP 2: import 문 추가 ==========
echo -e "${YELLOW}[2/2]${NC} import 문 추가 중..."

for file in "${FILES_NEEDING_IMPORT[@]}"; do
    if [ -f "$file" ]; then
        # 상수 파일 자체는 건너뛰기
        if [[ "$file" == *"constants/"* ]]; then
            continue
        fi
        
        # 첫 번째 import 문을 찾아서 그 다음에 추가
        if grep -q "^import " "$file"; then
            # 첫 번째 import 라인 번호 찾기
            first_import_line=$(grep -n "^import " "$file" | head -1 | cut -d: -f1)
            
            # 해당 라인 다음에 import 추가
            sed -i "${first_import_line}a\\import 'package:vms_app/core/constants/constants.dart';" "$file"
            echo "  ✓ Import 추가: $(basename $file)"
        else
            # import 문이 없으면 package 선언 다음에 추가
            if grep -q "^library " "$file"; then
                sed -i "/^library /a\\\\nimport 'package:vms_app/core/constants/constants.dart';" "$file"
            else
                # 파일 시작 부분에 추가
                sed -i "1i\\import 'package:vms_app/core/constants/constants.dart';\\n" "$file"
            fi
            echo "  ✓ Import 추가: $(basename $file)"
        fi
    fi
done

echo ""
echo "================================"
echo -e "${GREEN}✅ Import 추가 완료!${NC}"
echo ""

# 중복 import 제거
echo "🧹 중복 import 제거 중..."
for file in lib/**/*.dart; do
    if [ -f "$file" ]; then
        # 중복된 constants import 제거
        awk '!seen[$0]++ || !/import.*constants\.dart/' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
done

echo ""
echo "🔍 최종 검증..."
flutter analyze 2>&1 | grep -c "error" | while read ERROR_COUNT; do
    if [ "$ERROR_COUNT" -eq "0" ]; then
        echo -e "${GREEN}✅ 모든 에러가 해결되었습니다!${NC}"
    else
        echo "⚠️ 아직 $ERROR_COUNT개의 에러가 있습니다."
        echo "다음 명령어로 확인하세요:"
        echo "  flutter analyze | grep error"
    fi
done
