import 'package:vms_app/core/constants/constants.dart';

/// Domain Entity - 비즈니스 로직에 필요한 순수한 데이터 구조
/// Model과 달리 외부 의존성이 없음
class VesselEntity {
  final int mmsi;
  final String shipName;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final DateTime? lastUpdated;

  VesselEntity({
    required this.mmsi,
    required this.shipName,
    this.latitude,
    this.longitude,
    this.speed,
    this.lastUpdated,
  });

  /// 선박이 이동 중인지 확인 (비즈니스 로직)
  bool get isMoving =>
      speed != null && speed! > NumericConstants.movingSpeedThreshold;

  /// 위치 정보가 있는지 확인
  bool get hasLocation => latitude != null && longitude != null;
}
