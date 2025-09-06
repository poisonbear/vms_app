#!/bin/bash

# Provider dispose 에러 수정 스크립트
# 잘못된 변수명과 중괄호 문제 해결

echo "======================================"
echo "🔧 Provider dispose 에러 수정"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROVIDER_DIR="lib/presentation/providers"

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 1: 잘못된 dispose 제거${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 1. terms_provider.dart 수정 - 중복된 중괄호 제거
echo -e "\n${BLUE}1. terms_provider.dart 중괄호 수정${NC}"
if [ -f "$PROVIDER_DIR/terms_provider.dart" ]; then
    # 파일 끝의 중복된 } 제거
    # dispose 메서드가 있다면 임시로 제거
    cp "$PROVIDER_DIR/terms_provider.dart" "$PROVIDER_DIR/terms_provider.dart.backup"
    
    # 마지막 몇 줄 확인해서 중복된 } 제거
    tail -n 20 "$PROVIDER_DIR/terms_provider.dart" | grep -c "^}$" > bracket_count.txt
    BRACKET_COUNT=$(cat bracket_count.txt)
    rm bracket_count.txt
    
    if [ $BRACKET_COUNT -gt 2 ]; then
        # 중복된 } 제거 (마지막 }만 남기고)
        sed -i ':a; /^}$/{N; s/}\n}$/}/; ba}' "$PROVIDER_DIR/terms_provider.dart"
        echo -e "${GREEN}  ✅ 중복된 중괄호 제거됨${NC}"
    fi
    
    # dispose 메서드가 있다면 제거 (나중에 올바른 것으로 다시 추가)
    sed -i '/^  @override$/,/^  }$/{ /void dispose()/,/^  }$/d; }' "$PROVIDER_DIR/terms_provider.dart"
fi

# 2. vessel_provider.dart 수정
echo -e "\n${BLUE}2. vessel_provider.dart 변수명 수정${NC}"
if [ -f "$PROVIDER_DIR/vessel_provider.dart" ]; then
    cp "$PROVIDER_DIR/vessel_provider.dart" "$PROVIDER_DIR/vessel_provider.dart.backup"
    
    # 잘못된 dispose 제거
    sed -i '/^  @override$/,/^  }$/{ /void dispose()/,/^  }$/d; }' "$PROVIDER_DIR/vessel_provider.dart"
    echo -e "${GREEN}  ✅ 잘못된 dispose 제거됨${NC}"
fi

# 3. weather_provider.dart 수정
echo -e "\n${BLUE}3. weather_provider.dart 변수명 수정${NC}"
if [ -f "$PROVIDER_DIR/weather_provider.dart" ]; then
    cp "$PROVIDER_DIR/weather_provider.dart" "$PROVIDER_DIR/weather_provider.dart.backup"
    
    # 잘못된 dispose 제거
    sed -i '/^  @override$/,/^  }$/{ /void dispose()/,/^  }$/d; }' "$PROVIDER_DIR/weather_provider.dart"
    echo -e "${GREEN}  ✅ 잘못된 dispose 제거됨${NC}"
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 2: 실제 변수명 확인${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# vessel_provider의 실제 변수 확인
echo -e "\n${BLUE}vessel_provider.dart 변수 확인:${NC}"
if [ -f "$PROVIDER_DIR/vessel_provider.dart" ]; then
    echo "  찾은 변수들:"
    grep -E "^\s*(List|Map|String|bool|int|double|var|final|late).*_" "$PROVIDER_DIR/vessel_provider.dart" | head -10
fi

# weather_provider의 실제 변수 확인
echo -e "\n${BLUE}weather_provider.dart 변수 확인:${NC}"
if [ -f "$PROVIDER_DIR/weather_provider.dart" ]; then
    echo "  찾은 변수들:"
    grep -E "^\s*(List|Map|String|bool|int|double|var|final|late).*_" "$PROVIDER_DIR/weather_provider.dart" | head -10
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 3: 올바른 dispose 추가${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 1. vessel_provider.dart - 올바른 dispose 추가
echo -e "\n${BLUE}vessel_provider.dart dispose 추가${NC}"
if [ -f "$PROVIDER_DIR/vessel_provider.dart" ]; then
    # 파일 끝의 } 전에 dispose 추가
    cat > temp_vessel_dispose.txt << 'EOF'

  @override
  void dispose() {
    // Vessel 관련 리소스 정리
    _vessels.clear();
    
    // BaseProvider의 dispose 호출
    super.dispose();
  }
EOF
    
    # 파일의 마지막 } 전에 삽입
    head -n -1 "$PROVIDER_DIR/vessel_provider.dart" > temp_vessel.dart
    cat temp_vessel_dispose.txt >> temp_vessel.dart
    echo "}" >> temp_vessel.dart
    mv temp_vessel.dart "$PROVIDER_DIR/vessel_provider.dart"
    rm temp_vessel_dispose.txt
    
    echo -e "${GREEN}  ✅ vessel_provider dispose 추가됨${NC}"
fi

# 2. weather_provider.dart - 올바른 dispose 추가
echo -e "\n${BLUE}weather_provider.dart dispose 추가${NC}"
if [ -f "$PROVIDER_DIR/weather_provider.dart" ]; then
    cat > temp_weather_dispose.txt << 'EOF'

  @override
  void dispose() {
    // Weather 관련 리소스 정리
    // 실제 변수가 있다면 여기서 정리
    
    // BaseProvider의 dispose 호출
    super.dispose();
  }
EOF
    
    head -n -1 "$PROVIDER_DIR/weather_provider.dart" > temp_weather.dart
    cat temp_weather_dispose.txt >> temp_weather.dart
    echo "}" >> temp_weather.dart
    mv temp_weather.dart "$PROVIDER_DIR/weather_provider.dart"
    rm temp_weather_dispose.txt
    
    echo -e "${GREEN}  ✅ weather_provider dispose 추가됨${NC}"
fi

# 3. terms_provider.dart - 올바른 dispose 추가
echo -e "\n${BLUE}terms_provider.dart dispose 추가${NC}"
if [ -f "$PROVIDER_DIR/terms_provider.dart" ]; then
    # ChangeNotifier를 상속받는지 확인
    if grep -q "extends ChangeNotifier" "$PROVIDER_DIR/terms_provider.dart"; then
        cat > temp_terms_dispose.txt << 'EOF'

  @override
  void dispose() {
    // Terms 관련 상태 초기화
    // 실제 변수가 있다면 여기서 정리
    
    super.dispose();
  }
EOF
        
        head -n -1 "$PROVIDER_DIR/terms_provider.dart" > temp_terms.dart
        cat temp_terms_dispose.txt >> temp_terms.dart
        echo "}" >> temp_terms.dart
        mv temp_terms.dart "$PROVIDER_DIR/terms_provider.dart"
        rm temp_terms_dispose.txt
        
        echo -e "${GREEN}  ✅ terms_provider dispose 추가됨${NC}"
    fi
fi

# 4. route_search_provider.dart - clearRoutes 메서드 확인
echo -e "\n${BLUE}route_search_provider.dart 확인${NC}"
if [ -f "$PROVIDER_DIR/route_search_provider.dart" ]; then
    if grep -q "clearRoutes()" "$PROVIDER_DIR/route_search_provider.dart"; then
        echo -e "${GREEN}  ✅ clearRoutes 메서드 존재${NC}"
    else
        echo -e "${YELLOW}  ⚠️  clearRoutes 메서드 확인 필요${NC}"
    fi
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 4: 코드 검증${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 코드 포맷팅
echo -e "\n${BLUE}코드 포맷팅 실행중...${NC}"
dart format $PROVIDER_DIR --line-length=120 2>/dev/null || true

# Flutter analyze
echo -e "\n${BLUE}Flutter analyze 실행중...${NC}"
ANALYZE_OUTPUT=$(flutter analyze --no-pub $PROVIDER_DIR 2>&1 || true)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || true)

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ 컴파일 에러 해결됨!${NC}"
else
    echo -e "${YELLOW}⚠️  아직 에러 $ERROR_COUNT개 존재${NC}"
    echo "$ANALYZE_OUTPUT" | grep "error" | head -5
fi

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Provider 에러 수정 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n📊 ${YELLOW}결과:${NC}"
echo -e "  • 백업 파일 생성됨 (.backup)"
echo -e "  • dispose 메서드 수정됨"
echo -e "  • 컴파일 에러: $ERROR_COUNT개"

echo -e "\n🎯 ${YELLOW}다음 단계:${NC}"
echo "1. ${CYAN}flutter analyze${NC} - 전체 분석"
echo "2. ${CYAN}cat $PROVIDER_DIR/vessel_provider.dart | tail -20${NC} - dispose 확인"
echo "3. 남은 에러가 있다면 수동 수정"

echo -e "\n💡 ${GREEN}팁:${NC}"
echo "BaseProvider를 상속받는 클래스는"
echo "실제 존재하는 변수만 dispose에서 정리해야 합니다."

# 백업 파일 목록
echo -e "\n📁 ${YELLOW}백업 파일:${NC}"
ls -la $PROVIDER_DIR/*.backup 2>/dev/null || echo "백업 파일 없음"
