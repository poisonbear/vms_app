import 'dart:math';
import 'package:vms_app/core/utils/app_logger.dart';

/// 풍향 계산 디버깅 유틸리티
class WindDebugUtils {
  /// 풍향 계산 및 표시 테스트 (8방위)
  static void testWindCalculation() {
    AppLogger.d('🌪️ === 풍향/풍속 표시 테스트 (8방위) ===');
    AppLogger.d('');
    AppLogger.d('📌 풍속: 반올림 처리 (소수점 제거)');
    AppLogger.d('📌 풍향: 8방위 한글 표시');
    AppLogger.d('📌 화살표: 바람이 가는 방향 (풍향 + 180°)');
    AppLogger.d('');
    AppLogger.d('📍 8방위 체계:');
    AppLogger.d('   북(N), 북동(NE), 동(E), 남동(SE),');
    AppLogger.d('   남(S), 남서(SW), 서(W), 북서(NW)');
    AppLogger.d('');

    // 8방위 테스트 케이스
    final testCases = [
      {'name': '정북풍', 'u': 0.0, 'v': -5.7, 'expectedSpeed': 6, 'expectedWind': 0, 'expectedText': '북풍'},
      {'name': '북동풍', 'u': -4.0, 'v': -4.0, 'expectedSpeed': 6, 'expectedWind': 45, 'expectedText': '북동풍'},
      {'name': '정동풍', 'u': -4.3, 'v': 0.0, 'expectedSpeed': 4, 'expectedWind': 90, 'expectedText': '동풍'},
      {'name': '남동풍', 'u': -3.0, 'v': 3.0, 'expectedSpeed': 4, 'expectedWind': 135, 'expectedText': '남동풍'},
      {'name': '정남풍', 'u': 0.0, 'v': 8.6, 'expectedSpeed': 9, 'expectedWind': 180, 'expectedText': '남풍'},
      {'name': '남서풍', 'u': 3.5, 'v': 3.5, 'expectedSpeed': 5, 'expectedWind': 225, 'expectedText': '남서풍'},
      {'name': '정서풍', 'u': 3.4, 'v': 0.0, 'expectedSpeed': 3, 'expectedWind': 270, 'expectedText': '서풍'},
      {'name': '북서풍', 'u': 2.8, 'v': -2.8, 'expectedSpeed': 4, 'expectedWind': 315, 'expectedText': '북서풍'},
    ];

    bool allPassed = true;

    for (final test in testCases) {
      final u = test['u'] as double;
      final v = test['v'] as double;
      final expectedSpeed = test['expectedSpeed'] as int;
      final expectedWind = test['expectedWind'] as int;
      final expectedText = test['expectedText'] as String;
      final name = test['name'] as String;

      // 풍속 계산
      double windSpeedValue = sqrt(u * u + v * v);
      int calculatedSpeed = windSpeedValue.round();

      // 풍향 계산
      double windDirectionRad = atan2(-u, -v);
      double windDirectionDegrees = windDirectionRad * 180 / pi;
      if (windDirectionDegrees < 0) windDirectionDegrees += 360;
      int calculatedWind = windDirectionDegrees.round() % 360;

      // 화살표 방향
      int calculatedArrow = (calculatedWind + 180) % 360;

      // 8방위 한글 방위명
      String calculatedText = directionToText8(calculatedWind);

      // 검증
      bool speedOk = calculatedSpeed == expectedSpeed;
      bool windOk = (calculatedWind - expectedWind).abs() <= 10; // 10도 오차 허용
      bool textOk = calculatedText == expectedText;

      if (!speedOk || !windOk || !textOk) allPassed = false;

      AppLogger.d('$name:');
      AppLogger.d('  입력: U=$u, V=$v');
      AppLogger.d(
          '  풍속: ${windSpeedValue.toStringAsFixed(2)} → $calculatedSpeed m/s ${speedOk ? "✅" : "❌ (예상: $expectedSpeed)"}');
      AppLogger.d('  풍향: $calculatedWind° ${windOk ? "✅" : "❌ (예상: $expectedWind°)"}');
      AppLogger.d('  방위: $calculatedText ${textOk ? "✅" : "❌ (예상: $expectedText)"}');
      AppLogger.d('  화살표: $calculatedArrow°');
      AppLogger.d('');
    }

    AppLogger.d(allPassed ? '✅ 모든 테스트 통과!' : '❌ 일부 테스트 실패');
    AppLogger.d('🌪️ ========================');
  }

  /// 방위각을 8방위 한글명으로 변환
  static String directionToText8(int direction) {
    const directions = [
      '북풍', // 0° (337.5° ~ 22.5°)
      '북동풍', // 45° (22.5° ~ 67.5°)
      '동풍', // 90° (67.5° ~ 112.5°)
      '남동풍', // 135° (112.5° ~ 157.5°)
      '남풍', // 180° (157.5° ~ 202.5°)
      '남서풍', // 225° (202.5° ~ 247.5°)
      '서풍', // 270° (247.5° ~ 292.5°)
      '북서풍' // 315° (292.5° ~ 337.5°)
    ];
    int index = ((direction + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// 풍속 강도 설명
  static String getWindStrengthDescription(int windSpeed) {
    if (windSpeed == 0) return '무풍';
    if (windSpeed <= 3) return '약한 바람';
    if (windSpeed <= 7) return '보통 바람';
    if (windSpeed <= 13) return '강한 바람';
    if (windSpeed <= 18) return '매우 강한 바람';
    return '폭풍';
  }

  /// 풍향/풍속 정보 요약
  static void printWindSummary(String directionText, int windSpeed, int arrowRotation) {
    AppLogger.d('📊 바람 정보 (8방위):');
    AppLogger.d('  • 풍향: $directionText');
    AppLogger.d('  • 풍속: $windSpeed m/s (${getWindStrengthDescription(windSpeed)})');
    AppLogger.d('  • 화살표 회전: $arrowRotation°');
  }

  /// 8방위 각도 범위 안내
  static void print8DirectionRanges() {
    AppLogger.d('📐 8방위 각도 범위:');
    AppLogger.d('  • 북풍: 337.5° ~ 22.5° (0°)');
    AppLogger.d('  • 북동풍: 22.5° ~ 67.5° (45°)');
    AppLogger.d('  • 동풍: 67.5° ~ 112.5° (90°)');
    AppLogger.d('  • 남동풍: 112.5° ~ 157.5° (135°)');
    AppLogger.d('  • 남풍: 157.5° ~ 202.5° (180°)');
    AppLogger.d('  • 남서풍: 202.5° ~ 247.5° (225°)');
    AppLogger.d('  • 서풍: 247.5° ~ 292.5° (270°)');
    AppLogger.d('  • 북서풍: 292.5° ~ 337.5° (315°)');
  }
}
