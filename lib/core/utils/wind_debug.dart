import 'dart:math';
import 'package:flutter/foundation.dart';

/// 풍향 계산 디버깅 유틸리티
class WindDebugUtils {
  /// 풍향 계산 테스트
  static void testWindCalculation() {
    debugPrint('🌪️ === 풍향 계산 테스트 시작 ===');
    
    // 테스트 케이스들
    final testCases = [
      {'name': '북풍', 'u': 0.0, 'v': -5.0, 'expected': 0},    // 북쪽에서 남쪽으로
      {'name': '동풍', 'u': -5.0, 'v': 0.0, 'expected': 90},   // 동쪽에서 서쪽으로  
      {'name': '남풍', 'u': 0.0, 'v': 5.0, 'expected': 180},   // 남쪽에서 북쪽으로
      {'name': '서풍', 'u': 5.0, 'v': 0.0, 'expected': 270},   // 서쪽에서 동쪽으로
      {'name': '북동풍', 'u': -3.5, 'v': -3.5, 'expected': 45}, // 북동쪽에서
      {'name': '무풍', 'u': 0.0, 'v': 0.0, 'expected': 0},     // 바람 없음
    ];
    
    for (final test in testCases) {
      final u = test['u'] as double;
      final v = test['v'] as double;
      final expected = test['expected'] as int;
      final name = test['name'] as String;
      
      // 풍향 계산
      double windDirectionRad = atan2(-u, -v);
      double windDirectionDegrees = windDirectionRad * 180 / pi;
      if (windDirectionDegrees < 0) windDirectionDegrees += 360;
      int calculated = windDirectionDegrees.round() % 360;
      
      final windSpeed = sqrt(u * u + v * v);
      
      debugPrint('$name: U=$u, V=$v → $calculated° (예상: $expected°) 속도: ${windSpeed.toStringAsFixed(1)}');
    }
    
    debugPrint('🌪️ === 풍향 계산 테스트 완료 ===');
  }
  
  /// 방위각을 방위명으로 변환
  static String directionToText(int direction) {
    const directions = ['북', '북북동', '북동', '동북동', '동', '동남동', '남동', '남남동', 
                       '남', '남남서', '남서', '서남서', '서', '서북서', '북서', '북북서'];
    int index = ((direction + 11.25) / 22.5).floor() % 16;
    return '${directions[index]}풍';
  }
}
