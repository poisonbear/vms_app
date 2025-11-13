// lib/core/constants/ship_type_constants.dart

/// AIS 선박 타입 코드 상수
///
/// 국제해사기구(IMO) ITU-R M.1371 표준에 따른 AIS 선박 분류 코드
///
/// 사용 예시:
/// ```dart
/// String typeName = ShipTypeConstants.getKoreanName('52');  // "예인선"
/// String fullName = ShipTypeConstants.getFullName('52');    // "52(예인선)"
/// ```
class ShipType {
  ShipType._(); // Private 생성자

  // ==========================================
  // 선박 타입 코드 - 영문명 매핑
  // ==========================================
  static const Map<String, String> _englishNames = {
    '0': 'Not available',

    // Wing in Ground (20-29)
    '20': 'Wing in Ground (WIG)',
    '21': 'WIG, Hazardous category A',
    '22': 'WIG, Hazardous category B',
    '23': 'WIG, Hazardous category C',
    '24': 'WIG, Hazardous category D',

    // Special Category (30-39)
    '30': 'Fishing',
    '31': 'Towing',
    '32': 'Towing (large)',
    '33': 'Dredging or underwater ops',
    '34': 'Diving ops',
    '35': 'Military ops',
    '36': 'Sailing',
    '37': 'Pleasure Craft',

    // High Speed Craft (40-49)
    '40': 'High speed craft (HSC)',
    '41': 'HSC, Hazardous category A',
    '42': 'HSC, Hazardous category B',
    '43': 'HSC, Hazardous category C',
    '44': 'HSC, Hazardous category D',
    '49': 'HSC, No additional information',

    // Pilot and Special Vessels (50-59)
    '50': 'Pilot Vessel',
    '51': 'Search and Rescue vessel',
    '52': 'Tug',
    '53': 'Port Tender',
    '54': 'Anti-pollution equipment',
    '55': 'Law Enforcement',
    '56': 'Spare - Local Vessel',
    '57': 'Spare - Local Vessel',
    '58': 'Medical Transport',
    '59': 'Noncombatant ship',

    // Passenger (60-69)
    '60': 'Passenger',
    '61': 'Passenger, Hazardous category A',
    '62': 'Passenger, Hazardous category B',
    '63': 'Passenger, Hazardous category C',
    '64': 'Passenger, Hazardous category D',
    '69': 'Passenger, No additional information',

    // Cargo (70-79)
    '70': 'Cargo',
    '71': 'Cargo, Hazardous category A',
    '72': 'Cargo, Hazardous category B',
    '73': 'Cargo, Hazardous category C',
    '74': 'Cargo, Hazardous category D',
    '79': 'Cargo, No additional information',

    // Tanker (80-89)
    '80': 'Tanker',
    '81': 'Tanker, Hazardous category A',
    '82': 'Tanker, Hazardous category B',
    '83': 'Tanker, Hazardous category C',
    '84': 'Tanker, Hazardous category D',
    '89': 'Tanker, No additional information',

    // Other (90-99)
    '90': 'Other Type',
    '91': 'Other Type, Hazardous category A',
    '92': 'Other Type, Hazardous category B',
    '93': 'Other Type, Hazardous category C',
    '94': 'Other Type, Hazardous category D',
    '99': 'Other Type, no additional information',
  };

  // ==========================================
  // 선박 타입 코드 - 한글명 매핑
  // ==========================================
  static const Map<String, String> _koreanNames = {
    '0': '정보 없음',

    // Wing in Ground (20-29)
    '20': '위그선',
    '21': '위그선(위험A)',
    '22': '위그선(위험B)',
    '23': '위그선(위험C)',
    '24': '위그선(위험D)',

    // Special Category (30-39)
    '30': '어선',
    '31': '예인선',
    '32': '대형예인선',
    '33': '준설선',
    '34': '잠수작업선',
    '35': '군용선',
    '36': '범선',
    '37': '요트',

    // High Speed Craft (40-49)
    '40': '고속선',
    '41': '고속선(위험A)',
    '42': '고속선(위험B)',
    '43': '고속선(위험C)',
    '44': '고속선(위험D)',
    '49': '고속선(기타)',

    // Pilot and Special Vessels (50-59)
    '50': '도선선',
    '51': '수색구조선',
    '52': '예인선',
    '53': '항만작업선',
    '54': '방제선',
    '55': '단속선',
    '56': '지역선박',
    '57': '지역선박',
    '58': '의료수송선',
    '59': '비전투함',

    // Passenger (60-69)
    '60': '여객선',
    '61': '여객선(위험A)',
    '62': '여객선(위험B)',
    '63': '여객선(위험C)',
    '64': '여객선(위험D)',
    '69': '여객선(기타)',

    // Cargo (70-79)
    '70': '화물선',
    '71': '화물선(위험A)',
    '72': '화물선(위험B)',
    '73': '화물선(위험C)',
    '74': '화물선(위험D)',
    '79': '화물선(기타)',

    // Tanker (80-89)
    '80': '유조선',
    '81': '유조선(위험A)',
    '82': '유조선(위험B)',
    '83': '유조선(위험C)',
    '84': '유조선(위험D)',
    '89': '유조선(기타)',

    // Other (90-99)
    '90': '기타선박',
    '91': '기타선박(위험A)',
    '92': '기타선박(위험B)',
    '93': '기타선박(위험C)',
    '94': '기타선박(위험D)',
    '99': '기타선박',
  };

