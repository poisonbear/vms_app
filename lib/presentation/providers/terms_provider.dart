// lib/presentation/providers/terms_provider.dart
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/exceptions/result.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/data/models/terms_model.dart';
import 'package:vms_app/domain/usecases/terms_usecases.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';

/// 통합 약관 Provider
class TermsProvider extends BaseProvider {
  late final GetTermsList _getTermsList;

  // 전체 약관 리스트
  List<CmdModel>? _allTermsList;

  // 각 약관별 getter
  CmdModel? get serviceTerms =>
      _getTermsByTitle(['서비스'], excludeKeywords: ['위치', '기반']);
  CmdModel? get privacyPolicy =>
      _getTermsByTitle(['개인정보'], excludeKeywords: ['위치', '기반']);
  CmdModel? get locationTerms => _getTermsByTitle(['위치', '기반']);
  CmdModel? get marketingTerms => _getTermsByTitle(['마케팅']);

  // 전체 약관 리스트 getter
  List<CmdModel>? get allTerms => _allTermsList;

  // 약관 동의 상태 관리
  final Map<TermsType, bool> _agreementStatus = {
    TermsType.service: false,
    TermsType.privacy: false,
    TermsType.location: false,
    TermsType.marketing: false,
  };

  Map<TermsType, bool> get agreementStatus =>
      Map.unmodifiable(_agreementStatus);

  // 전체 동의 상태
  bool get isAllAgreed => _agreementStatus.values.every((agreed) => agreed);

  // 필수 약관 동의 상태 (마케팅 제외)
  bool get isRequiredAgreed =>
      _agreementStatus[TermsType.service]! &&
      _agreementStatus[TermsType.privacy]! &&
      _agreementStatus[TermsType.location]!;

  TermsProvider() {
    _getTermsList = getIt<GetTermsList>();
    loadAllTerms();
  }

  /// 모든 약관을 한 번에 로드 (일관된 패턴 적용)
  Future<void> loadAllTerms() async {
    // API 호출만 executeAsync로 감싸기
    final result = await executeAsync<Result<List<CmdModel>, AppException>>(
      () async {
        return await _getTermsList.execute();
      },
      errorMessage: '약관을 불러오는 중 오류가 발생했습니다',
      showLoading: true,
    );

    // 응답 처리
    if (result != null) {
      result.fold(
        onSuccess: (list) {
          _allTermsList = list;
          _logDetailedApiResponse(list);
          _validateTermsList();
          safeNotifyListeners();
        },
        onFailure: (error) {
          AppLogger.e('약관 로드 실패: ${error.message}');
          _allTermsList = [];
          setError(error.message);
          safeNotifyListeners();
        },
      );
    } else {
      AppLogger.w('[WARNING] 약관 API 응답이 null입니다');
      _allTermsList = [];
      safeNotifyListeners();
    }
  }

