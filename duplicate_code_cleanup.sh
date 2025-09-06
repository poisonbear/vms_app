#!/bin/bash

# Flutter 프로젝트 중복 코드 정리 스크립트
# 작성일: 2025-01-06
# 목적: 중복된 import, 다이얼로그 패턴, 유틸리티 코드 정리

echo "======================================"
echo "🧹 중복 코드 정리 시작"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 프로젝트 루트 확인
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Flutter 프로젝트 루트에서 실행해주세요.${NC}"
    exit 1
fi

FIXED_COUNT=0
DUPLICATE_COUNT=0

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 1: 중복 Import 분석${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 중복 import 패턴 분석
echo -e "\n${BLUE}1.1 가장 많이 사용되는 import 확인${NC}"
echo "----------------------------------------"

# 임시 파일 생성
IMPORT_STATS="import_stats.txt"
> "$IMPORT_STATS"

# 모든 dart 파일에서 import 추출 및 카운트
find lib -name "*.dart" -type f -exec grep "^import " {} \; | \
    sort | uniq -c | sort -rn | head -20 > "$IMPORT_STATS"

echo -e "${GREEN}Top 20 중복 import:${NC}"
cat "$IMPORT_STATS"

# 공통 import 파일 생성
echo -e "\n${BLUE}1.2 공통 import 파일 생성${NC}"
echo "----------------------------------------"

cat > lib/core/utils/common_imports.dart << 'EOF'
/// 공통으로 사용되는 import를 모아놓은 파일
/// 다른 파일에서 export 'package:vms_app/core/utils/common_imports.dart'; 로 사용

// Flutter 기본
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'dart:async';
export 'dart:io';

// 프로젝트 핵심 유틸리티
export 'package:vms_app/core/utils/app_logger.dart';
export 'package:vms_app/core/constants/constants.dart';
export 'package:vms_app/core/errors/app_exceptions.dart';

// Firebase
export 'package:firebase_auth/firebase_auth.dart';
export 'package:firebase_messaging/firebase_messaging.dart';
export 'package:cloud_firestore/cloud_firestore.dart';

// 상태 관리
export 'package:provider/provider.dart';

// 권한 관리
export 'package:geolocator/geolocator.dart';
export 'package:permission_handler/permission_handler.dart';

// UI 유틸리티
export 'package:flutter_svg/flutter_svg.dart';
EOF

echo -e "${GREEN}  ✅ common_imports.dart 생성 완료${NC}"
FIXED_COUNT=$((FIXED_COUNT + 1))

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 2: 다이얼로그 패턴 통합${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${BLUE}2.1 공통 다이얼로그 유틸리티 생성${NC}"
echo "----------------------------------------"

cat > lib/core/utils/dialog_utils.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 공통 다이얼로그 유틸리티 클래스
class DialogUtils {
  
  /// 기본 확인 다이얼로그
  static Future<void> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '확인',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
    Color? titleColor,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              color: titleColor ?? Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                child: Text(cancelText),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: titleColor ?? Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 권한 요청 다이얼로그
  static Future<void> showPermissionDialog({
    required BuildContext context,
    required String permissionType,
    required String message,
    required VoidCallback onOpenSettings,
    VoidCallback? onExit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionType 권한 필요'),
          content: Text('$message\n권한을 허용하지 않으면 앱을 사용할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: onOpenSettings,
              child: const Text('설정 열기'),
            ),
            if (onExit != null)
              TextButton(
                onPressed: onExit,
                child: const Text('앱 종료'),
              ),
          ],
        );
      },
    );
  }

  /// 로딩 다이얼로그
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(message),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 로딩 다이얼로그 닫기
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// 에러 다이얼로그
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = '확인',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 성공 다이얼로그
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = '확인',
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 커스텀 경고 팝업 (warningPop 대체)
  static Future<void> showWarningPopup({
    required BuildContext context,
    required String title,
    required String detail,
    String? additionalInfo,
    Color titleColor = Colors.orange,
    Color shadowColor = Colors.black,
    String? iconPath,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            // 배경
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      shadowColor.withOpacity(0.1),
                      shadowColor.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ),
            // 팝업 내용
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (iconPath != null)
                        Image.asset(iconPath, width: 64, height: 64),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        detail,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      if (additionalInfo != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            additionalInfo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: titleColor,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
EOF

echo -e "${GREEN}  ✅ dialog_utils.dart 생성 완료${NC}"
FIXED_COUNT=$((FIXED_COUNT + 1))

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 3: 권한 관리 통합${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${BLUE}3.1 권한 관리 리팩토링${NC}"
echo "----------------------------------------"

# permission_manager.dart 백업
if [ -f "lib/core/utils/permission_manager.dart" ]; then
    cp lib/core/utils/permission_manager.dart lib/core/utils/permission_manager.dart.backup
    echo -e "${GREEN}  ✅ permission_manager.dart 백업 완료${NC}"
fi

# 개선된 권한 관리자 생성
cat > lib/core/utils/unified_permission_manager.dart << 'EOF'
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/utils/dialog_utils.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 통합 권한 관리 클래스
class UnifiedPermissionManager {
  static bool _openedSettings = false;

  /// 모든 필수 권한 요청
  static Future<void> requestAllPermissions(BuildContext context) async {
    await requestLocationPermission(context);
    await requestNotificationPermission(context);
  }

  /// 위치 권한 요청
  static Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await DialogUtils.showConfirmDialog(
          context: context,
          title: '위치 서비스 필요',
          message: '위치 서비스가 꺼져 있습니다.\n설정에서 위치 서비스를 활성화해 주세요.',
          confirmText: '설정 열기',
          onConfirm: () async {
            await Geolocator.openLocationSettings();
          },
        );
        return false;
      }

      // 권한 상태 확인
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.d('❌ 위치 권한 거부됨');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await DialogUtils.showPermissionDialog(
          context: context,
          permissionType: '위치',
          message: '위치 권한이 영구적으로 거부되었습니다.',
          onOpenSettings: () async {
            _openedSettings = true;
            await openAppSettings();
          },
          onExit: () => exit(0),
        );
        return false;
      }

      AppLogger.d('✅ 위치 권한 허용됨');
      return true;
    } catch (e) {
      AppLogger.e('위치 권한 요청 오류', e);
      return false;
    }
  }

  /// 알림 권한 요청
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.d('✅ 알림 권한 허용됨');
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await DialogUtils.showPermissionDialog(
          context: context,
          permissionType: '알림',
          message: '알림 권한이 거부되었습니다.',
          onOpenSettings: () async {
            _openedSettings = true;
            await openAppSettings();
          },
          onExit: () => exit(0),
        );
        return false;
      }

      return false;
    } catch (e) {
      AppLogger.e('알림 권한 요청 오류', e);
      return false;
    }
  }

  /// 권한 상태 확인
  static Future<Map<String, bool>> checkPermissions() async {
    Map<String, bool> permissions = {};

    // 위치 권한
    LocationPermission locationPermission = await Geolocator.checkPermission();
    permissions['location'] = locationPermission == LocationPermission.whileInUse || 
                              locationPermission == LocationPermission.always;

    // 알림 권한
    NotificationSettings notificationSettings = 
        await FirebaseMessaging.instance.getNotificationSettings();
    permissions['notification'] = 
        notificationSettings.authorizationStatus == AuthorizationStatus.authorized;

    return permissions;
  }
}
EOF

