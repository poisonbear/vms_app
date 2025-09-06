#!/bin/bash

# 중복 코드 자동 교체 스크립트

echo "🔄 중복 코드 자동 교체 시작..."

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPLACED_COUNT=0

# 1. warningPop을 DialogUtils.showWarningPopup으로 교체
echo -e "\n${YELLOW}warningPop → DialogUtils.showWarningPopup 교체${NC}"
for file in $(find lib -name "*.dart" -type f); do
    if grep -q "warningPop(" "$file"; then
        # import 추가 (없는 경우)
        if ! grep -q "import.*dialog_utils" "$file"; then
            sed -i '1a\import '\''package:vms_app/core/utils/dialog_utils.dart'\'';' "$file"
        fi
        
        # 함수 교체
        sed -i 's/warningPop(/DialogUtils.showWarningPopup(/g' "$file"
        
        echo -e "  ✅ $(basename $file) 수정됨"
        REPLACED_COUNT=$((REPLACED_COUNT + 1))
    fi
done

# 2. 단순 showDialog를 DialogUtils로 교체
echo -e "\n${YELLOW}단순 AlertDialog → DialogUtils 교체${NC}"
for file in $(find lib -name "*.dart" -type f); do
    # 패턴: showDialog with simple AlertDialog
    if grep -q "showDialog.*AlertDialog" "$file"; then
        echo -e "  📝 $(basename $file) - 수동 검토 필요"
    fi
done

echo -e "\n${GREEN}✅ 자동 교체 완료: $REPLACED_COUNT개 파일${NC}"
echo "수동 검토가 필요한 파일은 위에 표시되었습니다."
