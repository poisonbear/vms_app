/// 에러 메시지
class ErrorMessages {
  ErrorMessages._();

  static const String network = '네트워크 연결을 확인해주세요';
  static const String server = '서버와의 통신 중 문제가 발생했습니다';
  static const String timeout = '연결 시간이 초과되었습니다';
  static const String unauthorized = '인증이 필요합니다';
  static const String forbidden = '접근 권한이 없습니다';
  static const String notFound = '요청한 정보를 찾을 수 없습니다';
  static const String general = '오류가 발생했습니다. 잠시 후 다시 시도해주세요';
  static const String dataFormat = '데이터 형식이 올바르지 않습니다';

  // ============ 자동 로그인 관련 ============
  static const String firebaseTokenMissing = 'Firebase 토큰을 가져올 수 없습니다.';
  static const String apiUrlNotSet = 'API URL이 설정되지 않았습니다.';
  static const String roleDataMissing = '권한 정보를 가져올 수 없습니다.';
  static const String loginFailed = '로그인 실패';
}

/// 성공 메시지
class SuccessMessages {
  SuccessMessages._();

  static const String saved = '저장되었습니다';
  static const String deleted = '삭제되었습니다';
  static const String updated = '수정되었습니다';
  static const String loaded = '불러오기 완료';
  static const String sent = '전송되었습니다';
}

/// 확인 메시지
class ConfirmMessages {
  ConfirmMessages._();

  static const String delete = '정말 삭제하시겠습니까?';
  static const String save = '저장하시겠습니까?';
  static const String cancel = '작업을 취소하시겠습니까?';
  static const String logout = '로그아웃 하시겠습니까?';
}

/// 유효성 검증 메시지
class ValidationMessages {
  ValidationMessages._();

  static const String required = '필수 입력 항목입니다';
  static const String emailInvalid = '올바른 이메일 형식이 아닙니다';
  static const String phoneInvalid = '올바른 전화번호 형식이 아닙니다';
  static const String mmsiInvalid = 'MMSI는 9자리 숫자여야 합니다';
  static const String passwordShort = '비밀번호는 8자 이상이어야 합니다';
  static const String passwordMismatch = '비밀번호가 일치하지 않습니다';
}

/// 안내 메시지
class InfoMessages {
  InfoMessages._();

  static const String loading = 'loading...';
  static const String loadingKorean = '불러오는 중...';
  static const String noData = '데이터가 없습니다';
  static const String noResult = '검색 결과가 없습니다';
  static const String noHistory = '이력이 없습니다';
}