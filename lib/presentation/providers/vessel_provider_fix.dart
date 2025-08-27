import 'package:flutter/cupertino.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/domain/usecases/vessel/search_vessel.dart';

class VesselProvider with ChangeNotifier {
  late final VesselRepository _vesselRepository;
  late final SearchVessel _searchVessel;

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<VesselSearchModel> _vessels = [];
  List<VesselSearchModel> get vessels => _vessels;

  VesselProvider() {
    // ✅ DI 컨테이너에서 주입
    _vesselRepository = getIt<VesselRepository>();
    _searchVessel = getIt<SearchVessel>();
  }

  Future<void> getVesselList({String? regDt, int? mmsi}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Repository 직접 호출 (UseCase 패턴 제거 - 현재는 단순 구조 유지)
      _vessels = await _vesselRepository.getVesselList(regDt: regDt, mmsi: mmsi);
      
      // 또는 UseCase 패턴을 사용하려면:
      // final params = SearchVesselParams(regDt: regDt, mmsi: mmsi);
      // _vessels = await _searchVessel.execute(params);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
