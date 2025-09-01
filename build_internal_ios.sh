#!/bin/bash

echo "=== 내부 배포용 iOS 빌드 ==="

# 버전 정보
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
DATE=$(date +%Y%m%d)

# 클린 빌드
flutter clean
flutter pub get

# iOS 빌드 (Ad Hoc 배포용)
flutter build ios --release \
  --dart-define=ENVIRONMENT=internal \
  --no-codesign

echo ""
echo "✅ iOS 빌드 완료"
echo "Xcode에서 Archive 후 Ad Hoc 배포 진행"
