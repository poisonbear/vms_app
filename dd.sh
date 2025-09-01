#!/bin/bash

echo "=== API 보안 적용 시작 ==="

# 1. main.dart에 보안 초기화 추가
echo "[1/8] main.dart에 보안 초기화 추가..."

# AppInitializer import 추가
if ! grep -q "import 'package:vms_app/core/security/app_initializer.dart';" lib/main.dart; then
    sed -i "18i import 'package:vms_app/core/security/app_initializer.dart';" lib/main.dart
fi

# initInjection() 다음에 보안 초기화 추가
if ! grep -q "AppInitializer.initializeSecurity" lib/main.dart; then
    sed -i '/await initInjection();/a\
\
  // 보안 초기화\
  try {\
    await AppInitializer.initializeSecurity();\
    print('\''✅ Security initialized'\'');\
  } catch (e) {\
    print('\''⚠️ Security initialization failed: $e'\'');\
    // 실패해도 앱은 계속 실행\
  }' lib/main.dart
fi

# 2. 보안 강화된 API 서비스 생성
echo "[2/8] 보안 API 서비스 생성..."
mkdir -p lib/core/services

cat > lib/core/services/secure_api_service.dart << 'EOF'
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/security/secure_api_manager.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/network/dio_client.dart';

/// 보안 강화된 API 서비스
class SecureApiService {
  static final SecureApiService _instance = SecureApiService._internal();
  factory SecureApiService() => _instance;
  SecureApiService._internal();

  final _secureManager = SecureApiManager();
  final _dioRequest = DioRequest();

  /// API URL 가져오기 (Secure Storage 우선, .env fallback)
  Future<String> getApiUrl(String secureKey, String envKey) async {
    try {
      // 1. Secure Storage에서 시도
      final secureUrl = await _secureManager.getSecureEndpoint(secureKey);
      if (secureUrl.isNotEmpty) {
        AppLogger.d('Using secure endpoint for $secureKey');
        return secureUrl;
      }
    } catch (e) {
      AppLogger.w('Secure storage failed for $secureKey, falling back to .env');
    }
    
    // 2. .env에서 fallback
    final envUrl = dotenv.env[envKey] ?? '';
    if (envUrl.isEmpty) {
      AppLogger.e('No API URL found for $envKey');
    }
    return envUrl;
  }

  /// 로그인 API
  Future<Response> login({
    required String userId,
    required String password,
    required bool autoLogin,
    required String fcmToken,
    String? uuid,
    String? firebaseToken,
  }) async {
    final apiUrl = await getApiUrl('login_api', 'kdn_loginForm_key');
    
    if (apiUrl.isEmpty) {
      throw Exception('Login API URL not configured');
    }
    
    AppLogger.api('POST', apiUrl, {
      'user_id': AppLogger.maskSensitive(userId),
      'user_pwd': '[HIDDEN]',
      'auto_login': autoLogin,
    });
    
    try {
      final response = await _dioRequest.dio.post(
        apiUrl,
        data: {
          'user_id': userId,
          'user_pwd': password,
          'auto_login': autoLogin,
          'fcm_tkn': fcmToken,
          'uuid': uuid,
        },
        options: Options(
          headers: firebaseToken != null 
            ? {'Authorization': 'Bearer $firebaseToken'}
            : null,
        ),
      );
      
      AppLogger.i('Login successful');
      return response;
    } catch (e) {
      AppLogger.e('Login failed', e);
      rethrow;
    }
  }

  /// 사용자 역할 조회 API
  Future<Response> getUserRole(String username) async {
    final apiUrl = await getApiUrl('role_api', 'kdn_usm_select_role_data_key');
    
    if (apiUrl.isEmpty) {
      throw Exception('Role API URL not configured');
    }
    
    AppLogger.api('POST', apiUrl, {'user_id': AppLogger.maskSensitive(username)});
    
    try {
      final response = await _dioRequest.dio.post(
        apiUrl,
        data: {'user_id': username},
      );
      
      AppLogger.i('User role fetched successfully');
      return response;
    } catch (e) {
      AppLogger.e('Failed to fetch user role', e);
      rethrow;
    }
  }

  /// 약관 목록 조회 API
  Future<Response> getTermsList() async {
    final apiUrl = await getApiUrl('terms_api', 'kdn_usm_select_cmd_key');
    
    if (apiUrl.isEmpty) {
      throw Exception('Terms API URL not configured');
    }
    
    AppLogger.api('GET', apiUrl);
    
    try {
      final response = await _dioRequest.dio.get(apiUrl);
      AppLogger.i('Terms list fetched successfully');
      return response;
    } catch (e) {
      AppLogger.e('Failed to fetch terms list', e);
      rethrow;
    }
  }

