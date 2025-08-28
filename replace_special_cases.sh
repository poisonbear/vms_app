#!/bin/bash

echo "🔧 특수 케이스 하드코딩 값 교체..."
echo "================================"
echo ""

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ========== getSize 함수 호출 교체 ==========
echo -e "${YELLOW}[1/5]${NC} getSize() 함수 호출을 상수로 교체..."

declare -A SIZE_FUNC_REPLACEMENTS=(
    ["getSize4().toDouble()"]="DesignConstants.spacing4"
    ["getSize8().toDouble()"]="DesignConstants.spacing8"
    ["getSize10().toDouble()"]="DesignConstants.spacing10"
    ["getSize12().toDouble()"]="DesignConstants.spacing12"
    ["getSize16().toDouble()"]="DesignConstants.spacing16"
    ["getSize20().toDouble()"]="DesignConstants.spacing20"
    ["getSize24().toDouble()"]="DesignConstants.spacing24"
    ["getSize30().toDouble()"]="DesignConstants.spacing30"
    ["getSize37().toDouble()"]="DesignConstants.spacing37"
    ["getSize50().toDouble()"]="DesignConstants.spacing50"
    ["getSize65().toDouble()"]="DesignConstants.spacing65"
)

for original in "${!SIZE_FUNC_REPLACEMENTS[@]}"; do
    replacement="${SIZE_FUNC_REPLACEMENTS[$original]}"
    count=$(grep -r "$original" lib --include="*.dart" | wc -l)
    if [ $count -gt 0 ]; then
        find lib -name "*.dart" -type f -exec sed -i "s/$original/$replacement/g" {} +
        echo "  ✓ $original → $replacement ($count개)"
    fi
done
echo ""

# ========== 네트워크 타임아웃 값 교체 ==========
echo -e "${YELLOW}[2/5]${NC} 네트워크 타임아웃 값 교체..."

declare -A TIMEOUT_REPLACEMENTS=(
    ["30000"]="NetworkConstants.connectTimeoutMs"
    ["100000"]="NetworkConstants.receiveTimeoutMs"
    ["connectionTimeout = 30000"]="connectionTimeout = NetworkConstants.connectTimeoutMs"
    ["receiveTimeout = 100000"]="receiveTimeout = NetworkConstants.receiveTimeoutMs"
    ["sendTimeout = 30000"]="sendTimeout = NetworkConstants.sendTimeoutMs"
)

