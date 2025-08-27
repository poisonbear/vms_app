import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';

class MarketingTermsProvider with ChangeNotifier {
  late final GetTermsList _getTermsList;
  List<CmdModel>? _CmdList;
  List<CmdModel>? get CmdList => _CmdList;

  MarketingTermsProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    List<CmdModel> fetchedList = await _getTermsList.execute();
    if (fetchedList.length > 3) {
      _CmdList = [fetchedList[3]];
    } else {
      _CmdList = [];
    }
    notifyListeners();
  }
}