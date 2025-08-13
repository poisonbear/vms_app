// lib/features/vessel/models/vessel_model.dart
import 'package:latlong2/latlong.dart';
import 'dart:convert';

/// 선박 정보를 나타내는 모델 클래스
/// 불변성을 보장하고 타입 안전성을 제공
class VesselModel {
  final int? mmsi;
  final double? latitude;
  final double? longitude;
  final double? speedOverGround;
  final double? courseOverGround;
  final double? heading;
  final String? shipName;
  final String? shipKind;
  final String? codeNm;
  final int? locCrlptA;
  final int? locCrlptB;
  final int? locCrlptC;
  final int? locCrlptD;
  final double? draft;
  final String? destination;
  final String? escapeRouteGeojson;
  final DateTime? lastUpdate;

  const VesselModel({
    this.mmsi,
    this.latitude,
    this.longitude,
    this.speedOverGround,
    this.courseOverGround,
    this.heading,
    this.shipName,
    this.shipKind,
    this.codeNm,
    this.locCrlptA,
    this.locCrlptB,
    this.locCrlptC,
    this.locCrlptD,
    this.draft,
    this.destination,
    this.escapeRouteGeojson,
    this.lastUpdate,
  });

  // ========================= 편의 메서드 =========================

  /// 선박 위치를 LatLng 객체로 반환
  LatLng? get position {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

  /// 선박 정보가 유효한지 확인
  bool get isValid {
    return mmsi != null &&
        latitude != null &&
        longitude != null &&
        shipName != null &&
        shipName!.isNotEmpty;
  }

  /// 퇴각 항로가 있는지 확인
  bool get hasEscapeRoute {
    return escapeRouteGeojson != null && escapeRouteGeojson!.isNotEmpty;
  }

  /// 퇴각 항로 좌표 파싱
  List<LatLng> get escapeRoutePoints {
    if (!hasEscapeRoute) return [];

    try {
      final decodedOnce = jsonDecode(escapeRouteGeojson!);
      final geoJson = decodedOnce is String ? jsonDecode(decodedOnce) : decodedOnce;

      if (geoJson['coordinates'] is List) {
        final coords = geoJson['coordinates'] as List;
        return coords.map<LatLng>((c) {
          final lon = double.tryParse(c[0].toString());
          final lat = double.tryParse(c[1].toString());
          if (lat == null || lon == null) return null;
          return LatLng(lat, lon);
        }).where((point) => point != null).cast<LatLng>().toList();
      }
    } catch (e) {
      print('Error parsing escape route: $e');
    }

    return [];
  }

  /// 마지막 업데이트로부터 경과 시간 (분 단위)
  int get minutesSinceLastUpdate {
    if (lastUpdate == null) return 0;
    return DateTime.now().difference(lastUpdate!).inMinutes;
  }

  /// 데이터가 오래되었는지 확인 (10분 기준)
  bool get isStale => minutesSinceLastUpdate > 10;

  // ========================= JSON 직렬화 =========================

  /// JSON에서 VesselModel 생성
  factory VesselModel.fromJson(Map<String, dynamic> json) {
    return VesselModel(
      mmsi: _parseToInt(json['mmsi']),
      latitude: _parseToDouble(json['lttd']),
      longitude: _parseToDouble(json['lntd']),
      speedOverGround: _parseToDouble(json['sog']),
      courseOverGround: _parseToDouble(json['cog']),
      heading: _parseToDouble(json['hdg']),
      shipName: json['ship_nm']?.toString(),
      shipKind: json['ship_knd']?.toString(),
      codeNm: json['cd_nm']?.toString(),
      locCrlptA: _parseToInt(json['loc_crlpt_a']),
      locCrlptB: _parseToInt(json['loc_crlpt_b']),
      locCrlptC: _parseToInt(json['loc_crlpt_c']),
      locCrlptD: _parseToInt(json['loc_crlpt_d']),
      draft: _parseToDouble(json['draft']),
      destination: json['destn']?.toString(),
      escapeRouteGeojson: json['escape_route_geojson']?.toString(),
      lastUpdate: DateTime.now(), // 현재 시간으로 설정
    );
  }

  /// VesselModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'mmsi': mmsi,
      'lttd': latitude,
      'lntd': longitude,
      'sog': speedOverGround,
      'cog': courseOverGround,
      'hdg': heading,
      'ship_nm': shipName,
      'ship_knd': shipKind,
      'cd_nm': codeNm,
      'loc_crlpt_a': locCrlptA,
      'loc_crlpt_b': locCrlptB,
      'loc_crlpt_c': locCrlptC,
      'loc_crlpt_d': locCrlptD,
      'draft': draft,
      'destn': destination,
      'escape_route_geojson': escapeRouteGeojson,
      'last_update': lastUpdate?.toIso8601String(),
    };
  }

  // ========================= 타입 안전 파싱 헬퍼 =========================

  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.round();
    return null;
  }

  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ========================= 객체 비교 및 복사 =========================

  /// 새로운 VesselModel 인스턴스 생성 (일부 필드 업데이트)
  VesselModel copyWith({
    int? mmsi,
    double? latitude,
    double? longitude,
    double? speedOverGround,
    double? courseOverGround,
    double? heading,
    String? shipName,
    String? shipKind,
    String? codeNm,
    int? locCrlptA,
    int? locCrlptB,
    int? locCrlptC,
    int? locCrlptD,
    double? draft,
    String? destination,
    String? escapeRouteGeojson,
    DateTime? lastUpdate,
  }) {
    return VesselModel(
      mmsi: mmsi ?? this.mmsi,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedOverGround: speedOverGround ?? this.speedOverGround,
      courseOverGround: courseOverGround ?? this.courseOverGround,
      heading: heading ?? this.heading,
      shipName: shipName ?? this.shipName,
      shipKind: shipKind ?? this.shipKind,
      codeNm: codeNm ?? this.codeNm,
      locCrlptA: locCrlptA ?? this.locCrlptA,
      locCrlptB: locCrlptB ?? this.locCrlptB,
      locCrlptC: locCrlptC ?? this.locCrlptC,
      locCrlptD: locCrlptD ?? this.locCrlptD,
      draft: draft ?? this.draft,
      destination: destination ?? this.destination,
      escapeRouteGeojson: escapeRouteGeojson ?? this.escapeRouteGeojson,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VesselModel &&
        other.mmsi == mmsi &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.shipName == shipName;
  }

  @override
  int get hashCode {
    return Object.hash(mmsi, latitude, longitude, shipName);
  }

  @override
  String toString() {
    return 'VesselModel(mmsi: $mmsi, shipName: $shipName, lat: $latitude, lng: $longitude)';
  }
}