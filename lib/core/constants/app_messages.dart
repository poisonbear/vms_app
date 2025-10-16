// lib/core/constants/app_messages.dart

/// 에러 메시지
class ErrorMessages {
  ErrorMessages._();

  // ============ 네트워크 관련 ============
  static const String network = '네트워크 연결을 확인해주세요';
  static const String server = '서버와의 통신 중 문제가 발생했습니다';
  static const String serverConnection = '서버에 연결할 수 없습니다. 다시 시도해주세요.';
  static const String timeout = '연결 시간이 초과되었습니다';
  static const String unauthorized = '인증이 필요합니다';
  static const String forbidden = '접근 권한이 없습니다';
  static const String notFound = '요청한 정보를 찾을 수 없습니다';
  static const String general = '오류가 발생했습니다. 잠시 후 다시 시도해주세요';
  static const String dataFormat = '데이터 형식이 올바르지 않습니다';
  static const String dataLoad = '데이터를 불러오는 중 오류가 발생했습니다.';
  static const String processingError = '처리 중 오류가 발생했습니다.';

  // ============ HTTP 상태 코드별 메시지 ============
  static const String badRequest = '잘못된 요청입니다';
  static const String requestTimeout = '요청 시간이 초과되었습니다';
  static const String tooManyRequests = '너무 많은 요청입니다';
  static const String tooManyRequestsRetry = '너무 많은 요청입니다. 잠시 후 다시 시도해주세요.';
  static const String internalServerError = '서버 내부 오류가 발생했습니다';
  static const String badGateway = '게이트웨이 오류가 발생했습니다';
  static const String serviceUnavailable = '서비스를 일시적으로 사용할 수 없습니다';
  static const String serverError = '서버 오류가 발생했습니다';
  static const String requestProcessError = '요청 처리 중 오류가 발생했습니다';
  static const String unknownError = '알 수 없는 오류가 발생했습니다';
  static const String noServerResponse = '서버 응답이 없습니다';

  // ============ 요청 관련 추가 ============
  static const String requestCancelled = '요청이 취소되었습니다';
  static const String initializationFailed = '초기화 중 오류가 발생했습니다';
  static const String errorOccurred = '에러가 발생했습니다';

  // ============ 인증 관련 ============
  static const String authRequired = '로그인이 필요합니다';
  static const String authExpired = '로그인이 만료되었습니다. 다시 로그인해주세요.';
  static const String firebaseTokenMissing = 'Firebase 토큰을 가져올 수 없습니다.';
  static const String apiUrlNotSet = 'API URL이 설정되지 않았습니다.';
  static const String roleDataMissing = '권한 정보를 가져올 수 없습니다.';
  static const String loginFailed = '로그인 실패';

  // ============ Firebase Auth 에러 ============
  static const String userNotFound = '등록되지 않은 사용자입니다.';
  static const String wrongPassword = '비밀번호가 올바르지 않습니다.';
  static const String invalidEmail = '이메일 형식이 올바르지 않습니다.';
  static const String userDisabled = '비활성화된 계정입니다.';
  static const String tooManyRequestsAuth = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
  static const String loginError = '로그인 중 오류가 발생했습니다';
  static const String roleInfoLoadFailed = '사용자 역할 정보를 불러오지 못했습니다.';

  // ============ 유효성 검증 관련 ============
  static const String idPasswordRequired = '아이디 비밀번호를 입력해주세요.';
  static const String idRequired = '아이디를 입력해주세요.';
  static const String passwordRequired = '비밀번호를 입력해주세요.';
  static const String passwordConfirmRequired = '비밀번호 확인을 입력해주세요.';
  static const String passwordMismatch = '비밀번호가 일치하지 않습니다.';
  static const String passwordFormat = '비밀번호는 6-12자리, 영문, 숫자, 특수문자를 포함해야 합니다.';
  static const String passwordFormatLong =
      '비밀번호는 문자, 숫자 및 특수문자를 포함한 6자리 이상 12자리 이하로 입력하여야 합니다.';
  static const String passwordShort = '비밀번호는 8자 이상이어야 합니다';
  static const String idInvalid = '아이디는 영문과 숫자만 사용 가능합니다.';
  static const String idDuplicateCheck = '아이디 중복확인을 해주세요.';
  static const String idDuplicateCheckFailed = '아이디 중복 확인에 실패했습니다.';
  static const String mmsiRequired = 'MMSI를 입력해주세요.';
  static const String mmsiInvalid = 'MMSI는 9자리 숫자여야 합니다.';
  static const String phoneRequired = '전화번호를 입력해주세요.';
  static const String phoneInvalid = '올바른 전화번호 형식이 아닙니다.';
  static const String emailRequired = '이메일을 완전히 입력해주세요.';
  static const String emailInvalid = '올바른 이메일 형식이 아닙니다';
  static const String oldPasswordIncorrect = '기존 비밀번호가 일치하지 않습니다.';
  static const String newPasswordRequired = '변경하실 새로운 비밀번호를 입력해주세요.';

