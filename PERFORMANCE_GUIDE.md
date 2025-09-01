# VMS App 성능 최적화 가이드

## ✅ 적용된 최적화

### 1. 위젯 최적화
- **const 위젯 사용**: 리빌드 방지
- **RepaintBoundary**: 그리기 영역 분리
- **Keys 활용**: 위젯 트리 최적화

### 2. 이미지 최적화
- **캐싱 크기 제한**: cacheWidth, cacheHeight
- **Progressive 로딩**: 단계적 이미지 로딩
- **WebP 포맷**: 50-70% 크기 감소

### 3. 리스트 최적화
- **ListView.builder**: 필요한 아이템만 렌더링
- **itemExtent**: 고정 높이로 성능 향상
- **Pagination**: 대량 데이터 분할 로딩

### 4. API 캐싱
- **메모리 캐싱**: 빠른 응답
- **디스크 캐싱**: 오프라인 지원
- **캐시 만료**: 자동 갱신

### 5. 메모리 관리
- **자동 dispose**: 메모리 누수 방지
- **이미지 크기 제한**: 메모리 사용량 감소
- **약한 참조**: 순환 참조 방지

## 📊 성능 측정 방법

### Flutter DevTools 사용
```bash
# DevTools 실행
flutter pub global activate devtools
flutter pub global run devtools

# 앱 실행 (프로파일 모드)
flutter run --profile
```

### 성능 지표 확인
- **Frame Rendering Time**: < 16ms (60fps)
- **Memory Usage**: < 200MB
- **App Size**: < 30MB
- **Startup Time**: < 3초

## 🎯 체크리스트

### 개발 시
- [ ] const 생성자 사용
- [ ] StatelessWidget 우선 사용
- [ ] 불필요한 setState 제거
- [ ] Keys 적절히 사용

### 이미지
- [ ] 적절한 해상도 사용
- [ ] WebP 포맷 고려
- [ ] 캐싱 전략 수립

### 리스트
- [ ] ListView.builder 사용
- [ ] itemExtent 설정
- [ ] 페이지네이션 구현

### 네트워크
- [ ] API 응답 캐싱
- [ ] 이미지 캐싱
- [ ] 동시 요청 제한

### 릴리즈
- [ ] 디버그 로그 제거
- [ ] ProGuard 활성화
- [ ] 트리 쉐이킹
- [ ] 코드 난독화

## 🚀 추가 최적화 팁

1. **Isolate 활용**: 무거운 연산 분리
2. **Lazy Loading**: 필요할 때 로딩
3. **Debounce/Throttle**: 이벤트 제한
4. **Virtual Scrolling**: 대량 리스트
5. **Image Sprites**: 작은 아이콘 통합
