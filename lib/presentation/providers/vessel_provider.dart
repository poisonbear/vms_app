import 'package:vms_app/data/repositories/vessel_repository_impl.dart';
import 'package:vms_app/domain/usecases/vessel/search_vessel.dart';

import 'package:flutter/cupertino.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';

class VesselProvider with ChangeNotifier {
  late final VesselRepositoryImpl _vesselRepository;
  late final SearchVessel _searchVessel;

  bool _isLoading = false; //로딩여부
  String _errorMessage = ''; //에러메시지

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<VesselSearchModel> _vessels = []; // 선박 목록 저장용 리스트
  List<VesselSearchModel> get vessels => _vessels;

  VesselProvider() {
    _vesselRepository = VesselRepositoryImpl();
    _searchVessel = SearchVessel(_vesselRepository);
  }

  Future<void> getVesselList({String? regDt, int? mmsi}) async {
    try {
      _isLoading = true;
      notifyListeners();

      //("요청 파라미터: regDt=$regDt, mmsi=$mmsi");

      // Repository로부터 List<VesselSearchModel> 받아오기
      _vessels =
          await _vesselRepository.getVesselList(regDt: regDt, mmsi: mmsi);

      //print("선박 데이터 로드 성공: ${_vessels.length}개 항목");
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
