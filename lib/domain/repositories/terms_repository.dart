import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/result.dart';

abstract class TermsRepository {
  Future<Result<List<CmdModel>, AppException>> getCmdList();
}
