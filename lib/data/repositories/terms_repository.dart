import 'package:vms_app/data/datasources/terms_datasource.dart';
import 'package:vms_app/data/models/terms_model.dart';
import 'package:vms_app/domain/repositories/terms_repository.dart' as domain;
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/result.dart';

/// 약관 정보 저장소 구현
class TermsRepository implements domain.TermsRepository {
  final TermsDataSource _dataSource;

  TermsRepository(this._dataSource);

  /// 약관 목록 조회
  @override
  Future<Result<List<TermsModel>, AppException>> getCmdList() async {
    return await _dataSource.getCmdList();
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef TermsRepositoryImpl = TermsRepository;
