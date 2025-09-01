import 'package:vms_app/data/datasources/remote/terms_remote_datasource.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/repositories/terms_repository.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';

class TermsRepositoryImpl implements TermsRepository {
  final CmdSource _dataSource;

  TermsRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<CmdModel>, AppException>> getCmdList() async {
    return await _dataSource.getCmdList();
  }
}
