// lib/data/models/vessel_model.dart

// ===== 공통 헬퍼 함수 =====
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// 선박 기본 정보 모델 (기존 VesselSearchModel)
class VesselModel {
  int? mmsi;
  String? ship_nm;
  String? ship_kdn;
  String? ship_knd;
  String? psng_auth;
  String? psng_auth_cd;
  double? lntd;
  double? lttd;
  String? shiptype;
  String? shiptype_nm;
  double? sog; // Speed Over Ground (대지속도)
  double? cog; // Course Over Ground (대지침로)
  double? draft; // 흘수
  String? escapeRouteGeojson; // 대피 경로 GeoJSON

  VesselModel({
    this.mmsi,
    this.ship_nm,
    this.ship_kdn,
    this.ship_knd,
    this.psng_auth,
    this.psng_auth_cd,
    this.lntd,
    this.lttd,
    this.shiptype,
    this.shiptype_nm,
    this.sog,
    this.cog,
    this.draft,
    this.escapeRouteGeojson,
  });

  factory VesselModel.fromJson(Map<String, dynamic> json) {
    return VesselModel(
      mmsi: json['mmsi'] != null ? int.tryParse(json['mmsi'].toString()) : null,
      ship_nm: json['ship_nm']?.toString(),
      ship_kdn: json['ship_kdn']?.toString(),
      ship_knd: json['ship_knd']?.toString() ?? json['ship_kdn']?.toString(),
      psng_auth: json['psng_auth']?.toString(),
      psng_auth_cd: json['psng_auth_cd']?.toString(),
      lntd: _parseDouble(json['lntd']),
      lttd: _parseDouble(json['lttd']),
      shiptype: json['shiptype']?.toString(),
      shiptype_nm: json['shiptype_nm']?.toString(),
      sog: _parseDouble(json['sog']),
      cog: _parseDouble(json['cog']),
      draft: _parseDouble(json['draft']),
      escapeRouteGeojson: json['escape_route_geojson']?.toString() ??
          json['escapeRouteGeojson']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mmsi': mmsi,
      'ship_nm': ship_nm,
      'ship_kdn': ship_kdn,
      'ship_knd': ship_knd,
      'psng_auth': psng_auth,
      'psng_auth_cd': psng_auth_cd,
      'rcv_loc_lntd': lntd,
      'rcv_loc_lttd': lttd,
      'shiptype': shiptype,
      'shiptype_nm': shiptype_nm,
      'sog': sog,
      'cog': cog,
      'draft': draft,
      'escape_route_geojson': escapeRouteGeojson,
    };
  }

  @override
  String toString() {
    return 'VesselModel(mmsi: $mmsi, ship_nm: $ship_nm, lntd: $lntd, lttd: $lttd, sog: $sog, cog: $cog)';
  }
}

/// 과거 항로 모델 (기존 PastRouteSearchModel)
class PastRouteModel {
  int? regDt;
  int? mmsi;
  double? lntd;
  double? lttd;
  double? sog;
  double? cog;

  PastRouteModel({
    this.regDt,
    this.mmsi,
    this.lntd,
    this.lttd,
    this.sog,
    this.cog,
  });

  factory PastRouteModel.fromJson(Map<String, dynamic> json) {
    return PastRouteModel(
      regDt: json['reg_dt'] != null
          ? int.tryParse(json['reg_dt'].toString())
          : null,
      mmsi: json['mmsi'] != null ? int.tryParse(json['mmsi'].toString()) : null,
      lntd: _parseDouble(json['rcv_loc_lntd']),
      lttd: _parseDouble(json['rcv_loc_lttd']),
      sog: _parseDouble(json['sog']),
      cog: _parseDouble(json['cog']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'regDt': regDt,
      'mmsi': mmsi,
      'lntd': lntd,
      'lttd': lttd,
      'sog': sog,
      'cog': cog,
    };
  }

  @override
  String toString() {
    return 'PastRouteModel(regDt: $regDt, mmsi: $mmsi, lntd: $lntd, lttd: $lttd, sog: $sog, cog: $cog)';
  }
}

/// 예측 항로 모델
class PredRouteModel {
  int? pdcthh;
  double? lntd;
  double? lttd;
  double? sog;

  PredRouteModel({
    this.pdcthh,
    this.lntd,
    this.lttd,
    this.sog,
  });

  factory PredRouteModel.fromJson(Map<String, dynamic> json) {
    return PredRouteModel(
      pdcthh: json['pdct_cord_hh'] != null
          ? int.tryParse(json['pdct_cord_hh'].toString())
          : null,
      lntd: _parseDouble(json['pdct_lntd']),
      lttd: _parseDouble(json['pdct_lttd']),
      sog: _parseDouble(json['pdct_sog']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pdcthh': pdcthh,
      'lntd': lntd,
      'lttd': lttd,
      'sog': sog,
    };
  }

  @override
  String toString() {
    return 'PredRouteModel(pdcthh: $pdcthh, lntd: $lntd, lttd: $lttd, sog: $sog)';
  }
}

/// 선박 항로 응답 모델
class VesselRouteResponse {
  final List<PredRouteModel> pred;
  final List<PastRouteModel> past;

  VesselRouteResponse({
    required this.pred,
    required this.past,
  });

  factory VesselRouteResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> predList = json['pred'] ?? [];
    final List<dynamic> pastList = json['past'] ?? [];

    return VesselRouteResponse(
      pred: predList.map((item) => PredRouteModel.fromJson(item)).toList(),
      past: pastList.map((item) => PastRouteModel.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pred': pred.map((item) => item.toJson()).toList(),
      'past': past.map((item) => item.toJson()).toList(),
    };
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
// 기존 코드에서 사용하던 클래스명 매핑
typedef VesselSearchModel = VesselModel;
typedef PastRouteSearchModel = PastRouteModel;
typedef PredRouteSearchModel = PredRouteModel;

/// RouteSearchModel - 기존 코드 호환용
class RouteSearchModel {
  final List<PastRouteModel> pastRoutes;
  final List<PredRouteModel> predRoutes;

  RouteSearchModel({
    required this.pastRoutes,
    required this.predRoutes,
  });

  factory RouteSearchModel.fromVesselRouteResponse(
      VesselRouteResponse response) {
    return RouteSearchModel(
      pastRoutes: response.past,
      predRoutes: response.pred,
    );
  }
}
