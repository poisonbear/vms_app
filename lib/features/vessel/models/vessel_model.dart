// lib/features/vessel/models/vessel_model.dart
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:math' as math; // math 라이브러리 추가

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

  /// 퇴각 항로 좌표 파싱 (null safety 수정)
  List<LatLng> get escapeRoutePoints {
    if (!hasEscapeRoute) return [];

    try {
      final decodedOnce = jsonDecode(escapeRouteGeojson!);
      final geoJson = decodedOnce is String ? jsonDecode(decodedOnce) : decodedOnce;

      if (geoJson is Map<String, dynamic> && geoJson['coordinates'] is List) {
        final coords = geoJson['coordinates'] as List;
        return coords
            .map<LatLng?>((c) {
          if (c is List && c.length >= 2) {
            final lon = double.tryParse(c[0].toString());
            final lat = double.tryParse(c[1].toString());
            if (lat != null && lon != null) {
              return LatLng(lat, lon);
            }
          }
          return null;
        })
            .where((point) => point != null)
            .cast<LatLng>()
            .toList();
      }
    } catch (e) {
      // print 대신 적절한 로깅 사용
      // logger가 사용 가능하다면 logger.w() 사용 권장
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

  /// 선박 속도가 유효한지 확인
  bool get hasValidSpeed {
    return speedOverGround != null && speedOverGround! >= 0;
  }

  /// 선박이 움직이고 있는지 확인 (속도 > 0.1 knots)
  bool get isMoving {
    return hasValidSpeed && speedOverGround! > 0.1;
  }

  /// 선박의 방향이 유효한지 확인
  bool get hasValidCourse {
    return courseOverGround != null &&
        courseOverGround! >= 0 &&
        courseOverGround! <= 360;
  }

  /// 선박의 heading이 유효한지 확인
  bool get hasValidHeading {
    return heading != null &&
        heading! >= 0 &&
        heading! <= 360;
  }

  /// 선박 크기 정보가 있는지 확인
  bool get hasDimensions {
    return locCrlptA != null &&
        locCrlptB != null &&
        locCrlptC != null &&
        locCrlptD != null;
  }

  /// 선박 전체 길이 계산
  double? get totalLength {
    if (locCrlptA != null && locCrlptB != null) {
      return (locCrlptA! + locCrlptB!).toDouble();
    }
    return null;
  }

  /// 선박 전체 폭 계산
  double? get totalWidth {
    if (locCrlptC != null && locCrlptD != null) {
      return (locCrlptC! + locCrlptD!).toDouble();
    }
    return null;
  }

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
      shipName: _parseToString(json['ship_nm']),
      shipKind: _parseToString(json['ship_knd']),
      codeNm: _parseToString(json['cd_nm']),
      locCrlptA: _parseToInt(json['loc_crlpt_a']),
      locCrlptB: _parseToInt(json['loc_crlpt_b']),
      locCrlptC: _parseToInt(json['loc_crlpt_c']),
      locCrlptD: _parseToInt(json['loc_crlpt_d']),
      draft: _parseToDouble(json['draft']),
      destination: _parseToString(json['destn']),
      escapeRouteGeojson: _parseToString(json['escape_route_geojson']),
      lastUpdate: _parseToDateTime(json['last_update']) ?? DateTime.now(),
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
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    if (value is double) return value.round();
    return null;
  }

  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  static String? _parseToString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString();
  }

  static DateTime? _parseToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is int) {
      try {
        // Unix timestamp를 밀리초로 가정
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return null;
      }
    }
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

  /// 선박 위치 업데이트 (lastUpdate도 함께 갱신)
  VesselModel updatePosition({
    required double latitude,
    required double longitude,
    double? speedOverGround,
    double? courseOverGround,
    double? heading,
  }) {
    return copyWith(
      latitude: latitude,
      longitude: longitude,
      speedOverGround: speedOverGround ?? this.speedOverGround,
      courseOverGround: courseOverGround ?? this.courseOverGround,
      heading: heading ?? this.heading,
      lastUpdate: DateTime.now(),
    );
  }

  /// 선박이 특정 영역 내에 있는지 확인
  bool isWithinBounds({
    required double northEast_lat,
    required double northEast_lng,
    required double southWest_lat,
    required double southWest_lng,
  }) {
    if (latitude == null || longitude == null) return false;

    return latitude! >= southWest_lat &&
        latitude! <= northEast_lat &&
        longitude! >= southWest_lng &&
        longitude! <= northEast_lng;
  }

  /// 다른 선박과의 거리 계산 (근사치, km 단위)
  double? distanceToVessel(VesselModel other) {
    if (position == null || other.position == null) return null;

    // Haversine 공식을 사용한 거리 계산
    const double earthRadius = 6371; // km

    final lat1Rad = position!.latitude * (math.pi / 180);
    final lat2Rad = other.position!.latitude * (math.pi / 180);
    final deltaLatRad = (other.position!.latitude - position!.latitude) * (math.pi / 180);
    final deltaLngRad = (other.position!.longitude - position!.longitude) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
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
    return 'VesselModel(mmsi: $mmsi, shipName: $shipName, lat: $latitude, lng: $longitude, sog: $speedOverGround)';
  }

  /// 디버그용 상세 정보 출력
  String toDetailedString() {
    return '''
VesselModel {
  MMSI: $mmsi
  Ship Name: $shipName
  Position: ${latitude != null && longitude != null ? '($latitude, $longitude)' : 'Unknown'}
  Speed: ${speedOverGround ?? 'Unknown'} knots
  Course: ${courseOverGround ?? 'Unknown'}°
  Heading: ${heading ?? 'Unknown'}°
  Ship Kind: $shipKind
  Destination: $destination
  Draft: ${draft ?? 'Unknown'} m
  Last Update: ${lastUpdate ?? 'Unknown'}
  Is Valid: $isValid
  Is Moving: $isMoving
  Is Stale: $isStale
}''';
  }
}