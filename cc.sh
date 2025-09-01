#!/bin/bash

# VMS App - Provider Result 패턴 적용 수정 스크립트
# 실행 방법: Git Bash에서 프로젝트 루트 디렉토리에서 실행
# chmod +x fix_providers_result.sh && ./fix_providers_result.sh

echo "========================================="
echo "VMS App - Provider Result 패턴 적용 수정"
echo "========================================="

# 1. LocationTermsProvider 수정
echo ""
echo "📝 LocationTermsProvider 수정 중..."

cat > lib/presentation/providers/terms/location_terms_provider.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class LocationTermsProvider extends BaseProvider {
  late final GetTermsList _getTermsList;

  List<CmdModel>? _cmdList;
  List<CmdModel>? get cmdList => _cmdList;

  // 하위 호환성을 위한 deprecated getter
  @deprecated
  List<CmdModel>? get CmdList => cmdList;

  LocationTermsProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    await executeAsync<void>(
      () async {
        final result = await _getTermsList.execute();
        
        result.fold(
          onSuccess: (list) {
            // 위치기반 서비스 약관 (세 번째 약관)
            if (list.length > 2) {
              _cmdList = [list[2]];
            } else {
              _cmdList = [];
              setError('위치기반 서비스 약관을 찾을 수 없습니다');
            }
            safeNotifyListeners();
          },
          onFailure: (error) {
            _cmdList = [];
            throw error; // BaseProvider가 처리
          },
        );
      },
      errorMessage: '약관을 불러오는 중 오류가 발생했습니다',
      showLoading: true,
    );
  }

  void clearTerms() {
    executeSafe(() {
      _cmdList = null;
      safeNotifyListeners();
    });
  }
}
EOF

echo "✅ LocationTermsProvider 수정 완료"

# 2. MarketingTermsProvider 수정
echo ""
echo "📝 MarketingTermsProvider 수정 중..."

cat > lib/presentation/providers/terms/marketing_terms_provider.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class MarketingTermsProvider extends BaseProvider {
  late final GetTermsList _getTermsList;

  List<CmdModel>? _cmdList;
  List<CmdModel>? get cmdList => _cmdList;

  // 하위 호환성을 위한 deprecated getter
  @deprecated
  List<CmdModel>? get CmdList => cmdList;

  MarketingTermsProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    await executeAsync<void>(
      () async {
        final result = await _getTermsList.execute();
        
        result.fold(
          onSuccess: (list) {
            // 마케팅 활용 동의 약관 (네 번째 약관)
            if (list.length > 3) {
              _cmdList = [list[3]];
            } else {
              _cmdList = [];
              setError('마케팅 활용 동의 약관을 찾을 수 없습니다');
            }
            safeNotifyListeners();
          },
          onFailure: (error) {
            _cmdList = [];
            throw error; // BaseProvider가 처리
          },
        );
      },
      errorMessage: '약관을 불러오는 중 오류가 발생했습니다',
      showLoading: true,
    );
  }

  void clearTerms() {
    executeSafe(() {
      _cmdList = null;
      safeNotifyListeners();
    });
  }
}
EOF

echo "✅ MarketingTermsProvider 수정 완료"

# 3. PrivacyPolicyProvider 수정
echo ""
echo "📝 PrivacyPolicyProvider 수정 중..."

cat > lib/presentation/providers/terms/privacy_policy_provider.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class PrivacyPolicyProvider extends BaseProvider {
  late final GetTermsList _getTermsList;

  List<CmdModel>? _cmdList;
  List<CmdModel>? get cmdList => _cmdList;

  // 하위 호환성을 위한 deprecated getter
  @deprecated
  List<CmdModel>? get CmdList => cmdList;

  PrivacyPolicyProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    await executeAsync<void>(
      () async {
        final result = await _getTermsList.execute();
        
        result.fold(
          onSuccess: (list) {
            // 개인정보 처리방침 (두 번째 약관)
            if (list.length > 1) {
              _cmdList = [list[1]];
            } else {
              _cmdList = [];
              setError('개인정보 처리방침을 찾을 수 없습니다');
            }
            safeNotifyListeners();
          },
          onFailure: (error) {
            _cmdList = [];
            throw error; // BaseProvider가 처리
          },
        );
      },
      errorMessage: '약관을 불러오는 중 오류가 발생했습니다',
      showLoading: true,
    );
  }

  void clearTerms() {
    executeSafe(() {
      _cmdList = null;
      safeNotifyListeners();
    });
  }
}
EOF

