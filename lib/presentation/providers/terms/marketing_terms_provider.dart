import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class MarketingTermsProvider extends BaseProvider {
  late final GetTermsList _getTermsList;

  List<CmdModel>? _cmdList;
  List<CmdModel>? get cmdList => _cmdList;

  // 하위 호환성을 위한 deprecated getter
  @deprecated
  List<CmdModel>? get CmdList => cmdList;

  MarketingTermsProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    await executeAsync<void>(
      () async {
        final result = await _getTermsList.execute();
        
        result.fold(
          onSuccess: (list) {
            // 마케팅 활용 동의 약관 (네 번째 약관)
            if (list.length > 3) {
              _cmdList = [list[3]];
            } else {
              _cmdList = [];
              setError('마케팅 활용 동의 약관을 찾을 수 없습니다');
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
