#!/bin/bash

# 기존 코드를 보안 강화 버전으로 마이그레이션하는 스크립트

echo "=== 기존 코드 보안 마이그레이션 시작 ==="

# 1. main.dart 수정 - 보안 초기화 추가
echo "[1/5] main.dart 보안 초기화 추가 중..."
sed -i.bak '/await initInjection();/a\
\  // 보안 설정 초기화\
\  await AppInitializer.initializeSecurity();' lib/main.dart

# import 추가
sed -i.bak '/import.*injection.dart/a\
import '\''package:vms_app/core/security/app_initializer.dart'\'';' lib/main.dart

# 2. login_screen.dart 수정
echo "[2/5] login_screen.dart 보안 강화 중..."
cat > lib/presentation/screens/auth/login_screen_secure.dart << 'EOF'
// 보안 강화된 로그인 처리 부분
import 'package:vms_app/core/security/secure_api_manager.dart';
import 'package:vms_app/core/utils/app_logger.dart';

// submitForm 메서드 내부 수정 예시
Future<void> submitFormSecure() async {
  final secureManager = SecureApiManager();
  
  // 암호화된 API URL 가져오기
  final apiUrl = await secureManager.getSecureEndpoint('login_api');
  final roleApiUrl = await secureManager.getSecureEndpoint('role_api');
  
  // 로그에는 민감한 정보 마스킹
  AppLogger.d('Login attempt for user: ${AppLogger.maskSensitive(id)}');
  
  try {
    Response response = await Dio().post(
      apiUrl, // 보안 처리된 URL 사용
      data: {
        'user_id': id,
        'user_pwd': password,
        'auto_login': auto_login,
        'fcm_tkn': fcmToken,
        'uuid': uuid
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $firebaseToken',
        },
      ),
    );
    
    AppLogger.i('Login successful');
    
    // 역할 조회도 보안 처리
    Response roleResponse = await Dio().post(
      roleApiUrl,
      data: {'user_id': username},
    );
    
  } catch (e) {
    AppLogger.e('Login failed', e);
    // 에러 처리
  }
}
EOF

# 3. datasource 파일들 수정
echo "[3/5] DataSource 파일들 보안 강화 중..."

# terms_remote_datasource.dart 수정 예시
cat > lib/data/datasources/remote/secure_datasource_template.dart << 'EOF'
import 'package:vms_app/core/security/secure_api_manager.dart';
import 'package:vms_app/core/utils/app_logger.dart';

class SecureDataSource {
  final secureManager = SecureApiManager();
  final dioRequest = DioRequest();

  Future<Result<List<Model>, AppException>> getSecureData() async {
    try {
      // 암호화된 API URL 가져오기
      final apiUrl = await secureManager.getSecureEndpoint('terms_api');
      
      if (apiUrl.isEmpty) {
        AppLogger.e('API URL not found in secure storage');
        return const Failure(GeneralAppException('API URL이 설정되지 않았습니다'));
      }
      
      AppLogger.api('GET', apiUrl);
      final response = await dioRequest.dio.get(apiUrl);
      
      AppLogger.d('Data fetched successfully');
      
      // 데이터 처리
      final list = (response.data as List)
          .map<Model>((json) => Model.fromJson(json))
          .toList();
          
      return Success(list);
    } catch (e) {
      AppLogger.e('API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}
EOF

# 4. .gitignore 업데이트
echo "[4/5] .gitignore 보안 설정 추가 중..."
cat >> .gitignore << 'EOF'

# 보안 관련 파일
*.keystore
*.jks
key.properties
/android/app/google-services.json
/ios/Runner/GoogleService-Info.plist

# 환경 파일
.env
.env.*

# 로그 파일
*.log
logs/

# 백업 파일
backup_*/
*.bak
EOF

# 5. 로그 출력 부분 모두 AppLogger로 교체
echo "[5/5] 로그 출력 교체 중..."

# print 문을 AppLogger.d로 교체
find lib -name "*.dart" -type f -exec sed -i.bak "s/print('/AppLogger.d('/g" {} \;
find lib -name "*.dart" -type f -exec sed -i.bak "s/log('/AppLogger.d('/g" {} \;

# developer.log를 AppLogger로 교체
find lib -name "*.dart" -type f -exec sed -i.bak "s/import 'dart:developer'/import 'package:vms_app\/core\/utils\/app_logger.dart'/g" {} \;

echo ""
echo "=== ✅ 마이그레이션 완료 ==="
echo ""
echo "수정된 사항:"
echo "1. main.dart - 보안 초기화 코드 추가"
echo "2. API 호출 부분 - SecureApiManager 사용"
echo "3. 로그 출력 - AppLogger 사용"
echo "4. .gitignore - 보안 파일 제외"
echo ""
echo "수동 작업 필요:"
echo "1. 각 DataSource의 dotenv.env를 SecureApiManager로 교체"
echo "2. google-services.json을 .gitignore에 추가 후 재배포"
echo "3. 테스트 실행"
echo ""
echo "테스트 명령어:"
echo "flutter clean"
echo "flutter pub get"
echo "flutter run --debug"
echo "flutter build apk --release"
