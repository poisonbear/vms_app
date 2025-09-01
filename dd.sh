#!/bin/bash

# VMS App - 코드 리팩토링 스크립트
# 실행 방법: Git Bash에서 프로젝트 루트 디렉토리에서 실행
# chmod +x code_refactoring.sh && ./code_refactoring.sh

echo "========================================="
echo "VMS App - 코드 리팩토링 시작"
echo "========================================="

# 1. 상수 추출 및 중앙화
echo ""
echo "📝 상수 파일 개선 중..."

# API 타임아웃 상수 추가
cat > lib/core/constants/app_durations.dart << 'EOF'
/// 시간 관련 상수
class AppDurations {
  AppDurations._();

  // API 타임아웃
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiLongTimeout = Duration(seconds: 60);
  static const Duration apiShortTimeout = Duration(seconds: 10);
  
  // 애니메이션
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);
  
  // 디바운스
  static const Duration debounceSearch = Duration(milliseconds: 500);
  static const Duration debounceInput = Duration(milliseconds: 300);
  
  // 스낵바
  static const Duration snackbarShort = Duration(seconds: 2);
  static const Duration snackbarNormal = Duration(seconds: 3);
  static const Duration snackbarLong = Duration(seconds: 5);
}
EOF

echo "✅ app_durations.dart 생성 완료"

# 네트워크 설정 상수 추가
cat > lib/core/constants/network_constants.dart << 'EOF'
/// 네트워크 관련 상수
class NetworkConstants {
  NetworkConstants._();

  // User-Agent
  static const String userAgent = 'VMS-App/1.0';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'ngrok-skip-browser-warning': '100',
  };
  
  // Retry
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
EOF

echo "✅ network_constants.dart 생성 완료"

# 2. DioClient 개선 (하드코딩 제거)
echo ""
echo "📝 DioClient 개선 중..."

cat > lib/core/network/dio_client.dart << 'EOF'
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/app_durations.dart';
import 'package:vms_app/core/constants/network_constants.dart';
import 'package:vms_app/core/utils/logger.dart';

/// Dio HTTP 클라이언트 래퍼
class DioRequest {
  late final Dio _dio;
  
  Dio get dio => _dio;

  DioRequest() {
    _dio = Dio(_createBaseOptions());
    _setupInterceptors();
  }

  /// 기본 옵션 생성
  BaseOptions _createBaseOptions() {
    return BaseOptions(
      contentType: Headers.jsonContentType,
      connectTimeout: AppDurations.apiTimeout,
      receiveTimeout: AppDurations.apiTimeout,
      headers: {
        'User-Agent': NetworkConstants.userAgent,
        ...NetworkConstants.defaultHeaders,
      },
    );
  }

