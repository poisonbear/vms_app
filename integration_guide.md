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
