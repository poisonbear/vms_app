import 'package:geolocator/geolocator.dart';

/// 긴급 상황 데이터 모델 - 프로젝트 파라미터명 규칙 적용
class EmergencyData {
  final String emergency_id;
  final int? mmsi;
  final String? ship_nm;
  final double? lttd; // 위도
  final double? lntd; // 경도
  final DateTime reg_dt;
  final String emergency_status;
  final String? phone_no;
  final Map<String, dynamic>? additional_info;

  EmergencyData({
    required this.emergency_id,
    this.mmsi,
    this.ship_nm,
    this.lttd,
    this.lntd,
    required this.reg_dt,
    required this.emergency_status,
    this.phone_no,
    this.additional_info,
  });

  /// Position 객체에서 위도/경도 추출하는 생성자
  factory EmergencyData.fromPosition({
    required String emergency_id,
    int? mmsi,
    String? ship_nm,
    Position? position,
    required DateTime reg_dt,
    required EmergencyStatus status,
    String? phone_no,
    Map<String, dynamic>? additional_info,
  }) {
    return EmergencyData(
      emergency_id: emergency_id,
      mmsi: mmsi,
      ship_nm: ship_nm,
      lttd: position?.latitude,
      lntd: position?.longitude,
      reg_dt: reg_dt,
      emergency_status: status.name,
      phone_no: phone_no,
      additional_info: additional_info,
    );
  }

  /// JSON 변환 (SharedPreferences 저장용)
  Map<String, dynamic> toJson() {
    return {
      'emergency_id': emergency_id,
      'mmsi': mmsi,
      'ship_nm': ship_nm,
      'lttd': lttd,
      'lntd': lntd,
      'reg_dt': reg_dt.toIso8601String(),
      'emergency_status': emergency_status,
      'phone_no': phone_no,
      'additional_info': additional_info,
    };
  }

  factory EmergencyData.fromJson(Map<String, dynamic> json) {
    return EmergencyData(
      emergency_id: json['emergency_id'],
      mmsi: json['mmsi'] != null ? int.tryParse(json['mmsi'].toString()) : null,
      ship_nm: json['ship_nm'],
      lttd: json['lttd']?.toDouble(),
      lntd: json['lntd']?.toDouble(),
      reg_dt: DateTime.parse(json['reg_dt']),
      emergency_status: json['emergency_status'],
      phone_no: json['phone_no'],
      additional_info: json['additional_info'],
    );
  }

  /// Position 객체로 변환 (호환성)
  Position? toPosition() {
    if (lttd == null || lntd == null) return null;

    return Position(
      latitude: lttd!,
      longitude: lntd!,
      timestamp: reg_dt,
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  EmergencyData copyWith({
    String? emergency_id,
    int? mmsi,
    String? ship_nm,
    double? lttd,
    double? lntd,
    DateTime? reg_dt,
    String? emergency_status,
    String? phone_no,
    Map<String, dynamic>? additional_info,
  }) {
    return EmergencyData(
      emergency_id: emergency_id ?? this.emergency_id,
      mmsi: mmsi ?? this.mmsi,
      ship_nm: ship_nm ?? this.ship_nm,
      lttd: lttd ?? this.lttd,
      lntd: lntd ?? this.lntd,
      reg_dt: reg_dt ?? this.reg_dt,
      emergency_status: emergency_status ?? this.emergency_status,
      phone_no: phone_no ?? this.phone_no,
      additional_info: additional_info ?? this.additional_info,
    );
  }
}

/// 긴급 상황 상태
enum EmergencyStatus {
  idle, // 평상시
  preparing, // 준비중 (카운트다운)
  active, // 긴급상황 활성
  completed, // 완료
  cancelled, // 취소됨
}

/// 위치 추적 데이터 - 프로젝트 파라미터명 규칙 적용
class LocationTrackingData {
  final double lttd; // 위도
  final double lntd; // 경도
  final DateTime reg_dt; // 등록일시
  final double? accuracy;
  final double? spd; // 속도
  final double? hdg; // 방향

  LocationTrackingData({
    required this.lttd,
    required this.lntd,
    required this.reg_dt,
    this.accuracy,
    this.spd,
    this.hdg,
  });

  /// Position 객체에서 생성
  factory LocationTrackingData.fromPosition({
    required Position position,
    required DateTime reg_dt,
  }) {
    return LocationTrackingData(
      lttd: position.latitude,
      lntd: position.longitude,
      reg_dt: reg_dt,
      accuracy: position.accuracy,
      spd: position.speed,
      hdg: position.heading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lttd': lttd,
      'lntd': lntd,
      'reg_dt': reg_dt.toIso8601String(),
      'accuracy': accuracy,
      'spd': spd,
      'hdg': hdg,
    };
  }

  factory LocationTrackingData.fromJson(Map<String, dynamic> json) {
    return LocationTrackingData(
      lttd: json['lttd']?.toDouble() ?? 0.0,
      lntd: json['lntd']?.toDouble() ?? 0.0,
      reg_dt: DateTime.parse(json['reg_dt']),
      accuracy: json['accuracy']?.toDouble(),
      spd: json['spd']?.toDouble(),
      hdg: json['hdg']?.toDouble(),
    );
  }

  /// Position 객체로 변환
  Position toPosition() {
    return Position(
      latitude: lttd,
      longitude: lntd,
      timestamp: reg_dt,
      accuracy: accuracy ?? 0,
      altitude: 0,
      heading: hdg ?? 0,
      speed: spd ?? 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}