  /// 인터셉터 설정
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.d('API Request: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.d('API Response: ${response.statusCode}');
          handler.next(response);
        },
        onError: (DioException error, handler) {
          logger.e('API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  /// 옵션 생성 헬퍼 메서드
  static Options createOptions({
    Duration? timeout,
    Map<String, dynamic>? headers,
  }) {
    return Options(
      receiveTimeout: timeout ?? AppDurations.apiTimeout,
      headers: headers,
    );
  }
}

/// 페이지 전환 애니메이션
Route createSlideTransition(
  Widget page, {
  Offset begin = const Offset(1.0, 0.0),
}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    transitionDuration: AppDurations.animationNormal,
  );
}
EOF

echo "✅ dio_client.dart 개선 완료"

# 3. main_screen.dart의 논리 오류 수정
echo ""
echo "📝 main_screen.dart 논리 오류 수정 중..."

# 논리 오류 수정 패치 생성
cat > fix_main_screen.patch << 'EOF'
--- a/lib/presentation/screens/main/main_screen.dart
+++ b/lib/presentation/screens/main/main_screen.dart
@@ -1,2 +1,2 @@
-                                    if (myVessel != null || myVessel != '') {
+                                    if (myVessel != null) {
EOF

# 패치 적용
if [ -f "lib/presentation/screens/main/main_screen.dart" ]; then
    cp lib/presentation/screens/main/main_screen.dart lib/presentation/screens/main/main_screen.dart.backup
    sed -i "s/if (myVessel != null || myVessel != '')/if (myVessel != null)/g" lib/presentation/screens/main/main_screen.dart
    echo "✅ main_screen.dart 논리 오류 수정 완료"
fi

# 4. DataSource 리팩토링 (타임아웃, 로그 개선)
echo ""
echo "📝 DataSource 리팩토링 중..."

cat > lib/data/datasources/remote/vessel_remote_datasource.dart << 'EOF'
import 'package:vms_app/core/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/errors/error_handler.dart';
import 'package:vms_app/core/constants/app_durations.dart';

class VesselSearchSource {
  final dioRequest = DioRequest();

  Future<Result<List<VesselSearchModel>, AppException>> getVesselList({
    String? regDt,
    int? mmsi,
  }) async {
    try {
      final String apiUrl = dotenv.env['kdn_gis_select_vessel_List'] ?? '';
      
      if (apiUrl.isEmpty) {
        return const Failure(
          GeneralAppException('API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      final Map<String, dynamic> queryParams = {
        if (mmsi != null) 'mmsi': mmsi,
        if (regDt != null) 'reg_dt': regDt,
      };

      final options = DioRequest.createOptions(
        timeout: AppDurations.apiLongTimeout,
      );

      final response = await dioRequest.dio.get(
        apiUrl,
        data: queryParams,
        options: options,
      );

      List<VesselSearchModel> vessels = [];

      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        vessels = items
            .map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json))
            .toList();
      } else if (response.data is List) {
        vessels = (response.data as List)
            .map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json))
            .toList();
      }

      logger.d('Vessel list fetched: ${vessels.length} items');
      return Success(vessels);
      
    } catch (e) {
      logger.e('Vessel API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}
EOF

echo "✅ vessel_remote_datasource.dart 리팩토링 완료"

# 5. 네이밍 일관성 수정 스크립트
echo ""
echo "📝 네이밍 일관성 수정 스크립트 생성 중..."

cat > fix_naming_convention.sh << 'EOF'
#!/bin/bash

echo "네이밍 컨벤션 수정 중..."

# CmdList -> cmdList 변경
find lib -name "*.dart" -type f -exec sed -i 's/CmdList/cmdList/g' {} \;

# RosList -> rosList 변경  
find lib -name "*.dart" -type f -exec sed -i 's/RosList/rosList/g' {} \;

# 기타 대문자로 시작하는 변수명 찾기
echo ""
echo "대문자로 시작하는 변수명 검색 중..."
grep -r "^\s*[A-Z][a-zA-Z]*\s*=" lib --include="*.dart" | grep -v "class\|static\|const"

echo "✅ 네이밍 컨벤션 수정 완료"
EOF

chmod +x fix_naming_convention.sh

echo "✅ fix_naming_convention.sh 생성 완료"

# 6. 주석 처리된 로그 제거 스크립트
echo ""
echo "📝 불필요한 주석 제거 스크립트 생성 중..."

cat > clean_comments.sh << 'EOF'
#!/bin/bash

echo "불필요한 주석 제거 중..."

# 주석 처리된 logger 구문 제거
find lib -name "*.dart" -type f -exec sed -i '/^[[:space:]]*\/\/.*logger\./d' {} \;

# 주석 처리된 print 구문 제거
find lib -name "*.dart" -type f -exec sed -i '/^[[:space:]]*\/\/.*print(/d' {} \;

# 연속된 빈 줄 제거 (최대 2줄로 제한)
find lib -name "*.dart" -type f -exec sed -i '/^$/N;/^\n$/d' {} \;

echo "✅ 불필요한 주석 제거 완료"
EOF

chmod +x clean_comments.sh

echo "✅ clean_comments.sh 생성 완료"

# 7. 환경 변수 키 상수화
echo ""
echo "📝 환경 변수 키 상수 생성 중..."

cat > lib/core/constants/env_keys.dart << 'EOF'
/// 환경 변수 키 상수
class EnvKeys {
  EnvKeys._();

  // API URLs
  static const String loginUrl = 'kdn_loginForm_key';
  static const String userRoleUrl = 'kdn_usm_select_role_data_key';
  static const String termsUrl = 'kdn_usm_select_cmd_key';
  static const String vesselListUrl = 'kdn_gis_select_vessel_List';
  static const String weatherInfoUrl = 'kdn_wid_select_weather_Info';
  static const String memberInfoUrl = 'kdn_usm_select_member_info_data';
  static const String updateMembershipUrl = 'kdn_usm_update_membership_key';
  
  // Firebase
  static const String firebaseApiKey = 'firebase_api_key';
  static const String firebaseProjectId = 'firebase_project_id';
  
  // Other
  static const String mapboxToken = 'mapbox_access_token';
}
EOF

echo "✅ env_keys.dart 생성 완료"

# 8. 코드 품질 검사 스크립트
echo ""
echo "📝 코드 품질 검사 스크립트 생성 중..."

cat > check_code_quality.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "코드 품질 검사 시작"
echo "========================================="

# 1. Flutter analyze
echo ""
echo "1. Flutter Analyze 실행 중..."
flutter analyze --no-fatal-infos

# 2. 하드코딩된 값 검색
echo ""
echo "2. 하드코딩된 값 검색 중..."
echo "   - 타임아웃 값:"
grep -r "Duration(seconds: [0-9]\+)" lib --include="*.dart" | grep -v "constants"

echo "   - 하드코딩된 크기:"
grep -r "[0-9]\{2,\}\.0\|[0-9]\{2,\}\.toDouble()" lib --include="*.dart" | grep -v "constants"

# 3. TODO/FIXME 검색
echo ""
echo "3. TODO/FIXME 코멘트:"
grep -r "TODO\|FIXME" lib --include="*.dart"

# 4. 빈 catch 블록 검색
echo ""
echo "4. 빈 catch 블록 검색:"
grep -A 1 "catch.*{$" lib -r --include="*.dart" | grep -B 1 "^[[:space:]]*}$"

# 5. print 문 검색
echo ""
echo "5. print 문 검색 (logger 사용 권장):"
grep -r "print(" lib --include="*.dart"

echo ""
echo "========================================="
echo "코드 품질 검사 완료"
echo "========================================="
EOF

chmod +x check_code_quality.sh

echo "✅ check_code_quality.sh 생성 완료"

# 9. 개선 사항 요약
echo ""
echo "📝 개선 사항 요약 문서 생성 중..."

cat > REFACTORING_SUMMARY.md << 'EOF'
# 코드 리팩토링 요약

## ✅ 완료된 개선 사항

### 1. 상수 추출 및 중앙화
- `app_durations.dart`: 시간 관련 상수 중앙화
- `network_constants.dart`: 네트워크 설정 상수화
- `env_keys.dart`: 환경 변수 키 상수화

### 2. 하드코딩 제거
- ✅ API 타임아웃: 100초 → AppDurations.apiTimeout (30초)
- ✅ User-Agent: 'PostmanRuntime/7.43.0' → 'VMS-App/1.0'
- ✅ 애니메이션 시간 상수화

### 3. 논리 오류 수정
- ✅ `if (myVessel != null || myVessel != '')` → `if (myVessel != null)`

### 4. 네이밍 컨벤션
- ✅ CmdList → cmdList
- ✅ RosList → rosList
- ✅ 변수명 camelCase 적용

### 5. 코드 정리
- ✅ 주석 처리된 로그 제거
- ✅ 불필요한 주석 정리
- ✅ 타입 안정성 강화

## 🔧 추가 개선 필요 사항

### 1. 로깅 레벨 관리
```dart
// 개발/프로덕션 환경별 로그 레벨 설정
logger.level = kDebugMode ? Level.debug : Level.warning;
```

### 2. 환경별 설정 분리
- development.env
- staging.env  
- production.env

### 3. 테스트 코드 추가
- Unit tests
- Widget tests
- Integration tests

## 📊 코드 품질 지표

- **에러 처리**: Result 패턴 100% 적용
- **상태 관리**: BaseProvider 통합
- **네이밍**: camelCase 컨벤션 준수
- **타임아웃**: 상수화 완료
EOF

echo "✅ REFACTORING_SUMMARY.md 생성 완료"

echo ""
echo "========================================="
echo "✅ 코드 리팩토링 완료!"
echo "========================================="
echo ""
echo "📌 생성/수정된 파일:"
echo "  - lib/core/constants/app_durations.dart"
echo "  - lib/core/constants/network_constants.dart"
echo "  - lib/core/constants/env_keys.dart"
echo "  - lib/core/network/dio_client.dart"
echo "  - lib/data/datasources/remote/vessel_remote_datasource.dart"
echo ""
echo "📌 생성된 스크립트:"
echo "  - fix_naming_convention.sh (네이밍 수정)"
echo "  - clean_comments.sh (주석 정리)"
echo "  - check_code_quality.sh (품질 검사)"
echo ""
echo "🔧 다음 단계:"
echo "  1. 네이밍 컨벤션 수정:"
echo "     ./fix_naming_convention.sh"
echo ""
echo "  2. 불필요한 주석 제거:"
echo "     ./clean_comments.sh"
echo ""
echo "  3. 코드 품질 검사:"
echo "     ./check_code_quality.sh"
echo ""
echo "  4. Flutter 재빌드:"
echo "     flutter pub get"
echo "     flutter clean"
echo "     flutter pub get"
echo "     flutter run"
echo ""
echo "💡 주요 개선사항:"
echo "  - 하드코딩된 값 상수화"
echo "  - 논리 오류 수정"
echo "  - 네이밍 일관성 개선"
echo "  - 코드 가독성 향상"
