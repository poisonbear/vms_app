import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/data/models/vessel_model.dart';

/// 선박 검색 파라미터
class SearchVesselParams {
  final String? regDt;
  final int? mmsi;

  SearchVesselParams({this.regDt, this.mmsi});
}

/// 항로 검색 파라미터
class GetVesselRouteParams {
  final String? regDt;
  final int? mmsi;

  GetVesselRouteParams({this.regDt, this.mmsi});
}

/// 선박 관련 UseCase 모음
class VesselUseCases {
  final VesselRepository _repository;

  VesselUseCases(this._repository);

  /// 선박 목록 조회
  Future<List<VesselModel>> searchVessel(SearchVesselParams params) async {
    return await _repository.getVesselList(
      regDt: params.regDt,
      mmsi: params.mmsi,
    );
  }

  /// 선박 항로 조회 (과거 + 예측)
  Future<VesselRouteResponse> getVesselRoute(
      GetVesselRouteParams params) async {
    return await _repository.getVesselRoute(
      regDt: params.regDt,
      mmsi: params.mmsi,
    );
  }

  /// 간편한 선박 검색 (파라미터 직접 전달)
  Future<List<VesselModel>> getVesselList({
    String? regDt,
    int? mmsi,
  }) async {
    return await _repository.getVesselList(
      regDt: regDt,
      mmsi: mmsi,
    );
  }
}

// ===== 개별 UseCase 클래스들 (기존 호환성 유지) =====

/// 선박 검색 UseCase (기존 SearchVessel)
class SearchVessel {
  final VesselRepository repository;

  SearchVessel(this.repository);

  Future<List<VesselModel>> execute(SearchVesselParams params) async {
    return await repository.getVesselList(
      regDt: params.regDt,
      mmsi: params.mmsi,
    );
  }
}

/// 선박 항로 조회 UseCase (RouteSearch 기능)
class GetVesselRoute {
  final VesselRepository repository;

  GetVesselRoute(this.repository);

  Future<VesselRouteResponse> execute(GetVesselRouteParams params) async {
    return await repository.getVesselRoute(
      regDt: params.regDt,
      mmsi: params.mmsi,
    );
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef SearchVesselInfo = SearchVessel;
typedef GetRouteSearch = GetVesselRoute;
typedef RouteSearchUseCase = GetVesselRoute;
