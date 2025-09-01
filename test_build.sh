#!/bin/bash

echo "=== 빌드 테스트 시작 ==="

# 1. 클린
echo "[1/3] 프로젝트 클린..."
flutter clean

# 2. 패키지 설치
echo "[2/3] 패키지 설치..."
flutter pub get

# 3. 빌드 테스트
echo "[3/3] 빌드 테스트..."

# 디버그 빌드
echo "Debug 빌드..."
flutter build apk --debug --no-tree-shake-icons

if [ $? -eq 0 ]; then
  echo "✅ Debug 빌드 성공"
  echo "APK 위치: build/app/outputs/flutter-apk/app-debug.apk"
else
  echo "❌ Debug 빌드 실패"
  exit 1
fi

# 릴리즈 빌드 (선택사항)
read -p "릴리즈 빌드도 테스트하시겠습니까? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Release 빌드..."
  flutter build apk --release --no-tree-shake-icons
  
  if [ $? -eq 0 ]; then
    echo "✅ Release 빌드 성공"
    echo "APK 위치: build/app/outputs/flutter-apk/app-release.apk"
    
    # APK 크기 비교
    DEBUG_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    RELEASE_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "Debug APK: $DEBUG_SIZE"
    echo "Release APK: $RELEASE_SIZE (난독화 적용)"
  else
    echo "❌ Release 빌드 실패"
  fi
fi
