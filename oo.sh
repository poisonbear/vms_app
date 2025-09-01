#!/bin/bash

echo "=== AppLogger 타입 오류 수정 ==="
echo "시작 시간: $(date +%H:%M:%S)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. load_location.dart 수정
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[1/3] load_location.dart 타입 오류 수정"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Line 196: Position 객체를 String으로 변환
sed -i '196s/AppLogger\.d(position);/AppLogger.d("Position: lat=\${position.latitude}, lng=\${position.longitude}");/' lib/core/utils/load_location.dart

# Line 322: Stream<Position>을 String으로 변환
sed -i '322s/AppLogger\.d(_geolocatorPlatform\.getPositionStream());/AppLogger.d("Position stream started");/' lib/core/utils/load_location.dart

echo -e "${GREEN}✅ load_location.dart 수정 완료${NC}"

# 2. login_screen.dart 수정
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[2/3] login_screen.dart 타입 오류 수정"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Line 126: int?를 String으로 변환
sed -i '126s/AppLogger\.d(response\.statusCode);/AppLogger.d("Response status code: \${response.statusCode}");/' lib/presentation/screens/auth/login_screen.dart

echo -e "${GREEN}✅ login_screen.dart 수정 완료${NC}"

# 3. 중복 import 제거
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[3/3] 중복 import 제거"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# login_screen.dart의 중복 import 제거
echo "login_screen.dart 중복 import 제거 중..."
cat > temp_login.dart << 'EOF'
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/screens/auth/terms_agreement_screen.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
EOF

# 파일의 나머지 부분 추가 (import 이후 부분)
sed -n '/^class LoginView/,$p' lib/presentation/screens/auth/login_screen.dart >> temp_login.dart

# 원본 파일 교체
mv temp_login.dart lib/presentation/screens/auth/login_screen.dart

echo -e "${GREEN}✅ login_screen.dart 중복 import 제거 완료${NC}"

# load_location.dart의 중복 import 제거  
echo "load_location.dart 중복 import 제거 중..."
cat > temp_location.dart << 'EOF'
import 'dart:async';
import 'dart:io' show Platform;
import 'package:baseflow_plugin_template/baseflow_plugin_template.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vms_app/core/utils/app_logger.dart';
EOF

# 파일의 나머지 부분 추가 (import 이후 부분)
sed -n '/^\/\/ Defines the main theme color/,$p' lib/core/utils/load_location.dart >> temp_location.dart

# 원본 파일 교체
mv temp_location.dart lib/core/utils/load_location.dart

echo -e "${GREEN}✅ load_location.dart 중복 import 제거 완료${NC}"

# 4. 검증
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 수정 결과 검증"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Flutter 분석 실행
echo "Flutter 분석 실행 중..."
flutter analyze --no-fatal-warnings > analyze_result.txt 2>&1

# 타입 오류 확인
TYPE_ERRORS=$(grep -c "argument_type_not_assignable" analyze_result.txt 2>/dev/null || echo "0")

if [ "$TYPE_ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✅ 모든 타입 오류 해결됨${NC}"
else
    echo -e "${YELLOW}⚠️ 남은 타입 오류: ${TYPE_ERRORS}건${NC}"
    echo "상세 내용:"
    grep "argument_type_not_assignable" analyze_result.txt | head -5
fi

# 중복 import 확인
echo ""
echo "중복 import 검사 중..."
DUPLICATE_IMPORTS_LOGIN=$(grep -c "import.*app_logger" lib/presentation/screens/auth/login_screen.dart)
DUPLICATE_IMPORTS_LOCATION=$(grep -c "import.*app_logger" lib/core/utils/load_location.dart)

echo "login_screen.dart - app_logger import: ${DUPLICATE_IMPORTS_LOGIN}개"
echo "load_location.dart - app_logger import: ${DUPLICATE_IMPORTS_LOCATION}개"

if [ "$DUPLICATE_IMPORTS_LOGIN" -eq 1 ] && [ "$DUPLICATE_IMPORTS_LOCATION" -eq 1 ]; then
    echo -e "${GREEN}✅ 중복 import 제거 완료${NC}"
else
    echo -e "${YELLOW}⚠️ 중복 import가 남아있을 수 있습니다${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 타입 오류 수정 완료"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "다음 단계:"
echo "1. flutter analyze 실행하여 오류 확인"
echo "2. 필요시 추가 수정"
echo ""
echo "완료 시간: $(date +%H:%M:%S)"
