/// 일반 문자열 및 상수
class StringConstants {
  StringConstants._();

  // ============ SharedPreferences 키 ============
  static const String autoLoginKey = 'auto_login';
  static const String firebaseTokenKey = 'firebase_token';
  static const String savedIdKey = 'saved_id';
  static const String savedPwKey = 'saved_pw';
  static const String usernameKey = 'username';

  // ============ 사용자 역할 상수 ============
  static const String userRoleKey = 'user_role';
  static const String userMmsiKey = 'user_mmsi';
  static const String roleKey = 'role';

  static const String roleUser = 'ROLE_USER'; // 일반 사용자
  static const String roleAdmin = 'ROLE_ADMIN'; // 시스템 관리자
  static const String roleOperator = 'ROLE_OPER'; // 발전단지 운영자

  // ============ Firebase 관련 ============
  static const String emailDomain = '@vms.com';

  // ============ Firestore 컬렉션 경로 ============
  static const String firestoreAppCollection = 'firebase_App';
  static const String userTokenDoc = 'userToken';
  static const String usersCollection = 'users';

  // ============ 에셋 경로 ============
  static const String turbinePoleAsset = 'assets/kdn/home/img/turbine_pole.svg';
  static const String turbineBladeAsset =
      'assets/kdn/home/img/turbine_blade.svg';

  // ============ 디렉토리/파일 관련 ============
  static const String assetsDir = 'assets';
  static const String libDir = 'lib';
  static const String pubspecFile = 'pubspec.yaml';

  // ============ 파일 확장자 ============
  static const String pngExtension = '.png';
  static const String jpgExtension = '.jpg';
  static const String jpegExtension = '.jpeg';
  static const String dartExtension = '.dart';

  // ============ 항행 상태 ============
  static const String statusAnchored = '정박 중';
  static const String statusHighSpeed = '고속 항행';
  static const String statusMoving = '항행 중';
  static const String statusUnknown = '알 수 없음';

  // ============ 단위 ============
  static const String unitKB = 'KB';
  static const String unitBytes = '개';

  // ============ 사용자 에이전트 ============
  static const String appName = 'VMS-App';
  static const String appVersion = '1.0';

  // ============ 기본 값 ============
  static const String emptyString = '';
  static const String space = ' ';
  static const String colon = ':';
  static const String slash = '/';
}

/// 개발/디버깅용 로그 메시지
class LogMessages {
  LogMessages._();

  // ============ 이미지 최적화 관련 ============
  static const String startOptimization = '이미지 최적화 시작...';
  static const String noAssetsDir = 'assets 디렉토리가 없습니다.';
  static const String foundImages = '발견된 이미지';
  static const String largeFileWarning = ' 큰 이미지 파일! 최적화 필요';

  // ============ 자동 로그인 관련 ============
  static const String autoLoginStart = '========== 자동 로그인 시작 ==========';
  static const String autoLoginFailed = '========== 자동 로그인 실패 ==========';
  static const String autoLoginComplete = '========== 자동 로그인 완료 ==========';
  static const String autoLoginCheck = '========== 자동 로그인 체크 ==========';
  static const String separator = '========================================';

  // ============ Firebase 관련 ============
  static const String firebaseAuthSuccess = 'Firebase 인증 성공';
  static const String firebaseTokenUpdate = 'Firebase 토큰 업데이트';
  static const String fcmTokenRetry = 'FCM 토큰을 가져올 수 없습니다. 재시도합니다.';

  // ============ 네비게이션 관련 ============
  static const String navigateToLogin = '로그인 화면으로 이동';
  static const String navigateToMain = 'MainScreen으로 이동';

  // ============ 사용자 정보 관련 ============
  static const String roleSetComplete = '역할 설정 완료';
  static const String mmsiSetComplete = 'MMSI 설정 완료';
  static const String userInfoSaveFailed = '사용자 정보 저장 실패';
  static const String autoLoginDataCleared = '자동 로그인 데이터 삭제 완료';
}

/// Firebase 에러 코드
class FirebaseErrorCodes {
  FirebaseErrorCodes._();

  static const String userNotFound = 'user-not-found';
  static const String wrongPassword = 'wrong-password';
  static const String emailAlreadyInUse = 'email-already-in-use';
  static const String weakPassword = 'weak-password';
  static const String invalidEmail = 'invalid-email';
}

/// 스플래시 화면 UI 상수
class SplashConstants {
  SplashConstants._();

  // ============ 색상 ============
  static const int gradientTop = 0xFF0A1931;
  static const int gradientMiddle = 0xFF185A9D;
  static const int gradientBottom = 0xFF43A6C6;

  // ============ 레이아웃 ============
  static const double turbineBottom = 50.0;
  static const double turbineWidth = 150.0;
  static const double turbineHeight = 300.0;
  static const double bladeSize = 300.0;
  static const double bladeBottom = 200.0;
  static const double containerHeight = 500.0;
  static const double textSpacing = 20.0;

  // ============ 텍스트 스타일 ============
  static const double textSize = 25.0;
  static const double textOpacity = 0.9;
  static const double textLetterSpacing = 1.0;

  // ============ 애니메이션 ============
  static const double turbineAlignmentX = 0.0;
  static const double turbineAlignmentY = 0.29;

  // ============ 그라데이션 ============
  static const List<double> gradientStops = [0.0, 0.5, 1.0];
}
