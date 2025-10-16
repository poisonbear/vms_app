/// 기상 정보 도메인 엔티티
class WeatherEntity {
  final double waveHeight;
  final double visibility;
  final double windSpeed;
  final String windDirection;
  final DateTime observationTime;
  final double? temperature;
  final double? humidity;

  WeatherEntity({
    required this.waveHeight,
    required this.visibility,
    required this.windSpeed,
    required this.windDirection,
    required this.observationTime,
    this.temperature,
    this.humidity,
  });

  /// 위험 여부
  bool get isDangerous =>
      waveHeight > 3.0 || visibility < 1000 || windSpeed > 20;

  /// 안전 레벨
  SafetyLevel get safetyLevel {
    if (waveHeight > 4.0 || visibility < 500) return SafetyLevel.danger;
    if (waveHeight > 2.0 || visibility < 1000) return SafetyLevel.caution;
    return SafetyLevel.safe;
  }

  /// 항행 가능 여부
  bool get isNavigable => safetyLevel != SafetyLevel.danger;

  /// 안전 레벨 한글 표시
  String get safetyText {
    switch (safetyLevel) {
      case SafetyLevel.danger:
        return '위험';
      case SafetyLevel.caution:
        return '주의';
      case SafetyLevel.safe:
        return '안전';
    }
  }
}

enum SafetyLevel { safe, caution, danger }
