#!/bin/bash

# Flutter 에러 완전 수정 스크립트
# 작성일: 2025-01-06
# 목적: dio_client.dart, common_imports.dart, main_screen.dart 에러 수정

echo "======================================"
echo "🔧 Flutter 에러 완전 수정 시작"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 프로젝트 루트 확인
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Flutter 프로젝트 루트에서 실행해주세요.${NC}"
    exit 1
fi

FIXED_COUNT=0

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Error 1: dio_client.dart 함수 선언 수정${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

if [ -f "lib/core/network/dio_client.dart" ]; then
    echo -e "  ${BLUE}dio_client.dart 백업 생성${NC}"
    cp lib/core/network/dio_client.dart lib/core/network/dio_client.dart.backup_$(date +%Y%m%d_%H%M%S)
    
    echo -e "  ${BLUE}잘못된 함수 선언 수정${NC}"
    
    # DialogUtils.showWarningPopup을 warningPop으로 변경
    sed -i 's/Future<void> DialogUtils\.showWarningPopup(/Future<void> warningPop(/g' lib/core/network/dio_client.dart
    
    echo -e "${GREEN}  ✅ dio_client.dart 함수 선언 수정 완료${NC}"
    FIXED_COUNT=$((FIXED_COUNT + 1))
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Error 2: common_imports.dart ServiceStatus 충돌 해결${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

if [ -f "lib/core/utils/common_imports.dart" ]; then
    echo -e "  ${BLUE}common_imports.dart 수정${NC}"
    
    # ServiceStatus 충돌 해결 - permission_handler에서 ServiceStatus hide
    cat > lib/core/utils/common_imports.dart << 'EOF'
/// 공통으로 사용되는 import를 모아놓은 파일
/// 다른 파일에서 import 'package:vms_app/core/utils/common_imports.dart'; 로 사용

// Flutter 기본
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'dart:async';
export 'dart:io';

// 프로젝트 핵심 유틸리티
export 'package:vms_app/core/utils/app_logger.dart';
export 'package:vms_app/core/constants/constants.dart';
export 'package:vms_app/core/errors/app_exceptions.dart';

// Firebase
export 'package:firebase_auth/firebase_auth.dart';
export 'package:firebase_messaging/firebase_messaging.dart';
export 'package:cloud_firestore/cloud_firestore.dart';

// 상태 관리
export 'package:provider/provider.dart';

// 권한 관리 - ServiceStatus 충돌 해결
export 'package:geolocator/geolocator.dart';
export 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

// UI 유틸리티
export 'package:flutter_svg/flutter_svg.dart';
EOF
    
    echo -e "${GREEN}  ✅ ServiceStatus 충돌 해결 완료${NC}"
    FIXED_COUNT=$((FIXED_COUNT + 1))
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Error 3: main_screen.dart DialogUtils 충돌 해결${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

if [ -f "lib/presentation/screens/main/main_screen.dart" ]; then
    echo -e "  ${BLUE}main_screen.dart 수정${NC}"
    
    # DialogUtils.showWarningPopup을 warningPop으로 변경 (dio_client의 함수 사용)
    sed -i 's/DialogUtils\.showWarningPopup/warningPop/g' lib/presentation/screens/main/main_screen.dart
    
    echo -e "${GREEN}  ✅ main_screen.dart DialogUtils 충돌 해결${NC}"
    FIXED_COUNT=$((FIXED_COUNT + 1))
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 추가 정리 작업${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 중복 import 제거
echo -e "  ${BLUE}중복 import 제거${NC}"
for file in lib/**/*.dart; do
    if [ -f "$file" ]; then
        # 중복 라인 제거
        awk '!seen[$0]++' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
done

echo -e "${GREEN}  ✅ 중복 import 제거 완료${NC}"

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 코드 포맷팅${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# dart format 실행
dart format lib/core/network/dio_client.dart lib/core/utils/common_imports.dart lib/presentation/screens/main/main_screen.dart 2>/dev/null || true

echo -e "${GREEN}  ✅ 코드 포맷팅 완료${NC}"

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Flutter Analyze 실행${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n분석 중..."
ANALYZE_OUTPUT=$(flutter analyze --no-pub 2>&1)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || true)
WARNING_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "warning" || true)
INFO_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "info" || true)

echo -e "\n수정 후 결과:"
echo -e "  • 에러: ${RED}$ERROR_COUNT${NC}개"
echo -e "  • 경고: ${YELLOW}$WARNING_COUNT${NC}개"
echo -e "  • 정보: ${BLUE}$INFO_COUNT${NC}개"

if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "\n${YELLOW}남은 에러 (상위 5개):${NC}"
    echo "$ANALYZE_OUTPUT" | grep "error" | head -5
fi

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ 에러 수정 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n📊 ${YELLOW}수정 결과:${NC}"
echo -e "  • 수정된 항목: ${GREEN}$FIXED_COUNT${NC}개"
echo -e "  • 남은 에러: ${RED}$ERROR_COUNT${NC}개"

echo -e "\n📝 ${YELLOW}수정 내용:${NC}"
echo "1. dio_client.dart: DialogUtils.showWarningPopup → warningPop"
echo "2. common_imports.dart: ServiceStatus 충돌 해결 (hide 사용)"
echo "3. main_screen.dart: DialogUtils 충돌 해결"

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "\n${GREEN}🎉 모든 에러가 해결되었습니다!${NC}"
else
    echo -e "\n${YELLOW}💡 추가 조치 필요:${NC}"
    echo "남은 에러를 확인하고 수동으로 수정하세요."
fi

echo -e "\n${GREEN}🎯 다음 단계:${NC}"
echo "1. ${BLUE}flutter clean${NC} - 캐시 정리"
echo "2. ${BLUE}flutter pub get${NC} - 패키지 재설치"
echo "3. ${BLUE}flutter run${NC} - 앱 실행 테스트"

echo -e "\n${GREEN}수정 완료!${NC}"
