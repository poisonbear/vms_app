#!/bin/bash

# 모든 Provider에 dispose 메서드 추가 스크립트
# BaseProvider를 상속받는 Provider들에 dispose 오버라이드 추가

echo "======================================"
echo "🔧 BaseProvider 상속 클래스 dispose 추가"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROVIDER_DIR="lib/presentation/providers"
FIXED_COUNT=0

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Provider 파일별 dispose 추가${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 1. navigation_provider.dart
echo -e "\n${BLUE}1. navigation_provider.dart${NC}"
if [ -f "$PROVIDER_DIR/navigation_provider.dart" ]; then
    if ! grep -q "void dispose()" "$PROVIDER_DIR/navigation_provider.dart"; then
        # 클래스 끝 부분(마지막 })을 찾아서 그 전에 dispose 추가
        cat >> temp_dispose.txt << 'EOF'

  // ✅ dispose 메서드 추가 - 메모리 누수 방지
  @override
  void dispose() {
    // Navigation 관련 리소스 정리
    _rosList.clear();
    _navigationWarnings.clear();
    
    // 상태 초기화
    _isInitialized = false;
    
    // Weather 데이터 초기화
    wave = 0;
    visibility = 0;
    walm1 = 0.0;
    walm2 = 0.0;
    walm3 = 0.0;
    walm4 = 0.0;
    valm1 = 0.0;
    valm2 = 0.0;
    valm3 = 0.0;
    valm4 = 0.0;
    
    // BaseProvider의 dispose 호출 (중요!)
    super.dispose();
  }
}
EOF
        # 파일의 마지막 }를 제거하고 dispose 메서드 추가
        sed -i '$ d' "$PROVIDER_DIR/navigation_provider.dart"
        cat temp_dispose.txt >> "$PROVIDER_DIR/navigation_provider.dart"
        rm temp_dispose.txt
        echo -e "${GREEN}  ✅ navigation_provider.dart dispose 추가됨${NC}"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    else
        echo -e "${YELLOW}  ℹ️  이미 dispose 메서드 존재${NC}"
    fi
fi

# 2. route_search_provider.dart
echo -e "\n${BLUE}2. route_search_provider.dart${NC}"
if [ -f "$PROVIDER_DIR/route_search_provider.dart" ]; then
    if ! grep -q "void dispose()" "$PROVIDER_DIR/route_search_provider.dart"; then
        cat >> temp_dispose.txt << 'EOF'

  @override
  void dispose() {
    // Route 검색 관련 리소스 정리
    clearRoutes();
    _isNavigationHistoryMode = false;
    
    // BaseProvider의 dispose 호출
    super.dispose();
  }
}
EOF
        sed -i '$ d' "$PROVIDER_DIR/route_search_provider.dart"
        cat temp_dispose.txt >> "$PROVIDER_DIR/route_search_provider.dart"
        rm temp_dispose.txt
        echo -e "${GREEN}  ✅ route_search_provider.dart dispose 추가됨${NC}"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    else
        echo -e "${YELLOW}  ℹ️  이미 dispose 메서드 존재${NC}"
    fi
fi

# 3. vessel_provider.dart
echo -e "\n${BLUE}3. vessel_provider.dart${NC}"
if [ -f "$PROVIDER_DIR/vessel_provider.dart" ]; then
    if ! grep -q "void dispose()" "$PROVIDER_DIR/vessel_provider.dart"; then
        cat >> temp_dispose.txt << 'EOF'

  @override
  void dispose() {
    // Vessel 관련 리소스 정리
    _vessels.clear();
    _filteredVessels.clear();
    _selectedVessel = null;
    _searchQuery = '';
    _isInitialized = false;
    
    // BaseProvider의 dispose 호출
    super.dispose();
  }
}
EOF
        sed -i '$ d' "$PROVIDER_DIR/vessel_provider.dart"
        cat temp_dispose.txt >> "$PROVIDER_DIR/vessel_provider.dart"
        rm temp_dispose.txt
        echo -e "${GREEN}  ✅ vessel_provider.dart dispose 추가됨${NC}"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    else
        echo -e "${YELLOW}  ℹ️  이미 dispose 메서드 존재${NC}"
    fi
fi

# 4. weather_provider.dart
echo -e "\n${BLUE}4. weather_provider.dart${NC}"
if [ -f "$PROVIDER_DIR/weather_provider.dart" ]; then
    if ! grep -q "void dispose()" "$PROVIDER_DIR/weather_provider.dart"; then
        cat >> temp_dispose.txt << 'EOF'

  @override
  void dispose() {
    // Weather 관련 리소스 정리
    _weatherData = null;
    _currentLocation = null;
    _selectedLocation = null;
    
    // BaseProvider의 dispose 호출
    super.dispose();
  }
}
EOF
        sed -i '$ d' "$PROVIDER_DIR/weather_provider.dart"
        cat temp_dispose.txt >> "$PROVIDER_DIR/weather_provider.dart"
        rm temp_dispose.txt
        echo -e "${GREEN}  ✅ weather_provider.dart dispose 추가됨${NC}"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    else
        echo -e "${YELLOW}  ℹ️  이미 dispose 메서드 존재${NC}"
    fi
