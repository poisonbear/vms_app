#!/bin/bash

echo "========================================="
echo "Flutter 앱 성능 프로파일링"
echo "========================================="

# 1. Release 빌드 생성
echo ""
echo "📦 Release APK 빌드 중..."
flutter build apk --release --analyze-size

# 2. APK 크기 분석
echo ""
echo "📊 APK 크기 분석:"
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "✅ Release APK 크기: $APK_SIZE"
    
    # 상세 분석
    echo ""
    echo "📈 APK 구성 요소별 크기:"
    unzip -l build/app/outputs/flutter-apk/app-release.apk | tail -n 10
else
    echo "❌ Release APK를 찾을 수 없습니다"
fi

# 3. 번들 사이즈 리포트
echo ""
echo "📊 번들 사이즈 상세 리포트:"
if [ -f "build/app-size-analysis.json" ]; then
    python -c "
import json
with open('build/app-size-analysis.json', 'r') as f:
    data = json.load(f)
    print(f\"Total Size: {data.get('precompressed-size', 0) / 1024 / 1024:.2f} MB\")
    if 'children' in data:
        for child in data['children'][:5]:
            size_mb = child.get('precompressed-size', 0) / 1024 / 1024
            print(f\"  - {child.get('n', 'Unknown')}: {size_mb:.2f} MB\")
    "
fi

# 4. 메모리 사용량 체크 (디버그 모드)
echo ""
echo "💾 메모리 사용량 체크를 위한 디버그 실행:"
echo "다음 명령어를 실행하여 메모리 프로파일링을 시작하세요:"
echo ""
echo "  flutter run --profile"
echo ""
echo "앱이 실행되면:"
echo "  1. 'M' 키를 눌러 메모리 정보 확인"
echo "  2. 'P' 키를 눌러 성능 오버레이 표시"
echo "  3. 'w' 키를 눌러 위젯 인스펙터 실행"

# 5. Flutter analyze 실행
echo ""
echo "🔍 코드 품질 분석:"
flutter analyze --no-fatal-infos | head -20

echo ""
echo "========================================="
echo "성능 프로파일링 완료"
echo "========================================="
echo ""
echo "🎯 성능 목표 달성 체크리스트:"
echo "  □ APK 크기 < 30MB"
echo "  □ 메모리 사용량 < 200MB"
echo "  □ 앱 시작 시간 < 3초"
echo "  □ 스크롤 성능 60fps"
echo ""
echo "📱 실제 기기에서 테스트하려면:"
echo "  flutter run --release"