  /// 선박 목록 조회 API
  Future<Response> getVesselList({String? regDt, int? mmsi}) async {
    final apiUrl = await getApiUrl('vessel_list_api', 'kdn_gis_select_vessel_List');
    
    if (apiUrl.isEmpty) {
      throw Exception('Vessel API URL not configured');
    }
    
    AppLogger.api('GET', apiUrl, {'regDt': regDt, 'mmsi': mmsi});
    
    try {
      final response = await _dioRequest.dio.get(
        apiUrl,
        queryParameters: {
          if (regDt != null) 'reg_dt': regDt,
          if (mmsi != null) 'mmsi': mmsi,
        },
      );
      
      AppLogger.i('Vessel list fetched successfully');
      return response;
    } catch (e) {
      AppLogger.e('Failed to fetch vessel list', e);
      rethrow;
    }
  }
}
EOF

# 3. 로그인 화면 보안 적용
echo "[3/8] 로그인 화면 보안 적용..."
cat > lib/presentation/screens/auth/login_screen_patch.dart << 'EOF'
// login_screen.dart에 추가할 코드

import 'package:vms_app/core/services/secure_api_service.dart';

// 클래스 내부에 추가
final _secureApiService = SecureApiService();

// submitForm 메서드를 보안 버전으로 교체
Future<void> submitFormSecure() async {
  final id = '${idController.text.trim()}@kdn.vms.com';
  final password = passwordController.text.trim();

  if (id.isEmpty || password.isEmpty) {
    showTopSnackBar(context, '아이디 비밀번호를 입력해주세요.');
    return;
  }

  try {
    // Firebase 인증
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: id, password: password);
    
    String? firebaseToken = await userCredential.user?.getIdToken();
    String? uuid = userCredential.user?.uid;

    if (firebaseToken == null) {
      showTopSnackBar(context, 'Firebase 토큰을 가져올 수 없습니다.');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_token', firebaseToken);

    // 보안 API 서비스 사용
    Response response = await _secureApiService.login(
      userId: id,
      password: password,
      autoLogin: auto_login,
      fcmToken: fcmToken,
      uuid: uuid,
      firebaseToken: firebaseToken,
    );

    if (response.statusCode == 200) {
      String username = response.data['username'];
      await prefs.setString('username', username);

      if (response.data.containsKey('uuid')) {
        String uuid = response.data['uuid'];
        await prefs.setString('uuid', uuid);
      }

      auto_login = true;
      await prefs.setBool('auto_login', auto_login);

      // 역할 조회도 보안 API 사용
      Response roleResponse = await _secureApiService.getUserRole(username);

      if (roleResponse.statusCode == 200) {
        String role = roleResponse.data['role'];
        int? mmsi = roleResponse.data['mmsi'];

        context.read<UserState>().setRole(role);
        context.read<UserState>().setMmsi(mmsi);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => mainView(username: username))
      );
    }
  } on FirebaseAuthException catch (e) {
    AppLogger.e('Firebase auth error', e);
    showTopSnackBar(context, '아이디 또는 비밀번호를 확인해주세요.');
  } catch (e) {
    AppLogger.e('Login error', e);
    showTopSnackBar(context, '로그인 중 오류가 발생했습니다.');
  }
}
EOF

# 4. DataSource 보안 적용 예시
echo "[4/8] DataSource 보안 적용..."
cat > lib/data/datasources/remote/terms_remote_datasource_secure.dart << 'EOF'
import 'package:vms_app/core/services/secure_api_service.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/errors/error_handler.dart';

class CmdSourceSecure {
  final dioRequest = DioRequest();
  final _secureApiService = SecureApiService();

