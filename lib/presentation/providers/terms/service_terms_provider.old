import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';

class ServiceTermsProvider with ChangeNotifier {
  late final GetTermsList _getTermsList;
  List<CmdModel>? _CmdList;
  List<CmdModel>? get CmdList => _CmdList;

  ServiceTermsProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    List<CmdModel> fetchedList = await _getTermsList.execute();
    if (fetchedList.isNotEmpty) {
      _CmdList = [fetchedList[0]];
    } else {
      _CmdList = [];
    }
    notifyListeners();
  }
}