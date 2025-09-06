# 남은 TODO 수동 처리 가이드

## 🔧 빠른 수정 명령어

### 1. Timer 관련 TODO 일괄 제거
```bash
# Timer TODO 주석만 제거 (코드는 유지)
find lib -name "*.dart" -exec sed -i '/\/\/ Timer?.*TimerService로 대체됨/d' {} \;
find lib -name "*.dart" -exec sed -i '/\/\/ TODO.*TimerService로 마이그레이션 필요/d' {} \;
```

### 2. StreamSubscription TODO 제거
```bash
# StreamSubscription 관련 TODO 제거
find lib -name "*.dart" -exec sed -i '/\/\/ TODO.*StreamSubscription을 List로 관리/,+1d' {} \;
```

### 3. 빈 TODO 제거
```bash
# 내용 없는 TODO 제거
find lib -name "*.dart" -exec sed -i '/\/\/ TODO$/d' {} \;
```

## 📝 파일별 수정 방법

### main_screen.dart
```dart
// 이미 TimerService로 마이그레이션 완료된 경우
// TODO 주석만 제거하면 됨
```

### Provider 파일들
```dart
@override
void dispose() {
  // 실제 리소스 정리 코드 추가
  _clearAllData();  // 데이터 클리어
  _cancelSubscriptions();  // 구독 취소
  super.dispose();
}
```

## ✅ 검증 방법
1. TODO 제거 후: `grep -r "TODO" lib/ --include="*.dart" | wc -l`
2. 컴파일 확인: `flutter analyze`
3. 메모리 누수 확인: `flutter run --profile`
