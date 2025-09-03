import 'dart:math';

void testWindIconRotation() {
  print('\n🎯 === 풍향 아이콘 회전 검증 ===\n');
  
  // 실제 API 데이터 시뮬레이션
  final testData = [
    {'desc': '북풍 (위→아래)', 'u': 0.0, 'v': -5.0},
    {'desc': '동풍 (오른쪽→왼쪽)', 'u': -5.0, 'v': 0.0},
    {'desc': '남풍 (아래→위)', 'u': 0.0, 'v': 5.0},
    {'desc': '서풍 (왼쪽→오른쪽)', 'u': 5.0, 'v': 0.0},
    {'desc': '북동풍', 'u': -3.5, 'v': -3.5},
    {'desc': '남서풍', 'u': 3.5, 'v': 3.5},
  ];
  
  for (final data in testData) {
    final u = data['u'] as double;
    final v = data['v'] as double;
    final desc = data['desc'] as String;
    
    // 풍향 계산
    double windDirectionRad = atan2(-u, -v);
    double windDirectionDegrees = windDirectionRad * 180 / pi;
    if (windDirectionDegrees < 0) windDirectionDegrees += 360;
    int windDirection = windDirectionDegrees.round() % 360;
    
    // 화살표 회전
    int arrowRotation = (windDirection + 180) % 360;
    int rounded = ((arrowRotation / 5).round() * 5) % 360;
    
    print('$desc:');
    print('  U=$u, V=$v');
    print('  풍향: $windDirection°');
    print('  화살표: $arrowRotation° → $rounded° (5도 단위 반올림)');
    print('  아이콘: ro$rounded');
    print('');
  }
  
  print('💡 설명:');
  print('  • 기본 아이콘(ro0)은 위쪽을 가리킴');
  print('  • 북풍일 때 화살표는 아래쪽(180°)을 가리켜야 함');
  print('  • 5도 단위 반올림으로 부드러운 회전 표현');
  print('\n🎯 ========================\n');
}

// main 함수에서 테스트 실행
void main() {
  testWindIconRotation();
}
