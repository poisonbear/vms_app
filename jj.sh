#!/bin/bash

# VMS App - 성능 측정 스크립트
# 실행 방법: Git Bash에서 프로젝트 루트 디렉토리에서 실행
# chmod +x measure_app_performance.sh && ./measure_app_performance.sh

echo "========================================="
echo "VMS App - 성능 측정 시작"
echo "========================================="

# 1. 특정 플랫폼으로 빌드 및 크기 분석 (arm64 기준)
echo ""
echo "📦 APK 빌드 및 크기 분석 (arm64)..."
echo "빌드 중... (2-3분 소요)"

flutter build apk --release --target-platform android-arm64 --analyze-size

# 2. APK 크기 확인
echo ""
echo "📊 APK 크기 정보:"

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    APK_SIZE_BYTES=$(du -b build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    APK_SIZE_MB=$((APK_SIZE_BYTES / 1024 / 1024))
    
    echo "✅ Release APK 크기: $APK_SIZE"
    
    # 목표 달성 여부 확인
    if [ $APK_SIZE_MB -lt 30 ]; then
        echo "🎉 목표 달성! (< 30MB)"
    else
        echo "⚠️  목표 초과 (목표: < 30MB)"
    fi
else
    echo "❌ APK 파일을 찾을 수 없습니다"
fi

# 3. 코드 크기 분석 결과 파싱
echo ""
echo "📈 코드 크기 상세 분석:"

if [ -f ".dart_tool/app_size/apk-code-size-analysis_01.json" ]; then
    python3 -c "
import json
import os

# 가장 최근 분석 파일 찾기
size_dir = '.dart_tool/app_size'
if os.path.exists(size_dir):
    files = [f for f in os.listdir(size_dir) if f.endswith('.json')]
    if files:
        latest_file = sorted(files)[-1]
        with open(os.path.join(size_dir, latest_file), 'r') as f:
            data = json.load(f)
            
            # 전체 크기
            total_size = data.get('precompressed_size', 0)
            print(f'총 크기: {total_size / 1024 / 1024:.2f} MB')
            print('')
            
            # 주요 구성 요소
            if 'children' in data:
                print('주요 구성 요소:')
                for child in sorted(data['children'], key=lambda x: x.get('precompressed_size', 0), reverse=True)[:10]:
                    name = child.get('n', 'Unknown')
                    size = child.get('precompressed_size', 0)
                    size_mb = size / 1024 / 1024
                    percentage = (size / total_size * 100) if total_size > 0 else 0
                    print(f'  - {name}: {size_mb:.2f} MB ({percentage:.1f}%)')
" 2>/dev/null || echo "Python 분석 실패 - 수동 확인 필요"
fi

# 4. 모든 플랫폼용 APK 빌드 (배포용)
echo ""
echo "📱 모든 플랫폼용 APK 빌드..."
read -p "모든 플랫폼용 APK를 빌드하시겠습니까? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    flutter build apk --release
    
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        FULL_APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
        echo "✅ 전체 플랫폼 APK 크기: $FULL_APK_SIZE"
    fi
fi

# 5. AAB (App Bundle) 빌드 옵션
echo ""
echo "📦 App Bundle 빌드 (Play Store 배포용)..."
read -p "App Bundle을 빌드하시겠습니까? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    flutter build appbundle --release
    
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
        echo "✅ App Bundle 크기: $AAB_SIZE"
    fi
fi

# 6. 성능 체크리스트
echo ""
echo "========================================="
echo "📊 성능 측정 결과 요약"
echo "========================================="

# APK 크기 체크
echo ""
echo "1. APK 크기:"
if [ -n "$APK_SIZE_MB" ]; then
    if [ $APK_SIZE_MB -lt 30 ]; then
        echo "   ✅ $APK_SIZE (목표: < 30MB) - 달성!"
    else
        echo "   ❌ $APK_SIZE (목표: < 30MB) - 최적화 필요"
    fi
else
    echo "   ⏳ 측정 필요"
fi

# 다음 단계 안내
echo ""
echo "2. 메모리 사용량 측정:"
echo "   다음 명령어로 프로파일 모드 실행:"
echo "   flutter run --profile"
echo "   실행 후 'M' 키를 눌러 메모리 확인"

echo ""
echo "3. 프레임 렌더링 (FPS):"
echo "   프로파일 모드에서 'P' 키를 눌러 성능 오버레이 확인"

echo ""
echo "4. 앱 시작 시간:"
echo "   실제 기기에서 측정 필요"
echo "   flutter run --release --trace-startup"

# 7. 최적화 제안
echo ""
echo "========================================="
echo "💡 추가 최적화 제안"
echo "========================================="

if [ -n "$APK_SIZE_MB" ] && [ $APK_SIZE_MB -gt 30 ]; then
    echo ""
    echo "APK 크기 줄이기:"
    echo "  1. 사용하지 않는 이미지 제거"
    echo "  2. 이미지를 WebP로 변환"
    echo "  3. ProGuard 규칙 최적화"
    echo "  4. 불필요한 패키지 제거"
fi

echo ""
echo "일반 최적화:"
echo "  1. flutter build apk --split-per-abi (ABI별 APK 생성)"
echo "  2. flutter build apk --obfuscate (코드 난독화)"
echo "  3. flutter build apk --tree-shake-icons (아이콘 최적화)"

# 8. 실행 파일 위치 안내
echo ""
echo "========================================="
echo "📁 빌드 파일 위치"
echo "========================================="
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
echo "크기 분석: .dart_tool/app_size/"

echo ""
echo "========================================="
echo "✅ 성능 측정 완료!"
echo "========================================="