echo -e "${GREEN}  ✅ unified_permission_manager.dart 생성 완료${NC}"
FIXED_COUNT=$((FIXED_COUNT + 1))

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 4: 중복 패턴 찾기 및 수정${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${BLUE}4.1 showDialog 패턴 분석${NC}"
echo "----------------------------------------"

DIALOG_COUNT=$(grep -r "showDialog" lib/ --include="*.dart" | wc -l)
echo -e "showDialog 사용 횟수: ${YELLOW}$DIALOG_COUNT${NC}개"

# Navigator.pop() 패턴 분석
POP_COUNT=$(grep -r "Navigator.of(context).pop()" lib/ --include="*.dart" | wc -l)
echo -e "Navigator.pop() 사용 횟수: ${YELLOW}$POP_COUNT${NC}개"

echo -e "\n${BLUE}4.2 중복 함수 패턴 추출${NC}"
echo "----------------------------------------"

# 유사한 함수명 찾기
echo -e "\n${GREEN}유사한 함수명 패턴:${NC}"
grep -h "^[[:space:]]*Future<.*> \|^[[:space:]]*void " lib/**/*.dart 2>/dev/null | \
    sed 's/^[[:space:]]*//' | \
    sort | uniq -c | sort -rn | \
    awk '$1 > 1 {print "  • " $0}' | head -10

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 5: 리팩토링 가이드 생성${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

cat > refactoring_guide.md << 'EOF'
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
EOF

echo -e "${GREEN}  ✅ refactoring_guide.md 생성 완료${NC}"
FIXED_COUNT=$((FIXED_COUNT + 1))

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 6: 자동 수정 스크립트 생성${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

cat > apply_refactoring.sh << 'SCRIPT'
#!/bin/bash

# 중복 코드 자동 교체 스크립트

echo "🔄 중복 코드 자동 교체 시작..."

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPLACED_COUNT=0

# 1. warningPop을 DialogUtils.showWarningPopup으로 교체
echo -e "\n${YELLOW}warningPop → DialogUtils.showWarningPopup 교체${NC}"
for file in $(find lib -name "*.dart" -type f); do
    if grep -q "warningPop(" "$file"; then
        # import 추가 (없는 경우)
        if ! grep -q "import.*dialog_utils" "$file"; then
            sed -i '1a\import '\''package:vms_app/core/utils/dialog_utils.dart'\'';' "$file"
        fi
        
        # 함수 교체
        sed -i 's/warningPop(/DialogUtils.showWarningPopup(/g' "$file"
        
        echo -e "  ✅ $(basename $file) 수정됨"
        REPLACED_COUNT=$((REPLACED_COUNT + 1))
    fi
done

# 2. 단순 showDialog를 DialogUtils로 교체
echo -e "\n${YELLOW}단순 AlertDialog → DialogUtils 교체${NC}"
for file in $(find lib -name "*.dart" -type f); do
    # 패턴: showDialog with simple AlertDialog
    if grep -q "showDialog.*AlertDialog" "$file"; then
        echo -e "  📝 $(basename $file) - 수동 검토 필요"
    fi
done

echo -e "\n${GREEN}✅ 자동 교체 완료: $REPLACED_COUNT개 파일${NC}"
echo "수동 검토가 필요한 파일은 위에 표시되었습니다."
SCRIPT

chmod +x apply_refactoring.sh
echo -e "${GREEN}  ✅ apply_refactoring.sh 생성 완료${NC}"

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Phase 7: 중복 코드 통계${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 중복 라인 수 계산
echo -e "\n${BLUE}7.1 예상 절감 라인 수${NC}"
echo "----------------------------------------"

# AppLogger.d 중복
LOGGER_LINES=$(grep -r "AppLogger\.d(" lib/ --include="*.dart" | wc -l)
echo -e "AppLogger.d 호출: ${YELLOW}$LOGGER_LINES${NC}줄"

# showDialog 중복
DIALOG_LINES=$(grep -r "showDialog" lib/ --include="*.dart" -A 20 | wc -l)
ESTIMATED_SAVINGS=$((DIALOG_LINES / 2))
echo -e "다이얼로그 코드 예상 절감: 약 ${GREEN}$ESTIMATED_SAVINGS${NC}줄"

# Navigator.pop 중복
NAV_POP_LINES=$(grep -r "Navigator.of(context).pop()" lib/ --include="*.dart" | wc -l)
echo -e "Navigator.pop 패턴: ${YELLOW}$NAV_POP_LINES${NC}개"

TOTAL_DUPLICATES=$((LOGGER_LINES + ESTIMATED_SAVINGS))
echo -e "\n총 중복 라인 수: 약 ${RED}$TOTAL_DUPLICATES${NC}줄"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ 중복 코드 정리 준비 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n📊 ${YELLOW}생성된 파일:${NC}"
echo -e "  • ${CYAN}lib/core/utils/common_imports.dart${NC} - 공통 import"
echo -e "  • ${CYAN}lib/core/utils/dialog_utils.dart${NC} - 다이얼로그 유틸리티"
echo -e "  • ${CYAN}lib/core/utils/unified_permission_manager.dart${NC} - 통합 권한 관리"
echo -e "  • ${CYAN}refactoring_guide.md${NC} - 리팩토링 가이드"
echo -e "  • ${CYAN}apply_refactoring.sh${NC} - 자동 교체 스크립트"
echo -e "  • ${CYAN}import_stats.txt${NC} - import 통계"

echo -e "\n🎯 ${YELLOW}다음 단계:${NC}"
echo "1. ${BLUE}cat refactoring_guide.md${NC} - 가이드 확인"
echo "2. ${BLUE}./apply_refactoring.sh${NC} - 자동 교체 실행"
echo "3. ${BLUE}flutter analyze${NC} - 코드 분석"
echo "4. ${BLUE}flutter test${NC} - 테스트 실행"

echo -e "\n💡 ${YELLOW}권장사항:${NC}"
echo "• 변경 전 git commit으로 백업"
echo "• 단계별로 적용하며 테스트"
echo "• 복잡한 다이얼로그는 수동 검토"

echo -e "\n${GREEN}스크립트 실행 완료!${NC}"