  // ==========================================
  // 헬퍼 메서드
  // ==========================================

  /// 선박 타입 코드로 영문명 가져오기
  ///
  /// [code]: 선박 타입 코드 (String 또는 int)
  /// 반환: 영문 선박 타입명, 없으면 'Unknown'
  static String getEnglishName(dynamic code) {
    if (code == null) return 'Unknown';
    final codeStr = code.toString();
    return _englishNames[codeStr] ?? 'Unknown (Code: $codeStr)';
  }

  /// 선박 타입 코드로 한글명 가져오기
  ///
  /// [code]: 선박 타입 코드 (String 또는 int)
  /// 반환: 한글 선박 타입명, 없으면 '알 수 없음'
  static String getKoreanName(dynamic code) {
    if (code == null) return '알 수 없음';
    final codeStr = code.toString();
    return _koreanNames[codeStr] ?? '알 수 없음 ($codeStr)';
  }

  /// 선박 타입 코드로 전체 이름 가져오기 (코드 + 한글명)
  ///
  /// [code]: 선박 타입 코드 (String 또는 int)
  /// 반환: "52(예인선)" 형식, 없으면 코드만 또는 '-'
  static String getFullName(dynamic code) {
    if (code == null) return '-';
    final codeStr = code.toString();
    final koreanName = _koreanNames[codeStr];

    if (koreanName != null) {
      return '$codeStr($koreanName)';
    }

    return codeStr;
  }

  /// 선박 타입 코드 유효성 검사
  ///
  /// [code]: 검사할 선박 타입 코드
  /// 반환: 유효하면 true, 아니면 false
  static bool isValidCode(dynamic code) {
    if (code == null) return false;
    final codeStr = code.toString();
    return _koreanNames.containsKey(codeStr);
  }

  /// 모든 선박 타입 코드 목록 가져오기
  static List<String> getAllCodes() {
    return _koreanNames.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  }

  /// 카테고리별 선박 타입 그룹
  static const Map<String, List<String>> categories = {
    'WIG': ['20', '21', '22', '23', '24'],
    '특수선박': ['30', '31', '32', '33', '34', '35', '36', '37'],
    '고속선': ['40', '41', '42', '43', '44', '49'],
    '특수작업선': ['50', '51', '52', '53', '54', '55', '56', '57', '58', '59'],
    '여객선': ['60', '61', '62', '63', '64', '69'],
    '화물선': ['70', '71', '72', '73', '74', '79'],
    '유조선': ['80', '81', '82', '83', '84', '89'],
    '기타': ['90', '91', '92', '93', '94', '99'],
  };

  /// 선박 타입 코드로 카테고리 가져오기
  static String getCategory(dynamic code) {
    if (code == null) return '알 수 없음';
    final codeStr = code.toString();

    for (final entry in categories.entries) {
      if (entry.value.contains(codeStr)) {
        return entry.key;
      }
    }

    return '알 수 없음';
  }
}

// ==========================================
// 사용 예시 (주석)
// ==========================================
/*
void main() {
  // 예시 1: 한글명 가져오기
  print(ShipTypeConstants.getKoreanName('52'));  // "예인선"

  // 예시 2: 전체 이름 가져오기
  print(ShipTypeConstants.getFullName('52'));    // "52(예인선)"

  // 예시 3: 영문명 가져오기
  print(ShipTypeConstants.getEnglishName('52')); // "Tug"

  // 예시 4: 유효성 검사
  print(ShipTypeConstants.isValidCode('52'));    // true
  print(ShipTypeConstants.isValidCode('999'));   // false

  // 예시 5: 카테고리 가져오기
  print(ShipTypeConstants.getCategory('52'));    // "특수작업선"

  // 예시 6: int 타입으로도 사용 가능
  print(ShipTypeConstants.getKoreanName(52));    // "예인선"
}
*/
