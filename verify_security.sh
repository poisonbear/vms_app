#!/bin/bash

echo "=== 보안 적용 검증 ==="

# 1. 민감한 정보 노출 검사
echo "[1/4] 민감한 정보 노출 검사..."
SENSITIVE_PATTERNS=(
  "118.40.116.129"
  "kdn_.*_key"
  "password:"
  "user_pwd:"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  echo "Checking for: $pattern"
  grep -r "$pattern" lib/ --include="*.dart" | grep -v "secure" | head -5
done

# 2. AppLogger 사용 확인
echo "[2/4] 로그 사용 확인..."
echo "print 사용: $(grep -r "print(" lib/ --include="*.dart" | wc -l)건"
echo "AppLogger 사용: $(grep -r "AppLogger\." lib/ --include="*.dart" | wc -l)건"

# 3. ProGuard 설정 확인
echo "[3/4] ProGuard 설정 확인..."
if [ -f "android/app/proguard-rules.pro" ]; then
  echo "✅ ProGuard 파일 존재"
  grep "minifyEnabled" android/app/build.gradle
else
  echo "❌ ProGuard 파일 없음"
fi

# 4. 보안 파일 확인
echo "[4/4] 보안 파일 확인..."
FILES_TO_CHECK=(
  "lib/core/security/secure_api_manager.dart"
  "lib/core/security/app_initializer.dart"
  "lib/core/utils/app_logger.dart"
  "lib/core/services/secure_api_service.dart"
)

for file in "${FILES_TO_CHECK[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file"
  else
    echo "❌ $file (없음)"
  fi
done
