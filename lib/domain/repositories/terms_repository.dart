import 'package:vms_app/data/models/terms_model.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/result.dart';

/// 약관 정보 저장소 인터페이스
abstract class TermsRepository {
  /// 약관 목록 조회
  Future<Result<List<TermsModel>, AppException>> getCmdList();
}