  /// 상세한 API 응답 로깅
  void _logDetailedApiResponse(List<CmdModel> list) {
    AppLogger.d('');
    AppLogger.d('=== 상세 약관 API 응답 분석 === ');
    AppLogger.d('총 ${list.length}개 약관 수신');
    AppLogger.d('');

    for (int i = 0; i < list.length; i++) {
      final terms = list[i];
      AppLogger.d('[$i] ━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.d('ID: ${terms.id}');
      AppLogger.d('제목: "${terms.terms_nm}"');
      AppLogger.d('날짜: ${terms.terms_dt}');

      // 내용 미리보기 (더 길게)
      final content = terms.terms_ctt ?? '';
      final preview =
          content.length > 100 ? content.substring(0, 100) : content;
      AppLogger.d('내용: "$preview${content.length > 100 ? "..." : ""}"');
      AppLogger.d('');
    }

    AppLogger.d(' === 매핑 시도 결과 === ');

    // 각 타입별 매핑 시도하면서 상세 로그
    _tryMapTerm('서비스 이용약관', ['서비스'], ['위치', '기반']);
    _tryMapTerm('개인정보 처리방침', ['개인정보'], ['위치', '기반']);
    _tryMapTerm('위치기반 서비스', ['위치', '기반'], []);
    _tryMapTerm('마케팅 활용 동의', ['마케팅'], []);
  }

  /// 매핑 시도 과정 로깅
  void _tryMapTerm(String termName, List<String> includeKeywords,
      List<String> excludeKeywords) {
    AppLogger.d(' "$termName" 매핑 시도...');
    AppLogger.d('포함 키워드: $includeKeywords');
    AppLogger.d('제외 키워드: $excludeKeywords');

    if (_allTermsList == null) {
      AppLogger.d('_allTermsList가 null');
      return;
    }

    for (int i = 0; i < _allTermsList!.length; i++) {
      final terms = _allTermsList![i];
      final title = terms.terms_nm?.toLowerCase() ?? '';

      AppLogger.d('   [$i] "${terms.terms_nm}" 검사중...');

      // 포함 키워드 체크
      bool allIncludeFound = includeKeywords.every((keyword) {
        final found = title.contains(keyword.toLowerCase());
        AppLogger.d('포함 "$keyword": $found');
        return found;
      });

      // 제외 키워드 체크
      bool anyExcludeFound = excludeKeywords.any((keyword) {
        final found = title.contains(keyword.toLowerCase());
        AppLogger.d('제외 "$keyword": $found');
        return found;
      });

      if (allIncludeFound && !anyExcludeFound) {
        AppLogger.d('매핑 성공: "$termName" ← "${terms.terms_nm}"');
        return;
      }
    }

    AppLogger.d('매핑 실패: "$termName"에 해당하는 약관을 찾을 수 없음');
  }

  /// 약관 리스트 유효성 검증
  void _validateTermsList() {
    if (_allTermsList == null || _allTermsList!.isEmpty) {
      setError('약관 정보를 찾을 수 없습니다');
      return;
    }

    // 필수 약관들이 모두 찾아졌는지 확인
    final missingTerms = <String>[];
    if (serviceTerms == null) missingTerms.add('서비스 이용약관');
    if (privacyPolicy == null) missingTerms.add('개인정보 처리방침');
    if (locationTerms == null) missingTerms.add('위치기반 서비스 약관');

    if (missingTerms.isNotEmpty) {
      AppLogger.d('누락된 약관: ${missingTerms.join(", ")}');
      setError('필수 약관을 찾을 수 없습니다: ${missingTerms.join(", ")}');
    } else {
      AppLogger.d('모든 필수 약관 매핑 성공');
    }
  }

  /// 제목 키워드로 약관 찾기 (제외 키워드 포함)
  CmdModel? _getTermsByTitle(List<String> includeKeywords,
      {List<String> excludeKeywords = const <String>[]}) {
    if (_allTermsList == null) return null;

    for (final terms in _allTermsList!) {
      final title = terms.terms_nm?.toLowerCase() ?? '';

      // 모든 포함 키워드가 제목에 포함되어 있는지 확인
      bool allIncludeFound = includeKeywords
          .every((keyword) => title.contains(keyword.toLowerCase()));

      // 제외 키워드가 제목에 포함되어 있는지 확인
      bool anyExcludeFound = excludeKeywords
          .any((keyword) => title.contains(keyword.toLowerCase()));

      if (allIncludeFound && !anyExcludeFound) {
        return terms;
      }
    }

    return null;
  }

  /// 특정 타입의 약관 가져오기
  CmdModel? getTermsByType(TermsType type) {
    switch (type) {
      case TermsType.service:
        return serviceTerms;
      case TermsType.privacy:
        return privacyPolicy;
      case TermsType.location:
        return locationTerms;
      case TermsType.marketing:
        return marketingTerms;
    }
  }

  /// 타입별 약관명 가져오기 (UI 표시용)
  String getTermsTitle(TermsType type) {
    switch (type) {
      case TermsType.service:
        return '서비스 이용약관';
      case TermsType.privacy:
        return '개인정보수집/이용 동의';
      case TermsType.location:
        return '위치기반 서비스 이용약관';
      case TermsType.marketing:
        return '마케팅 활용 동의';
    }
  }

  /// 약관 동의 상태 변경
  void updateAgreement(TermsType type, bool agreed) {
    executeSafe(() {
      _agreementStatus[type] = agreed;
      safeNotifyListeners();
    });
  }

  /// 전체 약관 동의/해제
  void updateAllAgreements(bool agreed) {
    executeSafe(() {
      _agreementStatus.forEach((key, _) {
        _agreementStatus[key] = agreed;
      });
      safeNotifyListeners();
    });
  }

  /// 약관 데이터 초기화
  void clearTerms() {
    executeSafe(() {
      _allTermsList = null;
      _agreementStatus.forEach((key, _) {
        _agreementStatus[key] = false;
      });
      safeNotifyListeners();
    });
  }

  /// 약관 새로고침
  Future<void> refreshTerms() async {
    clearTerms();
    await loadAllTerms();
  }

  @override
  void dispose() {
    // Terms 관련 리소스 정리
    _allTermsList?.clear();
    _allTermsList = null;

    // 동의 상태 초기화
    _agreementStatus.forEach((key, _) {
      _agreementStatus[key] = false;
    });

    AppLogger.d('TermsProvider disposed');

    super.dispose();
  }
}

/// 약관 타입 enum
enum TermsType {
  service, // 서비스 이용약관
  privacy, // 개인정보 처리방침
  location, // 위치기반 서비스
  marketing // 마케팅 활용 동의
}
