import 'package:vms_app/data/models/terms/terms_model.dart';

abstract class TermsRepository {
  Future<List<CmdModel>> getCmdList();
}
