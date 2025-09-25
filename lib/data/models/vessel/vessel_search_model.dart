import 'package:vms_app/core/utils/helpers.dart';

class VesselSearchModel {
  final int? mmsi;
  final double? lttd;
  final double? lntd;
  final double? sog;
  final double? cog;
  final double? hdg;
  final String? ship_nm;
  final String? ship_knd;
  final String? cd_nm;
  final int? loc_crlpt_a;
  final int? loc_crlpt_b;
  final int? loc_crlpt_c;
  final int? loc_crlpt_d;
  final double? draft;
  final String? destn;
  final String? escapeRouteGeojson;

  const VesselSearchModel({
    this.mmsi,
    this.lttd,
    this.lntd,
    this.sog,
    this.cog,
    this.hdg,
    this.ship_nm,
    this.ship_knd,
    this.cd_nm,
    this.loc_crlpt_a,
    this.loc_crlpt_b,
    this.loc_crlpt_c,
    this.loc_crlpt_d,
    this.draft,
    this.destn,
    this.escapeRouteGeojson,
  });

  factory VesselSearchModel.fromJson(Map<String, dynamic> json) {
    return VesselSearchModel(
      mmsi: JsonParser.parseInt(json['mmsi']),
      lttd: JsonParser.parseDouble(json['lttd']),
      lntd: JsonParser.parseDouble(json['lntd']),
      sog: JsonParser.parseDouble(json['sog']),
      cog: JsonParser.parseDouble(json['cog']),
      hdg: JsonParser.parseDouble(json['hdg']),
      ship_nm: JsonParser.parseString(json['ship_nm']),
      ship_knd: JsonParser.parseString(json['ship_knd']),
      cd_nm: JsonParser.parseString(json['cd_nm']),
      loc_crlpt_a: JsonParser.parseInt(json['loc_crlpt_a']),
      loc_crlpt_b: JsonParser.parseInt(json['loc_crlpt_b']),
      loc_crlpt_c: JsonParser.parseInt(json['loc_crlpt_c']),
      loc_crlpt_d: JsonParser.parseInt(json['loc_crlpt_d']),
      draft: JsonParser.parseDouble(json['draft']),
      destn: JsonParser.parseString(json['destn']),
      escapeRouteGeojson: JsonParser.parseString(json['escape_route_geojson']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mmsi': mmsi,
      'lttd': lttd,
      'lntd': lntd,
      'sog': sog,
      'cog': cog,
      'hdg': hdg,
      'ship_nm': ship_nm,
      'ship_knd': ship_knd,
      'cd_nm': cd_nm,
      'loc_crlpt_a': loc_crlpt_a,
      'loc_crlpt_b': loc_crlpt_b,
      'loc_crlpt_c': loc_crlpt_c,
      'loc_crlpt_d': loc_crlpt_d,
      'draft': draft,
      'destn': destn,
      'escape_route_geojson': escapeRouteGeojson,
    };
  }
}
