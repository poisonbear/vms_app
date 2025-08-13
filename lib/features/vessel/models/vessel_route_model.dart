import 'package:equatable/equatable.dart';

/// 선박 항로 응답 모델
class VesselRouteResponse extends Equatable {
  const VesselRouteResponse({
    required this.pred,
    required this.past,
  });

  final List<PredRouteModel> pred;
  final List<PastRouteModel> past;

  factory VesselRouteResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> predList = json['pred'] ?? [];
    final List<dynamic> pastList = json['past'] ?? [];

    return VesselRouteResponse(
      pred: predList.map((item) => PredRouteModel.fromJson(item)).toList(),
      past: pastList.map((item) => PastRouteModel.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'pred': pred.map((e) => e.toJson()).toList(),
    'past': past.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [pred, past];
}

/// 예측 항로 모델
class PredRouteModel extends Equatable {
  const PredRouteModel({
    this.pdcthh,
    this.lntd,
    this.lttd,
    this.spd,
  });

  final int? pdcthh;
  final double? lntd;
  final double? lttd;
  final double? spd;

  factory PredRouteModel.fromJson(Map<String, dynamic> json) {
    return PredRouteModel(
      pdcthh: json['pdct_cord_hh'],
      lntd: json['pdct_lntd']?.toDouble(),
      lttd: json['pdct_lttd']?.toDouble(),
      spd: json['pdct_sog']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'pdct_cord_hh': pdcthh,
    'pdct_lntd': lntd,
    'pdct_lttd': lttd,
    'pdct_sog': spd,
  };

  @override
  List<Object?> get props => [pdcthh, lntd, lttd, spd];
}

/// 과거 항로 모델
class PastRouteModel extends Equatable {
  const PastRouteModel({
    this.regDt,
    this.mmsi,
    this.lntd,
    this.lttd,
    this.spd,
    this.cog,
  });

  final int? regDt;
  final int? mmsi;
  final double? lntd;
  final double? lttd;
  final double? spd;
  final double? cog;

  factory PastRouteModel.fromJson(Map<String, dynamic> json) {
    return PastRouteModel(
      regDt: json['reg_dt'],
      mmsi: json['mmsi'],
      lntd: json['rcv_loc_lntd']?.toDouble(),
      lttd: json['rcv_loc_lttd']?.toDouble(),
      spd: json['spd']?.toDouble(),
      cog: json['course']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'reg_dt': regDt,
    'mmsi': mmsi,
    'rcv_loc_lntd': lntd,
    'rcv_loc_lttd': lttd,
    'spd': spd,
    'course': cog,
  };

  @override
  List<Object?> get props => [regDt, mmsi, lntd, lttd, spd, cog];
}