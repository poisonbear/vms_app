import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';

class PrivacyPolicyProvider with ChangeNotifier {
  late final GetTermsList _getTermsList;

  // 변수명 수정: _CmdList -> _cmdList
  List<CmdModel>? _cmdList;

  // Getter 수정: CmdList -> cmdList
  List<CmdModel>? get cmdList => _cmdList;

  // 하위 호환성
  @deprecated
  List<CmdModel>? get CmdList => cmdList;

  PrivacyPolicyProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    List<CmdModel> fetchedList = await _getTermsList.execute();
    if (fetchedList.length > 1) {
      _cmdList = [fetchedList[1]];
    } else {
      _cmdList = [];
    }
    notifyListeners();
  }
}
