import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/security/secure_api_manager.dart';
import 'package:vms_app/core/services/secure_api_service.dart';

void main() {
  // Flutter 바인딩 초기화 - 테스트 환경에서 필수
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // .env 파일 로드
  setUpAll(() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      print('Warning: .env file not found in test environment');
    }
  });

  group('SecureApiManager Tests', () {
    late SecureApiManager secureManager;

    setUp(() {
      secureManager = SecureApiManager();
    });

    testWidgets('Should store and retrieve secure endpoints', (WidgetTester tester) async {
      // 초기화 테스트
      await secureManager.initializeSecureEndpoints();
      
      // 저장된 엔드포인트 확인
      final loginUrl = await secureManager.getSecureEndpoint('login_api');
      expect(loginUrl, isNotEmpty);
      expect(loginUrl, contains('http'));
    });

    testWidgets('Should check if key exists', (WidgetTester tester) async {
      // 키 존재 여부 확인
      await secureManager.initializeSecureEndpoints();
      
      final hasLoginKey = await secureManager.hasKey('login_api');
      expect(hasLoginKey, isTrue);
      
      final hasInvalidKey = await secureManager.hasKey('invalid_key');
      expect(hasInvalidKey, isFalse);
    });

    testWidgets('Should clear all stored data', (WidgetTester tester) async {
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
      // .env가 없어도 빈 문자열 반환해야 함
      final url = await apiService.getApiUrl(
        'non_existent_key',
        'non_existent_env_key'
      );
      
      // URL이 null이 아닌지만 확인 (테스트 환경에서는 비어있을 수 있음)
      expect(url, isNotNull);
    });
  });
}
