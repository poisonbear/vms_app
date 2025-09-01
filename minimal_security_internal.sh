#!/bin/bash

echo "=== 내부 배포용 최소 보안 설정 ==="
echo ""

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 간단한 Firestore 보안 규칙
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Firestore 기본 보안 규칙"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 인증된 사용자만 접근 (내부 사용자)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
EOF

echo -e "${GREEN}✅ 간단한 firestore.rules 생성${NC}"

# 2. .gitignore 업데이트 (중요!)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 민감한 파일 Git 제외"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat >> .gitignore << 'EOF'

# Firebase 설정 파일 (중요!)
**/google-services.json
**/GoogleService-Info.plist
.env
*.keystore
*.jks

# 백업 파일
*.backup
*.bak
*_backup_*
EOF

echo -e "${GREEN}✅ .gitignore 업데이트${NC}"

# 3. 환경 변수 분리 (개발/운영)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️ 환경 설정 분리"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# .env.example 생성 (실제 값 제외)
cat > .env.example << 'EOF'
# API 엔드포인트 (실제 값으로 교체)
kdn_loginForm_key=YOUR_LOGIN_API_URL
kdn_usm_select_role_data_key=YOUR_ROLE_API_URL

# Firebase (선택사항)
FIREBASE_PROJECT_ID=your-project-id
EOF

echo -e "${GREEN}✅ .env.example 생성${NC}"

# 4. 내부 배포용 빌드 스크립트
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 내부 배포 빌드 스크립트"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > build_internal.sh << 'EOF'
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
EOF

chmod +x build_internal.sh
echo -e "${GREEN}✅ build_internal.sh 생성${NC}"

# iOS용 빌드 스크립트
cat > build_internal_ios.sh << 'EOF'
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
EOF

chmod +x build_internal_ios.sh
echo -e "${GREEN}✅ build_internal_ios.sh 생성${NC}"

# 5. 체크리스트
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 내부 배포 체크리스트"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > internal_deployment_checklist.md << 'EOF'
# 내부 배포 체크리스트

## 최소 필수 보안 ✅
- [x] 비밀번호 로깅 제거
- [x] API 키를 .env 파일로 분리
- [x] .gitignore에 민감한 파일 추가
- [x] 기본 Firestore 인증 규칙

## 불필요한 것들 ❌
- App Check (마켓 미등록 시 작동 안 함)
- Play Integrity API (구글 플레이 전용)
- 복잡한 ProGuard 규칙 (내부용은 디버깅 편의를 위해 최소화)
- Certificate Pinning (내부 네트워크면 불필요)

## 배포 방법 📱

### Android
1. `./build_internal.sh` 실행
2. APK 파일을 직접 설치 또는 MDM으로 배포
3. 설정 → 보안 → 출처를 알 수 없는 앱 허용

### iOS  
1. Apple Developer Enterprise Program 가입 (연 $299)
   또는
2. Ad Hoc 배포 (최대 100대)
   - TestFlight 미사용
   - 직접 IPA 설치

## 사용자 관리 👥
- Firebase Auth로 충분
- 이메일/비밀번호 인증만 사용
- 사용자 수동 등록 (Firebase Console)

## 모니터링 📊
- Firebase Console에서 사용량 확인
- 비정상 트래픽 주기적 체크
- 월 1회 사용자 목록 검토
EOF

echo -e "${GREEN}✅ internal_deployment_checklist.md 생성${NC}"

# 6. 결과 요약
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 내부 배포용 최소 보안 설정 완료"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}필수 설정만 적용:${NC}"
echo "  • 기본 인증 규칙"
echo "  • 민감 정보 Git 제외"
echo "  • 환경 변수 분리"
echo ""
echo -e "${YELLOW}제외한 것들:${NC}"
echo "  • App Check (작동 안 함)"
echo "  • Play Integrity (마켓 전용)"
echo "  • 복잡한 보안 규칙"
echo ""
echo "빌드: ./build_internal.sh"
