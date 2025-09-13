import 'package:vms_app/core/constants/constants.dart';

/// 항행 정보 도메인 엔티티
class NavigationEntity {
  final int mmsi;
  final DateTime navigationDate;
  final double latitude;
  final double longitude;
  final double speed;
  final double course;
  final String? destinationPort;

  NavigationEntity({
    required this.mmsi,
    required this.navigationDate,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.course,
    this.destinationPort,
  });

  /// 정박 중 여부
  bool get isAnchored => speed < NumericConstants.movingSpeedThreshold;

  /// 이동 중 여부
  bool get isMoving => speed >= NumericConstants.movingSpeedThreshold;

  /// 고속 항행 여부
  bool get isHighSpeed => speed > NumericConstants.highSpeedThreshold;

  /// 위치 유효성 검증
  bool get hasValidPosition =>
      latitude >= NumericConstants.latitudeMin &&
      latitude <= NumericConstants.latitudeMax &&
      longitude >= NumericConstants.longitudeMin &&
      longitude <= NumericConstants.longitudeMax;

  /// 항행 상태 문자열
  String get status {
    if (isAnchored) return StringConstants.statusAnchored;
    if (isHighSpeed) return StringConstants.statusHighSpeed;
    if (isMoving) return StringConstants.statusMoving;
    return StringConstants.statusUnknown;
  }
}
