import 'package:vms_app/domain/repositories/terms_repository.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';

class GetTermsList {
  final TermsRepository repository;

  GetTermsList(this.repository);

  Future<List<CmdModel>> execute() async {
    return await repository.getCmdList();
  }
}
