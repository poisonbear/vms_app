# 중복 코드 리팩토링 가이드

## 1. Import 최적화

### 변경 전
```dart
import 'package:flutter/material.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
// ... 많은 import들
```

### 변경 후
```dart
import 'package:vms_app/core/utils/common_imports.dart';
// 추가로 필요한 특별한 import만
```

## 2. 다이얼로그 통합

### 변경 전
```dart
showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: Text('제목'),
      content: Text('내용'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('확인'),
        ),
      ],
    );
  },
);
```

### 변경 후
```dart
DialogUtils.showConfirmDialog(
  context: context,
  title: '제목',
  message: '내용',
  onConfirm: () => print('확인됨'),
);
```

## 3. 권한 요청 통합

### 변경 전
```dart
// 각 화면에서 개별적으로 권한 요청
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  // 복잡한 로직...
}
```

### 변경 후
```dart
// 통합된 권한 관리자 사용
bool hasPermission = await UnifiedPermissionManager.requestLocationPermission(context);
if (hasPermission) {
  // 권한 있음
}
```

## 4. 적용 방법

1. **백업 생성**
   ```bash
   git add .
   git commit -m "리팩토링 전 백업"
   ```

2. **공통 유틸리티 import**
   ```dart
   // 각 파일 상단에 추가
   import 'package:vms_app/core/utils/dialog_utils.dart';
   import 'package:vms_app/core/utils/unified_permission_manager.dart';
   ```

3. **기존 코드 교체**
   - showDialog → DialogUtils 메서드
   - 권한 요청 → UnifiedPermissionManager 메서드

4. **테스트**
   ```bash
   flutter test
   flutter analyze
   ```

## 5. 체크리스트

- [ ] common_imports.dart 생성 완료
- [ ] dialog_utils.dart 생성 완료
- [ ] unified_permission_manager.dart 생성 완료
- [ ] 중복 showDialog 코드 교체
- [ ] 중복 권한 요청 코드 교체
- [ ] flutter analyze 에러 없음
- [ ] 앱 실행 테스트 완료
