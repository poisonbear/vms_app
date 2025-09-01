import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class ServiceTermsProvider extends BaseProvider {
  late final GetTermsList _getTermsList;

  List<CmdModel>? _cmdList;
  List<CmdModel>? get cmdList => _cmdList;

  // 하위 호환성을 위한 deprecated getter
  @deprecated
  List<CmdModel>? get CmdList => cmdList;

  ServiceTermsProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    await executeAsync<void>(
      () async {
        final result = await _getTermsList.execute();
        
        result.fold(
          onSuccess: (list) {
            // 서비스 이용약관 (첫 번째 약관)
            if (list.isNotEmpty) {
              _cmdList = [list[0]];
            } else {
              _cmdList = [];
              setError('서비스 이용약관을 찾을 수 없습니다');
            }
            safeNotifyListeners();
          },
          onFailure: (error) {
            _cmdList = [];
            throw error; // BaseProvider가 처리
          },
        );
      },
      errorMessage: '약관을 불러오는 중 오류가 발생했습니다',
      showLoading: true,
    );
  }

  void clearTerms() {
    executeSafe(() {
      _cmdList = null;
      safeNotifyListeners();
    });
  }
}