for original in "${!TIMEOUT_REPLACEMENTS[@]}"; do
    replacement="${TIMEOUT_REPLACEMENTS[$original]}"
    # dio_client.dart와 network 관련 파일에서만 교체
    for file in lib/core/network/*.dart lib/data/datasources/remote/*.dart; do
        if [ -f "$file" ]; then
            if grep -q "$original" "$file"; then
                sed -i "s/$original/$replacement/g" "$file"
                echo "  ✓ $original → $replacement in $(basename $file)"
            fi
        fi
    done
done
echo ""

# ========== 아이콘 크기 교체 ==========
echo -e "${YELLOW}[3/5]${NC} 아이콘 크기 값 교체..."

declare -A ICON_REPLACEMENTS=(
    ["width: 16, height: 16"]="width: DesignConstants.iconSizeXS, height: DesignConstants.iconSizeXS"
    ["width: 20, height: 20"]="width: DesignConstants.iconSizeS, height: DesignConstants.iconSizeS"
    ["width: 24, height: 24"]="width: DesignConstants.iconSizeM, height: DesignConstants.iconSizeM"
    ["width: 32, height: 32"]="width: DesignConstants.iconSizeL, height: DesignConstants.iconSizeL"
    ["width: 40, height: 40"]="width: DesignConstants.iconSizeXL, height: DesignConstants.iconSizeXL"
    ["width: 60, height: 60"]="width: DesignConstants.iconSizeXXL, height: DesignConstants.iconSizeXXL"
    ["size: 24"]="size: DesignConstants.iconSizeM"
    ["size: 32"]="size: DesignConstants.iconSizeL"
    ["size: 64"]="size: DesignConstants.iconSizeMap"
)

for original in "${!ICON_REPLACEMENTS[@]}"; do
    replacement="${ICON_REPLACEMENTS[$original]}"
    count=$(grep -r "$original" lib --include="*.dart" | wc -l)
    if [ $count -gt 0 ]; then
        find lib -name "*.dart" -type f -exec sed -i "s/$original/$replacement/g" {} +
        echo "  ✓ $original → $replacement ($count개)"
    fi
done
echo ""

# ========== 날짜 포맷 교체 ==========
echo -e "${YELLOW}[4/5]${NC} 날짜/시간 포맷 문자열 교체..."

declare -A FORMAT_REPLACEMENTS=(
    ["'yyyy-MM-dd'"]="FormatConstants.dateFormat"
    ["'yyyy년 MM월 dd일'"]="FormatConstants.dateFormatKr"
    ["'yyyy-MM-dd HH:mm:ss'"]="FormatConstants.dateTimeFormat"
    ["'HH:mm:ss'"]="FormatConstants.timeFormat"
    ["'HH:mm'"]="FormatConstants.timeFormatShort"
    ["'MM.dd'"]="FormatConstants.monthDayFormat"
    ["'yyyy.MM'"]="FormatConstants.yearMonthFormat"
    ["'yyyy.MM.dd'"]="FormatConstants.dateFormat.replaceAll('-', '.')"
)

for original in "${!FORMAT_REPLACEMENTS[@]}"; do
    replacement="${FORMAT_REPLACEMENTS[$original]}"
    # DateFormat 사용하는 파일들에서 교체
    count=$(grep -r "DateFormat($original)" lib --include="*.dart" | wc -l)
    if [ $count -gt 0 ]; then
        find lib -name "*.dart" -type f -exec sed -i "s/DateFormat($original)/DateFormat($replacement)/g" {} +
        echo "  ✓ DateFormat($original) → DateFormat($replacement) ($count개)"
    fi
done
echo ""

# ========== 지도 관련 상수 교체 ==========
echo -e "${YELLOW}[5/5]${NC} 지도 관련 상수 교체..."

# main_screen.dart에서 지도 관련 값 교체
MAP_FILE="lib/presentation/screens/main/main_screen.dart"
if [ -f "$MAP_FILE" ]; then
    # 줌 레벨
    sed -i "s/zoom: 13\.0/zoom: MapConstants.zoomDefault/g" "$MAP_FILE"
    sed -i "s/minZoom: 5\.0/minZoom: MapConstants.zoomMin/g" "$MAP_FILE"
    sed -i "s/maxZoom: 18\.0/maxZoom: MapConstants.zoomMax/g" "$MAP_FILE"
    
    # Timer 간격
    sed -i "s/Duration(seconds: 2)/Duration(seconds: MapConstants.vesselUpdateSeconds)/g" "$MAP_FILE"
    
    echo "  ✓ 지도 관련 상수 교체 완료"
fi
echo ""

# ========== 검증 패턴 교체 ==========
echo "🔍 검증 패턴 교체..."

# validation 관련 파일들
for file in lib/presentation/screens/auth/*.dart lib/core/utils/*.dart; do
    if [ -f "$file" ]; then
        # MMSI 패턴
        if grep -q "r'\\^\\\\d{9}\\$'" "$file"; then
            sed -i "s/r'^\\\\d{9}\$'/FormatConstants.mmsiPattern/g" "$file"
            echo "  ✓ MMSI 패턴 교체: $(basename $file)"
        fi
        
        # Phone 패턴
        if grep -q "r'^01\[0-9\]" "$file"; then
            sed -i "s/r'^01\[0-9\]-?\[0-9\]{3,4}-?\[0-9\]{4}\$'/FormatConstants.phonePattern/g" "$file"
            echo "  ✓ Phone 패턴 교체: $(basename $file)"
        fi
    fi
done

echo ""
echo "================================"
echo -e "${GREEN}✅ 특수 케이스 교체 완료!${NC}"
echo ""
echo "📊 교체된 항목들:"
echo "  • getSize() 함수 호출"
echo "  • 네트워크 타임아웃 값"
echo "  • 아이콘 크기"
echo "  • 날짜/시간 포맷"
echo "  • 지도 설정"
echo "  • 검증 패턴"
echo ""
echo "🔍 수동 확인이 필요한 부분:"
echo "  • 계산식에 포함된 숫자 (예: width * 0.8)"
echo "  • 조건문의 매직넘버 (예: if (value > 1000))"
echo "  • API 응답 코드 (예: if (statusCode == 200))"