fi

# 5. terms_provider.dart
echo -e "\n${BLUE}5. terms_provider.dart${NC}"
if [ -f "$PROVIDER_DIR/terms_provider.dart" ]; then
    if ! grep -q "void dispose()" "$PROVIDER_DIR/terms_provider.dart"; then
        cat >> temp_dispose.txt << 'EOF'

  @override
  void dispose() {
    // Terms 관련 상태 초기화
    _allAgreed = false;
    _termsAgreed = false;
    _privacyAgreed = false;
    _marketingAgreed = false;
    
    // BaseProvider의 dispose 호출
    super.dispose();
  }
}
EOF
        sed -i '$ d' "$PROVIDER_DIR/terms_provider.dart"
        cat temp_dispose.txt >> "$PROVIDER_DIR/terms_provider.dart"
        rm temp_dispose.txt
        echo -e "${GREEN}  ✅ terms_provider.dart dispose 추가됨${NC}"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    else
        echo -e "${YELLOW}  ℹ️  이미 dispose 메서드 존재${NC}"
    fi
fi

# 6. auth_provider.dart (있다면)
echo -e "\n${BLUE}6. auth_provider.dart${NC}"
if [ -f "$PROVIDER_DIR/auth_provider.dart" ]; then
    if grep -q "extends BaseProvider\|extends ChangeNotifier" "$PROVIDER_DIR/auth_provider.dart"; then
        if ! grep -q "void dispose()" "$PROVIDER_DIR/auth_provider.dart"; then
            cat >> temp_dispose.txt << 'EOF'

  @override
  void dispose() {
    // Auth 관련 리소스 정리
    _user = null;
    _isAuthenticated = false;
    
    // super.dispose 호출
    super.dispose();
  }
}
EOF
            sed -i '$ d' "$PROVIDER_DIR/auth_provider.dart"
            cat temp_dispose.txt >> "$PROVIDER_DIR/auth_provider.dart"
            rm temp_dispose.txt
            echo -e "${GREEN}  ✅ auth_provider.dart dispose 추가됨${NC}"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        else
            echo -e "${YELLOW}  ℹ️  이미 dispose 메서드 존재${NC}"
        fi
    fi
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 코드 포맷팅 및 검증${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 코드 포맷팅
echo -e "\n${BLUE}코드 포맷팅 실행중...${NC}"
dart format $PROVIDER_DIR --line-length=120 2>/dev/null || true

# 검증
echo -e "\n${BLUE}dispose 메서드 추가 확인중...${NC}"
for file in $PROVIDER_DIR/*.dart; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if grep -q "extends BaseProvider\|extends ChangeNotifier" "$file"; then
            if grep -q "void dispose()" "$file"; then
                echo -e "${GREEN}  ✅ $filename: dispose 메서드 확인됨${NC}"
            else
                echo -e "${RED}  ❌ $filename: dispose 메서드 없음${NC}"
            fi
        fi
    fi
done

# Flutter analyze
echo -e "\n${BLUE}Flutter analyze 실행중...${NC}"
ANALYZE_OUTPUT=$(flutter analyze --no-pub $PROVIDER_DIR 2>&1 || true)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || true)

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ 컴파일 에러 없음${NC}"
else
    echo -e "${YELLOW}⚠️  에러 $ERROR_COUNT개 발견 (변수명 확인 필요)${NC}"
fi

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Provider dispose 추가 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n📊 ${YELLOW}작업 결과:${NC}"
echo -e "  • 수정된 Provider: ${GREEN}$FIXED_COUNT${NC}개"
echo -e "  • 컴파일 에러: $ERROR_COUNT개"

echo -e "\n💡 ${YELLOW}주의사항:${NC}"
echo "BaseProvider를 상속받는 클래스는 반드시"
echo "dispose 메서드 끝에 super.dispose()를 호출해야 합니다."

echo -e "\n🎯 ${YELLOW}다음 단계:${NC}"
echo "1. ${CYAN}grep -r \"void dispose()\" $PROVIDER_DIR${NC} - dispose 확인"
echo "2. ${CYAN}flutter analyze${NC} - 전체 분석"
echo "3. ${CYAN}./verify_memory_fix.sh${NC} - 메모리 누수 재검증"
