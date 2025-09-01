import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';

abstract class TermsRepository {
  Future<Result<List<CmdModel>, AppException>> getCmdList();
}
