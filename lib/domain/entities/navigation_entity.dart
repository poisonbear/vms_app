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
  bool get isAnchored => speed < 0.5;

  /// 이동 중 여부
  bool get isMoving => speed >= 0.5;

  /// 고속 항행 여부
  bool get isHighSpeed => speed > 20.0;

  /// 위치 유효성 검증
  bool get hasValidPosition =>
      latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;

  /// 항행 상태 문자열
  String get status {
    if (isAnchored) return '정박 중';
    if (isHighSpeed) return '고속 항행';
    if (isMoving) return '항행 중';
    return '알 수 없음';
  }
}
