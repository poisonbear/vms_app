import 'package:equatable/equatable.dart';

/// 항행 이력 모델
class NavigationHistoryModel extends Equatable {
  const NavigationHistoryModel({
    this.mmsi,
    this.regDt,
    this.odbRegDate,
    this.shipName,
    this.shipKdn,
    this.psngAuth,
    this.psngAuthCd,
  });

  final int? mmsi;
  final int? regDt;
  final int? odbRegDate;
  final String? shipName;
  final String? shipKdn;
  final String? psngAuth;
  final String? psngAuthCd;

  factory NavigationHistoryModel.fromJson(Map<String, dynamic> json) {
    return NavigationHistoryModel(
      mmsi: json['mmsi'],
      regDt: json['reg_dt'],
      odbRegDate: json['odb_reg_date'],
      shipName: json['ship_nm'],
      shipKdn: json['ship_kdn'],
      psngAuth: json['psng_auth'],
      psngAuthCd: json['psng_auth_cd'],
    );
  }

  Map<String, dynamic> toJson() => {
    'mmsi': mmsi,
    'reg_dt': regDt,
    'odb_reg_date': odbRegDate,
    'ship_nm': shipName,
    'ship_kdn': shipKdn,
    'psng_auth': psngAuth,
    'psng_auth_cd': psngAuthCd,
  };

  @override
  List<Object?> get props => [
    mmsi,
    regDt,
    odbRegDate,
    shipName,
    shipKdn,
    psngAuth,
    psngAuthCd,
  ];
}