  // ============ 회원 관련 ============
  static const String registerSuccess = '회원가입이 완료되었습니다.';
  static const String registerFailed = '회원가입에 실패했습니다. 다시 시도해주세요.';
  static const String profileUpdateSuccess = '회원정보가 성공적으로 수정되었습니다.';
  static const String profileUpdateFailed = '회원정보 수정에 실패했습니다.';

  // ============ 저장 관련 추가 ============
  static const String roleSaveFailed = '역할 저장 실패';
  static const String mmsiSaveFailed = 'MMSI 저장 실패';
  static const String roleSaveError = '사용자 역할 저장 중 오류가 발생했습니다';
  static const String mmsiSaveError = 'MMSI 저장 중 오류가 발생했습니다';
  static const String userInfoLoadError = '사용자 정보를 불러오는 중 오류가 발생했습니다';
  static const String userInfoClearError = '사용자 정보 초기화 중 오류가 발생했습니다';

  // ============ 선박 관련 ============
  static const String vesselListLoadFailed = '선박 목록을 불러오는 중 오류가 발생했습니다';
  static const String vesselRouteLoadFailed = '항로 정보를 불러오는데 실패했습니다';
  static const String vesselNotFound = '선박 정보를 찾을 수 없습니다';

  // ============ 기상 관련 ============
  static const String weatherLoadFailed = '기상 정보를 불러오는 중 오류가 발생했습니다';
  static const String weatherInfoLoadFailed = '기상정보 조회 중 오류가 발생했습니다';

  // ============ 항행 관련 ============
  static const String navigationLoadFailed = '항행이력 조회 중 오류가 발생했습니다';
  static const String navigationWarningsLoadFailed = '항행경보 조회 중 오류가 발생했습니다';
  static const String navigationHistoryFailed = '항행이력 조회 실패';

  // ============ 기타 ============
  static const String required = '필수 입력 항목입니다';
  static const String permissionRequired = '필요한 권한이 없습니다';
  static const String locationError = '위치 정보를 가져올 수 없습니다';
  static const String cacheError = '캐시 처리 중 문제가 발생했습니다';
  static const String inputValidation = '입력한 정보를 확인해주세요';
}

/// 성공 메시지
class SuccessMessages {
  SuccessMessages._();

  static const String saved = '저장되었습니다';
  static const String deleted = '삭제되었습니다';
  static const String updated = '수정되었습니다';
  static const String loaded = '불러오기 완료';
  static const String sent = '전송되었습니다';
  static const String registerComplete = '회원가입이 완료되었습니다.';
  static const String profileUpdated = '회원정보가 성공적으로 수정되었습니다.';
  static const String idAvailable = '사용 가능한 아이디입니다.';
  static const String idDuplicate = '이미 사용 중인 아이디입니다.';
}

/// 확인 메시지
class ConfirmMessages {
  ConfirmMessages._();

  static const String delete = '정말 삭제하시겠습니까?';
  static const String save = '저장하시겠습니까?';
  static const String cancel = '작업을 취소하시겠습니까?';
  static const String logout = '로그아웃 하시겠습니까?';
}

/// 유효성 검증 메시지 (중복 제거용)
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

  static const String notification = '알림';
  static const String newMessageArrived = '새로운 메시지가 도착했습니다';
  static const String noNavigationWarningsToday = '금일 항행경보가 없습니다';
}
