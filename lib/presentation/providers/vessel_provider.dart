import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';

class VesselProvider extends BaseProvider {
  late final VesselRepository _vesselRepository;

  List<VesselSearchModel> _vessels = [];
  List<VesselSearchModel> get vessels => _vessels;

  VesselProvider() {
    _vesselRepository = getIt<VesselRepository>();
  }

  Future<void> getVesselList({String? regDt, int? mmsi}) async {
    await executeAsync<void>(
      () async {
        _vessels = await _vesselRepository.getVesselList(
          regDt: regDt,
          mmsi: mmsi,
        );
        safeNotifyListeners();
      },
      errorMessage: '선박 목록을 불러오는 중 오류가 발생했습니다',
      onError: (error) {
        if (error is AuthException) {
          // 인증 에러 특별 처리
          setError('다시 로그인해주세요');
        }
      },
    );
  }

  void clearVessels() {
    executeSafe(() {
      _vessels = [];
      safeNotifyListeners();
    });
  }
}
