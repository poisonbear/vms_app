#!/bin/bash

echo "=== 내부 배포용 APK 빌드 ==="

# 버전 정보
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
DATE=$(date +%Y%m%d)

# 클린 빌드
flutter clean
flutter pub get

# Android APK 빌드 (난독화 없이)
flutter build apk --release \
  --dart-define=ENVIRONMENT=internal \
  --no-shrink

# 파일명 변경
mv build/app/outputs/flutter-apk/app-release.apk \
   build/app/outputs/flutter-apk/vms_internal_${VERSION}_${DATE}.apk

echo ""
echo "✅ APK 생성 완료:"
echo "build/app/outputs/flutter-apk/vms_internal_${VERSION}_${DATE}.apk"
echo ""
echo "설치 방법:"
echo "adb install build/app/outputs/flutter-apk/vms_internal_${VERSION}_${DATE}.apk"
