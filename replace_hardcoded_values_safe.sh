#!/bin/bash

echo "🔄 하드코딩된 값을 상수로 교체하는 작업 시작..."
echo "================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 백업 디렉토리 생성
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
echo "📁 백업 디렉토리 생성: $BACKUP_DIR"
mkdir -p $BACKUP_DIR

# 전체 lib 폴더 백업
echo "💾 전체 lib 폴더 백업 중..."
cp -r lib $BACKUP_DIR/
echo -e "${GREEN}✅ 백업 완료!${NC}"
echo ""

# ========== STEP 1: Import 문 추가 ==========
echo -e "${YELLOW}[STEP 1/6]${NC} 필요한 파일들에 import 문 추가..."

# import 문을 추가할 파일 패턴
PATTERNS=(
    "lib/presentation/screens/**/*.dart"
    "lib/presentation/widgets/**/*.dart"
    "lib/presentation/providers/**/*.dart"
)

for pattern in "${PATTERNS[@]}"; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            # 이미 import가 있는지 확인
            if ! grep -q "import 'package:vms_app/core/constants/constants.dart';" "$file"; then
                # Flutter 관련 import 다음에 추가
                sed -i "/^import 'package:flutter/a import 'package:vms_app/core/constants/constants.dart';" "$file"
                echo "  ✓ Import 추가: $(basename $file)"
            fi
        fi
    done
done
echo ""

# ========== STEP 2: fontSize 교체 ==========
echo -e "${YELLOW}[STEP 2/6]${NC} fontSize 값들을 상수로 교체..."

# fontSize 교체 규칙
declare -A FONT_REPLACEMENTS=(
    ["fontSize: 10"]="fontSize: DesignConstants.fontSizeXXS"
    ["fontSize: 12"]="fontSize: DesignConstants.fontSizeXS"
    ["fontSize: 14"]="fontSize: DesignConstants.fontSizeS"
    ["fontSize: 16"]="fontSize: DesignConstants.fontSizeM"
    ["fontSize: 18"]="fontSize: DesignConstants.fontSizeL"
    ["fontSize: 20"]="fontSize: DesignConstants.fontSizeXL"
    ["fontSize: 24"]="fontSize: DesignConstants.fontSizeXXL"
    ["fontSize: 30"]="fontSize: DesignConstants.fontSizeTitle"
)

for original in "${!FONT_REPLACEMENTS[@]}"; do
    replacement="${FONT_REPLACEMENTS[$original]}"
    count=$(grep -r "$original" lib --include="*.dart" | wc -l)
    if [ $count -gt 0 ]; then
        find lib -name "*.dart" -type f -exec sed -i "s/$original/$replacement/g" {} +
        echo "  ✓ $original → $replacement ($count개 교체)"
    fi
done
echo ""

# ========== STEP 3: EdgeInsets 교체 ==========
echo -e "${YELLOW}[STEP 3/6]${NC} EdgeInsets 값들을 상수로 교체..."

declare -A EDGE_REPLACEMENTS=(
    ["EdgeInsets.all(4)"]="EdgeInsets.all(DesignConstants.spacing4)"
    ["EdgeInsets.all(8)"]="EdgeInsets.all(DesignConstants.spacing8)"
    ["EdgeInsets.all(10)"]="EdgeInsets.all(DesignConstants.spacing10)"
    ["EdgeInsets.all(12)"]="EdgeInsets.all(DesignConstants.spacing12)"
    ["EdgeInsets.all(16)"]="EdgeInsets.all(DesignConstants.spacing16)"
    ["EdgeInsets.all(20)"]="EdgeInsets.all(DesignConstants.spacing20)"
    ["EdgeInsets.all(24)"]="EdgeInsets.all(DesignConstants.spacing24)"
    ["EdgeInsets.all(30)"]="EdgeInsets.all(DesignConstants.spacing30)"
    ["EdgeInsets.all(50)"]="EdgeInsets.all(DesignConstants.spacing50)"
    ["EdgeInsets.all(65)"]="EdgeInsets.all(DesignConstants.spacing65)"
)