  Future<Result<List<CmdModel>, AppException>> getCmdList() async {
    try {
      // 보안 API 서비스 사용
      final response = await _secureApiService.getTermsList();

      AppLogger.d('Terms list fetched successfully');

      final list = (response.data as List)
          .map<CmdModel>((json) => CmdModel.fromJson(json))
          .toList();
          
      return Success(list);
    } catch (e) {
      AppLogger.e('Terms API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}
EOF

# 5. 테스트 파일 생성
echo "[5/8] 테스트 파일 생성..."
mkdir -p test/security

cat > test/security/secure_api_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_app/core/security/secure_api_manager.dart';
import 'package:vms_app/core/services/secure_api_service.dart';

void main() {
  group('SecureApiManager Tests', () {
    late SecureApiManager secureManager;

    setUp(() {
      secureManager = SecureApiManager();
    });

    test('Should encrypt and decrypt text correctly', () async {
      const originalText = 'http://api.example.com/endpoint';
      
      // 암호화
      final encrypted = secureManager._encrypt(originalText);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(originalText));
      
      // 복호화
      final decrypted = secureManager._decrypt(encrypted);
      expect(decrypted, equals(originalText));
    });

    test('Should initialize secure endpoints', () async {
      await secureManager.initializeSecureEndpoints();
      
      // 저장된 엔드포인트 확인
      final loginUrl = await secureManager.getSecureEndpoint('login_api');
      expect(loginUrl, isNotEmpty);
      expect(loginUrl, contains('http'));
    });
  });

  group('SecureApiService Tests', () {
    late SecureApiService apiService;

    setUp(() {
      apiService = SecureApiService();
    });

    test('Should get API URL with fallback', () async {
      final url = await apiService.getApiUrl(
        'non_existent_key',
        'kdn_loginForm_key'
      );
      
      // .env fallback이 작동해야 함
      expect(url, isNotEmpty);
    });
  });
}
EOF

# 6. 보안 검증 스크립트
echo "[6/8] 보안 검증 스크립트 생성..."
cat > verify_security.sh << 'EOF'
#!/bin/bash

echo "=== 보안 적용 검증 ==="

# 1. 민감한 정보 노출 검사
echo "[1/4] 민감한 정보 노출 검사..."
SENSITIVE_PATTERNS=(
  "118.40.116.129"
  "kdn_.*_key"
  "password:"
  "user_pwd:"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  echo "Checking for: $pattern"
  grep -r "$pattern" lib/ --include="*.dart" | grep -v "secure" | head -5
done

# 2. AppLogger 사용 확인
echo "[2/4] 로그 사용 확인..."
echo "print 사용: $(grep -r "print(" lib/ --include="*.dart" | wc -l)건"
echo "AppLogger 사용: $(grep -r "AppLogger\." lib/ --include="*.dart" | wc -l)건"

# 3. ProGuard 설정 확인
echo "[3/4] ProGuard 설정 확인..."
if [ -f "android/app/proguard-rules.pro" ]; then
  echo "✅ ProGuard 파일 존재"
  grep "minifyEnabled" android/app/build.gradle
else
  echo "❌ ProGuard 파일 없음"
fi

# 4. 보안 파일 확인
echo "[4/4] 보안 파일 확인..."
FILES_TO_CHECK=(
  "lib/core/security/secure_api_manager.dart"
  "lib/core/security/app_initializer.dart"
  "lib/core/utils/app_logger.dart"
  "lib/core/services/secure_api_service.dart"
)

for file in "${FILES_TO_CHECK[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file"
  else
    echo "❌ $file (없음)"
  fi
done
EOF

chmod +x verify_security.sh

# 7. 빌드 테스트 스크립트
echo "[7/8] 빌드 테스트 스크립트 생성..."
cat > test_build.sh << 'EOF'
#!/bin/bash

echo "=== 빌드 테스트 시작 ==="

# 1. 클린
echo "[1/3] 프로젝트 클린..."
flutter clean

# 2. 패키지 설치
echo "[2/3] 패키지 설치..."
flutter pub get

# 3. 빌드 테스트
echo "[3/3] 빌드 테스트..."

# 디버그 빌드
echo "Debug 빌드..."
flutter build apk --debug --no-tree-shake-icons

if [ $? -eq 0 ]; then
  echo "✅ Debug 빌드 성공"
  echo "APK 위치: build/app/outputs/flutter-apk/app-debug.apk"
else
  echo "❌ Debug 빌드 실패"
  exit 1
fi

# 릴리즈 빌드 (선택사항)
read -p "릴리즈 빌드도 테스트하시겠습니까? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Release 빌드..."
  flutter build apk --release --no-tree-shake-icons
  
  if [ $? -eq 0 ]; then
    echo "✅ Release 빌드 성공"
    echo "APK 위치: build/app/outputs/flutter-apk/app-release.apk"
    
    # APK 크기 비교
    DEBUG_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    RELEASE_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "Debug APK: $DEBUG_SIZE"
    echo "Release APK: $RELEASE_SIZE (난독화 적용)"
  else
    echo "❌ Release 빌드 실패"
  fi
fi
EOF

chmod +x test_build.sh

# 8. 완료 메시지
echo "[8/8] 완료!"
echo ""
echo "=== ✅ API 보안 적용 완료 ==="
echo ""
echo "적용된 내용:"
echo "1. main.dart에 보안 초기화 추가"
echo "2. SecureApiService 생성"
echo "3. 로그인 화면 보안 예시 생성"
echo "4. DataSource 보안 예시 생성"
echo "5. 테스트 코드 생성"
echo "6. 검증 스크립트 생성"
echo ""
echo "다음 단계:"
echo "1. ./verify_security.sh 실행하여 보안 적용 확인"
echo "2. ./test_build.sh 실행하여 빌드 테스트"
echo "3. 실제 디바이스에서 테스트"
echo ""
echo "수동 작업:"
echo "1. login_screen.dart의 submitForm을 submitFormSecure로 교체"
echo "2. 각 DataSource를 SecureApiService 사용하도록 수정"
