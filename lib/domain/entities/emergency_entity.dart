/// 긴급 상황 도메인 엔티티
class EmergencyEntity {
  final String emergencyId;
  final int? mmsi;
  final String? shipName;
  final double? latitude;
  final double? longitude;
  final DateTime registeredDate;
  final EmergencyStatus status;
  final String? phoneNumber;
  final Map<String, dynamic>? additionalInfo;

  EmergencyEntity({
    required this.emergencyId,
    this.mmsi,
    this.shipName,
    this.latitude,
    this.longitude,
    required this.registeredDate,
    required this.status,
    this.phoneNumber,
    this.additionalInfo,
  });

  /// 위치 정보가 있는지 확인
  bool get hasLocation => latitude != null && longitude != null;

  /// 긴급 상황이 활성 상태인지 확인
  bool get isActive =>
      status == EmergencyStatus.active || status == EmergencyStatus.inProgress;

  /// 긴급 상황이 완료되었는지 확인
  bool get isCompleted =>
      status == EmergencyStatus.resolved || status == EmergencyStatus.cancelled;

  /// 긴급 상황 경과 시간 (분)
  int get elapsedMinutes => DateTime.now().difference(registeredDate).inMinutes;

  /// 긴급 상황이 오래된 것인지 확인 (24시간 이상)
  bool get isOld => DateTime.now().difference(registeredDate).inHours >= 24;

  /// 상태별 한글 표시
  String get statusText {
    switch (status) {
      case EmergencyStatus.active:
        return '활성';
      case EmergencyStatus.inProgress:
        return '처리중';
      case EmergencyStatus.resolved:
        return '해결됨';
      case EmergencyStatus.cancelled:
        return '취소됨';
    }
  }

  /// 우선순위 레벨
  EmergencyPriority get priority {
    if (elapsedMinutes > 60) return EmergencyPriority.high;
    if (elapsedMinutes > 30) return EmergencyPriority.medium;
    return EmergencyPriority.low;
  }

  /// 우선순위별 한글 표시
  String get priorityText {
    switch (priority) {
      case EmergencyPriority.high:
        return '높음';
      case EmergencyPriority.medium:
        return '보통';
      case EmergencyPriority.low:
        return '낮음';
    }
  }
}

enum EmergencyStatus { active, inProgress, resolved, cancelled }

enum EmergencyPriority { low, medium, high }
