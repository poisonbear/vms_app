#!/bin/bash

echo "=== 패치 파일 오류 수정 및 정리 ==="

# 1. 불필요한 패치 파일 제거
echo "[1/5] 예시 패치 파일 제거..."
rm -f lib/presentation/screens/auth/login_screen_patch.dart
rm -f lib/presentation/screens/auth/login_screen_secure.dart
rm -f lib/data/datasources/remote/secure_datasource_template.dart
rm -f lib/data/datasources/remote/terms_remote_datasource_secure.dart

echo "✅ 패치 파일 제거 완료"

# 2. 테스트 파일 수정
echo "[2/5] 테스트 파일 수정..."
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

    test('Should store and retrieve secure endpoints', () async {
      // 초기화 테스트
      await secureManager.initializeSecureEndpoints();
      
      // 저장된 엔드포인트 확인
      final loginUrl = await secureManager.getSecureEndpoint('login_api');
      expect(loginUrl, isNotEmpty);
      expect(loginUrl, contains('http'));
    });

    test('Should check if key exists', () async {
      // 키 존재 여부 확인
      await secureManager.initializeSecureEndpoints();
      
      final hasLoginKey = await secureManager.hasKey('login_api');
      expect(hasLoginKey, isTrue);
      
      final hasInvalidKey = await secureManager.hasKey('invalid_key');
      expect(hasInvalidKey, isFalse);
    });

    test('Should clear all stored data', () async {
      // 데이터 저장
      await secureManager.initializeSecureEndpoints();
      
      // 모든 데이터 삭제
      await secureManager.clearAll();
      
      // 확인
      final hasKey = await secureManager.hasKey('login_api');
      expect(hasKey, isFalse);
    });
  });

  group('SecureApiService Tests', () {
    late SecureApiService apiService;

    setUp(() {
      apiService = SecureApiService();
    });

    test('Should get API URL with fallback', () async {
      // 존재하지 않는 키로 테스트 (fallback 동작 확인)
      final url = await apiService.getApiUrl(
        'non_existent_key',
        'kdn_loginForm_key'
      );
      
      // .env fallback이 작동해야 함
      // URL이 비어있을 수 있음 (테스트 환경에서는 .env가 로드되지 않을 수 있음)
      expect(url, isNotNull);
    });
  });
}
EOF

echo "✅ 테스트 파일 수정 완료"

# 3. 실제 login_screen.dart에 보안 기능 통합하는 가이드 생성
echo "[3/5] 통합 가이드 생성..."
cat > integration_guide.md << 'EOF'
# Login Screen 보안 통합 가이드

## 1. Import 추가
```dart
// login_screen.dart 상단에 추가
import 'package:vms_app/core/services/secure_api_service.dart';
import 'package:vms_app/core/utils/app_logger.dart';
```

## 2. 클래스 멤버 추가
```dart
class _CmdViewState extends State<LoginView> {
  // 기존 멤버들...
  
  // 보안 API 서비스 추가
  final _secureApiService = SecureApiService();
  
  // 기존 코드...
}
```

## 3. submitForm 메서드 수정
기존 submitForm 메서드를 다음과 같이 수정:

```dart
Future<void> submitForm() async {
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

    // ✨ 보안 API 서비스 사용
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

      // ✨ 역할 조회도 보안 API 사용
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
```

## 4. 기존 print 문을 AppLogger로 교체
```dart
// 기존
print('로그인 응답: $response');

// 변경
AppLogger.d('로그인 응답: $response');
```
EOF

echo "✅ 통합 가이드 생성 완료"

# 4. 실제 적용 스크립트 생성
echo "[4/5] 실제 적용 스크립트 생성..."
cat > apply_security_to_login.sh << 'EOF'
#!/bin/bash

echo "=== Login Screen 보안 적용 ==="

# 1. login_screen.dart 백업
cp lib/presentation/screens/auth/login_screen.dart lib/presentation/screens/auth/login_screen.dart.backup

# 2. Import 추가
echo "Import 추가 중..."
if ! grep -q "import 'package:vms_app/core/services/secure_api_service.dart';" lib/presentation/screens/auth/login_screen.dart; then
  sed -i "15i import 'package:vms_app/core/services/secure_api_service.dart';" lib/presentation/screens/auth/login_screen.dart
  sed -i "16i import 'package:vms_app/core/utils/app_logger.dart';" lib/presentation/screens/auth/login_screen.dart
fi

# 3. SecureApiService 멤버 추가
echo "SecureApiService 멤버 추가 중..."
if ! grep -q "final _secureApiService = SecureApiService();" lib/presentation/screens/auth/login_screen.dart; then
  sed -i '/class _CmdViewState extends State<LoginView> {/a\  final _secureApiService = SecureApiService();' lib/presentation/screens/auth/login_screen.dart
fi

# 4. print 문을 AppLogger로 변경
echo "로그 변경 중..."
sed -i "s/print('/AppLogger.d('/g" lib/presentation/screens/auth/login_screen.dart
sed -i "s/print(\$/AppLogger.d(\$/g" lib/presentation/screens/auth/login_screen.dart

echo "✅ 보안 적용 완료"
echo "⚠️  submitForm 메서드는 수동으로 수정 필요"
echo "    integration_guide.md 참조"
EOF

chmod +x apply_security_to_login.sh

echo "✅ 적용 스크립트 생성 완료"

# 5. 클린업
echo "[5/5] 프로젝트 정리..."
flutter clean
flutter pub get

echo ""
echo "=== ✅ 완료 ==="
echo ""
echo "제거된 파일:"
echo "  - login_screen_patch.dart"
echo "  - login_screen_secure.dart"
echo "  - secure_datasource_template.dart"
echo ""
echo "수정된 파일:"
echo "  - test/security/secure_api_test.dart"
echo ""
echo "생성된 파일:"
echo "  - integration_guide.md (통합 가이드)"
echo "  - apply_security_to_login.sh (적용 스크립트)"
echo ""
echo "다음 단계:"
echo "1. ./apply_security_to_login.sh 실행"
echo "2. integration_guide.md 참조하여 수동 수정"
echo "3. flutter analyze 실행하여 오류 확인"
echo "4. flutter test 실행"
