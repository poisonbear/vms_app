/// 일반 문자열 상수
class StringConstants {
  StringConstants._();

  // ============ 사용자 역할 상수 ============
  static const String userRoleKey = 'user_role';
  static const String userMmsiKey = 'user_mmsi';
  
  // ============ 디렉토리/파일 관련 ============
  static const String assetsDir = 'assets';
  static const String libDir = 'lib';
  static const String pubspecFile = 'pubspec.yaml';
  
  // ============ 파일 확장자 ============
  static const String pngExtension = '.png';
  static const String jpgExtension = '.jpg';
  static const String jpegExtension = '.jpeg';
  static const String dartExtension = '.dart';
  
  // ============ 로그 메시지 ============
  static const String startOptimization = '이미지 최적화 시작...';
  static const String noAssetsDir = 'assets 디렉토리가 없습니다.';
  static const String foundImages = '발견된 이미지';
  static const String largeFileWarning = '⚠️  큰 이미지 파일! 최적화 필요';
  
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