for original in "${!EDGE_REPLACEMENTS[@]}"; do
    replacement="${EDGE_REPLACEMENTS[$original]}"
    count=$(grep -r "$original" lib --include="*.dart" | wc -l)
    if [ $count -gt 0 ]; then
        find lib -name "*.dart" -type f -exec sed -i "s/$original/$replacement/g" {} +
        echo "  ✓ $original → $replacement ($count개 교체)"
    fi
done

# symmetric padding도 교체
declare -A SYMMETRIC_REPLACEMENTS=(
    ["horizontal: 8"]="horizontal: DesignConstants.spacing8"
    ["horizontal: 10"]="horizontal: DesignConstants.spacing10"
    ["horizontal: 12"]="horizontal: DesignConstants.spacing12"
    ["horizontal: 16"]="horizontal: DesignConstants.spacing16"
    ["horizontal: 20"]="horizontal: DesignConstants.spacing20"
    ["vertical: 8"]="vertical: DesignConstants.spacing8"
    ["vertical: 10"]="vertical: DesignConstants.spacing10"
    ["vertical: 12"]="vertical: DesignConstants.spacing12"
    ["vertical: 16"]="vertical: DesignConstants.spacing16"
    ["vertical: 20"]="vertical: DesignConstants.spacing20"
)

for original in "${!SYMMETRIC_REPLACEMENTS[@]}"; do
    replacement="${SYMMETRIC_REPLACEMENTS[$original]}"
    count=$(grep -r "$original" lib --include="*.dart" | wc -l)
    if [ $count -gt 0 ]; then
        find lib -name "*.dart" -type f -exec sed -i "s/$original/$replacement/g" {} +
        echo "  ✓ $original → $replacement ($count개 교체)"
    fi
done
echo ""

# ========== STEP 4: SizedBox height/width 교체 ==========
echo -e "${YELLOW}[STEP 4/6]${NC} SizedBox height/width 값들을 상수로 교체..."

declare -A SIZED_REPLACEMENTS=(
    ["SizedBox(height: 4)"]="SizedBox(height: DesignConstants.spacing4)"
    ["SizedBox(height: 8)"]="SizedBox(height: DesignConstants.spacing8)"
    ["SizedBox(height: 10)"]="SizedBox(height: DesignConstants.spacing10)"
    ["SizedBox(height: 12)"]="SizedBox(height: DesignConstants.spacing12)"
    ["SizedBox(height: 16)"]="SizedBox(height: DesignConstants.spacing16)"
    ["SizedBox(height: 20)"]="SizedBox(height: DesignConstants.spacing20)"
    ["SizedBox(height: 24)"]="SizedBox(height: DesignConstants.spacing24)"
    ["SizedBox(height: 30)"]="SizedBox(height: DesignConstants.spacing30)"
    ["SizedBox(width: 4)"]="SizedBox(width: DesignConstants.spacing4)"
    ["SizedBox(width: 8)"]="SizedBox(width: DesignConstants.spacing8)"
    ["SizedBox(width: 10)"]="SizedBox(width: DesignConstants.spacing10)"
    ["SizedBox(width: 12)"]="SizedBox(width: DesignConstants.spacing12)"
    ["SizedBox(width: 16)"]="SizedBox(width: DesignConstants.spacing16)"
    ["SizedBox(width: 20)"]="SizedBox(width: DesignConstants.spacing20)"
)

for original in "${!SIZED_REPLACEMENTS[@]}"; do
    replacement="${SIZED_REPLACEMENTS[$original]}"
    count=$(grep -r "$original" lib --include="*.dart" | wc -l)
    if [ $count -gt 0 ]; then
        find lib -name "*.dart" -type f -exec sed -i "s/$original/$replacement/g" {} +
        echo "  ✓ $original → $replacement ($count개 교체)"
    fi
done
echo ""

# ========== STEP 5: Duration 교체 ==========
echo -e "${YELLOW}[STEP 5/6]${NC} Duration 값들을 상수로 교체..."

