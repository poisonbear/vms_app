# Provider 마이그레이션 가이드

## 기존 Provider (ChangeNotifier) → BaseProvider 마이그레이션

### 변경 전:
```dart
class MyProvider with ChangeNotifier {
  List<Model> _data = [];
  
  Future<void> loadData() async {
    try {
      _data = await repository.getData();
      notifyListeners();
    } catch (e) {
      // 에러 처리
    }
  }
}
```

### 변경 후:
```dart
class MyProvider extends BaseProvider {
  List<Model> _data = [];
  
  Future<void> loadData() async {
    await executeAsync<void>(
      () async {
        final result = await repository.getData();
        result.fold(
          onSuccess: (data) {
            _data = data;
            safeNotifyListeners();
          },
          onFailure: (error) {
            _data = [];
            throw error; // BaseProvider가 처리
          },
        );
      },
      errorMessage: '데이터를 불러오는 중 오류가 발생했습니다',
      showLoading: true,
    );
  }
}
```

## 주요 변경사항:

1. **상속 변경**: `with ChangeNotifier` → `extends BaseProvider`
2. **에러 처리**: try-catch → `executeAsync` + Result 패턴
3. **상태 알림**: `notifyListeners()` → `safeNotifyListeners()`
4. **로딩 상태**: BaseProvider가 자동 관리
5. **에러 메시지**: BaseProvider가 자동 관리

## BaseProvider 제공 기능:

- `isLoading`: 로딩 상태
- `errorMessage`: 에러 메시지
- `hasError`: 에러 여부
- `executeAsync`: 비동기 작업 래퍼
- `executeSafe`: 동기 작업 래퍼
- `safeNotifyListeners`: 안전한 상태 알림