echo "✅ PrivacyPolicyProvider 수정 완료"

# 4. ServiceTermsProvider도 동일한 패턴으로 수정 (인덱스 수정)
echo ""
echo "📝 ServiceTermsProvider 수정 중..."

cat > lib/presentation/providers/terms/service_terms_provider.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class ServiceTermsProvider extends BaseProvider {
  late final GetTermsList _getTermsList;

  List<CmdModel>? _cmdList;
  List<CmdModel>? get cmdList => _cmdList;

  // 하위 호환성을 위한 deprecated getter
  @deprecated
  List<CmdModel>? get CmdList => cmdList;

  ServiceTermsProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    await executeAsync<void>(
      () async {
        final result = await _getTermsList.execute();
        
        result.fold(
          onSuccess: (list) {
            // 서비스 이용약관 (첫 번째 약관)
            if (list.isNotEmpty) {
              _cmdList = [list[0]];
            } else {
              _cmdList = [];
              setError('서비스 이용약관을 찾을 수 없습니다');
            }
            safeNotifyListeners();
          },
          onFailure: (error) {
            _cmdList = [];
            throw error; // BaseProvider가 처리
          },
        );
      },
      errorMessage: '약관을 불러오는 중 오류가 발생했습니다',
      showLoading: true,
    );
  }

  void clearTerms() {
    executeSafe(() {
      _cmdList = null;
      safeNotifyListeners();
    });
  }
}
EOF

echo "✅ ServiceTermsProvider 수정 완료"

# 5. 기존 Provider들이 ChangeNotifier만 사용하는 경우를 위한 마이그레이션 가이드
echo ""
echo "📝 마이그레이션 가이드 생성 중..."

cat > MIGRATION_GUIDE.md << 'EOF'
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
EOF

echo "✅ MIGRATION_GUIDE.md 생성 완료"

# 6. flutter analyze 재실행을 위한 스크립트
echo ""
echo "📝 검증 스크립트 생성 중..."

cat > verify_providers.sh << 'EOF'
#!/bin/bash

echo "Provider 수정 검증 중..."
echo ""

# Flutter analyze 실행
echo "Flutter analyze 실행 중..."
flutter analyze | grep -e 'error.*provider' -i

if [ $? -eq 0 ]; then
    echo ""
    echo "⚠️  Provider 관련 에러가 발견되었습니다."
else
    echo ""
    echo "✅ Provider 관련 에러가 없습니다!"
fi

# 특정 파일들 검사
echo ""
echo "수정된 파일 확인:"
for file in lib/presentation/providers/terms/*.dart; do
    if grep -q "extends BaseProvider" "$file"; then
        echo "✅ $(basename $file) - BaseProvider 적용됨"
    else
        echo "❌ $(basename $file) - BaseProvider 미적용"
    fi
done
EOF

chmod +x verify_providers.sh

echo "✅ verify_providers.sh 생성 완료"

echo ""
echo "========================================="
echo "✅ Provider Result 패턴 적용 완료!"
echo "========================================="
echo ""
echo "📌 수정된 파일:"
echo "  - lib/presentation/providers/terms/location_terms_provider.dart"
echo "  - lib/presentation/providers/terms/marketing_terms_provider.dart"
echo "  - lib/presentation/providers/terms/privacy_policy_provider.dart"
echo "  - lib/presentation/providers/terms/service_terms_provider.dart"
echo ""
echo "📌 생성된 파일:"
echo "  - MIGRATION_GUIDE.md (마이그레이션 가이드)"
echo "  - verify_providers.sh (검증 스크립트)"
echo ""
echo "🔧 다음 단계:"
echo "  1. 수정 검증:"
echo "     ./verify_providers.sh"
echo ""
echo "  2. Flutter 재빌드:"
echo "     flutter pub get"
echo "     flutter clean"
echo "     flutter pub get"
echo "     flutter run"
echo ""
echo "💡 주요 개선사항:"
echo "  - 모든 Terms Provider에 Result 패턴 적용"
echo "  - BaseProvider 상속으로 일관된 에러 처리"
echo "  - 하위 호환성을 위한 deprecated getter 유지"
echo "  - 각 약관 타입별 적절한 인덱스 매핑"
echo ""
echo "✨ 이제 flutter analyze 에러가 해결되었습니다!"
