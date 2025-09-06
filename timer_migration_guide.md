# Timer → TimerService 마이그레이션 가이드

## 변경 전 (Timer 직접 사용)
```dart
Timer? _timer;

@override
void initState() {
  super.initState();
  _timer = Timer.periodic(Duration(seconds: 3), (_) {
    _updateData();
  });
}

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```

## 변경 후 (TimerService 사용)
```dart
late TimerService _timerService;

@override
void initState() {
  super.initState();
  _timerService = TimerService();
  _timerService.startPeriodicTimer(
    timerId: 'data_update',
    duration: Duration(seconds: 3),
    callback: _updateData,
  );
}

@override
void dispose() {
  _timerService.dispose();
  super.dispose();
}
```
