import 'package:vms_app/domain/repositories/terms_repository.dart';
import 'package:vms_app/data/models/terms_model.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/result.dart';

/// 약관 관련 UseCase 모음
class TermsUseCases {
  final TermsRepository _repository;

  TermsUseCases(this._repository);

  /// 약관 목록 조회
  Future<Result<List<TermsModel>, AppException>> getTermsList() async {
    return await _repository.getCmdList();
  }
}

// ===== 개별 UseCase 클래스들 (기존 호환성 유지) =====

/// 약관 목록 조회 UseCase (기존 GetTermsList)
class GetTermsList {
  final TermsRepository repository;

  GetTermsList(this.repository);

  Future<Result<List<TermsModel>, AppException>> execute() async {
    return await repository.getCmdList();
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef GetCmdList = GetTermsList;
