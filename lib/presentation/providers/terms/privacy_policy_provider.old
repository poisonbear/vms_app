import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';

class PrivacyPolicyProvider with ChangeNotifier {
  late final GetTermsList _getTermsList;
  List<CmdModel>? _CmdList;
  List<CmdModel>? get CmdList => _CmdList;

  PrivacyPolicyProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    List<CmdModel> fetchedList = await _getTermsList.execute();
    if (fetchedList.length > 1) {
      _CmdList = [fetchedList[1]];
    } else {
      _CmdList = [];
    }
    notifyListeners();
  }
}