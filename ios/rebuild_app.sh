#!/bin/bash
echo "🧹 Cleaning project..."
flutter clean
rm -rf build/
rm -rf .dart_tool/
rm -rf .packages
rm -rf pubspec.lock

# iOS 캐시 정리
cd ios
rm -rf Pods/
rm -rf Podfile.lock
rm -rf .symlinks/
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
pod cache clean --all
cd ..

# Android 캐시 정리  
cd android
./gradlew clean 2>/dev/null || true
cd ..

echo "📦 Installing dependencies..."
flutter pub get

echo "📱 iOS pod install..."
cd ios && pod install && cd ..

echo "✅ Ready to run!"
echo "Run: flutter run"