declare -A DURATION_REPLACEMENTS=(
    ["Duration(milliseconds: 100)"]="AnimationConstants.durationInstant"
    ["Duration(milliseconds: 150)"]="AnimationConstants.durationFast"
    ["Duration(milliseconds: 300)"]="AnimationConstants.durationQuick"
    ["Duration(milliseconds: 500)"]="AnimationConstants.durationNormal"
    ["Duration(milliseconds: 700)"]="AnimationConstants.durationSlow"
    ["Duration(milliseconds: 1000)"]="AnimationConstants.durationVerySlow"
    ["Duration(seconds: 2)"]="AnimationConstants.autoScrollDelay"
    ["Duration(seconds: 3)"]="AnimationConstants.splashDuration"
    ["Duration(seconds: 30)"]="AnimationConstants.weatherUpdateInterval"
)

for original in "${!DURATION_REPLACEMENTS[@]}"; do
    replacement="${DURATION_REPLACEMENTS[$original]}"
    count=$(grep -r "$original" lib --include="*.dart" | wc -l)
    if [ $count -gt 0 ]; then
        find lib -name "*.dart" -type f -exec sed -i "s/$original/$replacement/g" {} +
        echo "  ✓ $original → $replacement ($count개 교체)"
    fi
done
echo ""

# ========== STEP 6: BorderRadius 교체 ==========
echo -e "${YELLOW}[STEP 6/6]${NC} BorderRadius 값들을 상수로 교체..."

declare -A RADIUS_REPLACEMENTS=(
    ["BorderRadius.circular(4)"]="BorderRadius.circular(DesignConstants.radiusXS)"
    ["BorderRadius.circular(6)"]="BorderRadius.circular(DesignConstants.radiusS)"
    ["BorderRadius.circular(10)"]="BorderRadius.circular(DesignConstants.radiusM)"
    ["BorderRadius.circular(16)"]="BorderRadius.circular(DesignConstants.radiusL)"
    ["BorderRadius.circular(20)"]="BorderRadius.circular(DesignConstants.radiusXL)"
    ["Radius.circular(4)"]="Radius.circular(DesignConstants.radiusXS)"
    ["Radius.circular(6)"]="Radius.circular(DesignConstants.radiusS)"
    ["Radius.circular(10)"]="Radius.circular(DesignConstants.radiusM)"
    ["Radius.circular(16)"]="Radius.circular(DesignConstants.radiusL)"
    ["Radius.circular(20)"]="Radius.circular(DesignConstants.radiusXL)"
)

for original in "${!RADIUS_REPLACEMENTS[@]}"; do
    replacement="${RADIUS_REPLACEMENTS[$original]}"
    count=$(grep -r "$original" lib --include="*.dart" | wc -l)
    if [ $count -gt 0 ]; then
        find lib -name "*.dart" -type f -exec sed -i "s/$original/$replacement/g" {} +
        echo "  ✓ $original → $replacement ($count개 교체)"
    fi
done
echo ""

# ========== 검증 ==========
echo "🔍 Flutter analyze 실행 중..."
flutter analyze > analyze_result.txt 2>&1

if grep -q "error" analyze_result.txt; then
    echo -e "${RED}⚠️ 에러가 발견되었습니다!${NC}"
    echo "analyze_result.txt 파일을 확인해주세요."
    echo ""
    echo "복원 명령어:"
    echo "  rm -rf lib && cp -r $BACKUP_DIR/lib ."
else
    echo -e "${GREEN}✅ 모든 교체가 성공적으로 완료되었습니다!${NC}"
    rm analyze_result.txt
fi

echo ""
echo "================================"
echo "📊 교체 작업 완료!"
echo ""
echo "📁 백업 위치: $BACKUP_DIR"
echo ""
echo "🔧 다음 단계:"
echo "1. 변경사항 확인:"
echo "   git diff"
echo ""
echo "2. 특정 파일만 복원하려면:"
echo "   cp $BACKUP_DIR/lib/path/to/file.dart lib/path/to/file.dart"
echo ""
echo "3. 전체 복원이 필요하면:"
echo "   rm -rf lib && cp -r $BACKUP_DIR/lib ."
echo ""
echo "4. 문제가 없다면 백업 삭제:"
echo "   rm -rf $BACKUP_DIR"
