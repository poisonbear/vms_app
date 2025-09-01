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
