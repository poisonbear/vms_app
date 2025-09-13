import 'package:vms_app/domain/repositories/terms_repository.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';

class GetTermsList {
  final TermsRepository repository;

  GetTermsList(this.repository);

  Future<Result<List<CmdModel>, AppException>> execute() async {
    return await repository.getCmdList();
  }
}
