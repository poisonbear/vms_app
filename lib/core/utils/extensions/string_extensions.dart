// lib/core/utils/extensions/string_extensions.dart

/// String 확장
extension StringExtension on String {
  /// 빈 문자열 확인
  bool get isBlank => trim().isEmpty;

  /// null이거나 빈 문자열 확인
  bool get isNullOrBlank => trim().isEmpty;

  /// 첫 글자 대문자
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// 모든 단어 첫 글자 대문자
  String get capitalizeWords {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// 이메일 유효성
  bool get isEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  /// URL 유효성
  bool get isUrl {
    return Uri.tryParse(this) != null;
  }

  /// 숫자인지 확인
  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  /// 전화번호 형식인지 확인
  bool get isPhoneNumber {
    return RegExp(r'^[0-9\-\+\(\)\s]+$').hasMatch(this);
  }

  /// 빈 문자열일 경우 기본값 반환
  String ifEmpty(String defaultValue) {
    return isEmpty ? defaultValue : this;
  }
}
