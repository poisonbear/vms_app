/// emergency_constants.dart
/// Emergency 탭 전용 상수 정의
library;

class EmergencyConstants {
  EmergencyConstants._();

  // ============ 타이머 관련 ============
  static const int countdownSeconds = 5;
  static const int longPressSeconds = 3;
  static const Duration longPressDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 200);

  // ============ 전화번호 ============
  static const String emergencyNumberMarine = '122';
  static const String emergencyNumberFire = '119';
  static const String emergencyNumberPolice = '112';

  // ============ 메시지 ============
  static const String titleEmergency = '긴급신고';
  static const String titleEmergencySituation = '🚨 긴급 상황 시';
  static const String messageEmergencyConfirm = '해양경찰 122로\n긴급신고를 진행하시겠습니까?';
  static const String messageAutoConnect = '초 후 자동 연결됩니다';
  static const String messageLongPress = '3초간 길게 눌러 긴급신고';
  static const String messageLocationTracking = '위치 추적 중';
  static const String messageLocationStart = '위치 추적 시작';
  static const String messageLocationFetching = '위치 정보를 가져오는 중...';

  static const String warningFalseReport = '긴급 상황 시 122 버튼을 3초간 길게 누르면 해양경찰과 연결됩니다.\n거짓 신고 시 법적 처벌을 받을 수 있습니다.';

  // ============ 라벨 ============
  static const String labelCancel = '취소';
  static const String labelCallNow = '지금 신고';
  static const String labelDeleteAll = '전체 삭제';
  static const String labelRefresh = '새로고침';
  static const String labelCurrentLocation = '현재 위치 정보';
  static const String labelVesselInfo = '선박 정보';
  static const String labelOtherEmergency = '기타 긴급 연락처';
  static const String labelEmergencyHistory = '최근 긴급신고 기록';
  static const String labelShipName = '선박명';
  static const String labelLatitude = '위도';
  static const String labelLongitude = '경도';
  static const String labelSpeed = '속도';
  static const String labelHeading = '방향';
  static const String labelUnknown = 'Unknown';

  // ============ 단위 ============
  static const String unitDegree = '°';
  static const String unitMeterPerSecond = 'm/s';
  static const String unitLocation = '위치: ';

  // ============ 아이콘 크기 ============
  static const double iconSizeWarning = 48.0;
  static const double iconSizePhone = 40.0;
  static const double iconSizeInfo = 16.0;
  static const double iconSizeStatus = 16.0;
  static const double iconSizeHeader = 24.0;
  static const double iconSizeLocation = 20.0;

  // ============ 컨테이너 크기 ============
  static const double countdownCircleSize = 80.0;
  static const double headerButtonSize = 24.0;

  // ============ History 표시 개수 ============
  static const int maxHistoryDisplay = 3;

  // ============ 소수점 자리수 ============
  static const int coordinateDecimalPlaces = 6;
  static const int coordinateShortDecimalPlaces = 4;
  static const int speedDecimalPlaces = 1;
  static const int headingDecimalPlaces = 0;
}