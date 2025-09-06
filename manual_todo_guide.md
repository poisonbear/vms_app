# 수동 TODO 처리 가이드

## 1. Timer 마이그레이션 확인사항
- Timer.periodic → _timerService.startPeriodicTimer
- Timer() → _timerService.startOnceTimer
- timer?.cancel() → _timerService.stopTimer(timerId)

## 2. StreamController 처리
```dart
// dispose에 추가
await _streamController?.close();
```

## 3. 복잡한 리소스 정리
```dart
@override
void dispose() {
  // 애니메이션 컨트롤러
  _animationController?.dispose();
  
  // 텍스트 컨트롤러
  _textController?.dispose();
  
  // 포커스 노드
  _focusNode?.dispose();
  
  // 스크롤 컨트롤러  
  _scrollController?.dispose();
  
  // 타이머 서비스
  _timerService?.dispose();
  
  super.dispose();
}
```

## 4. 메모리 누수 체크
- 앱 실행 후 DevTools → Memory 탭 확인
- 화면 전환 시 인스턴스 수 확인
- dispose 후 리소스 해제 확인
