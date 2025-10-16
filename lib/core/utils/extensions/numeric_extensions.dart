// lib/core/utils/extensions/numeric_extensions.dart

/// int 확장
extension IntExtension on int {
  /// 범위 내 값인지 확인
  bool isBetween(int min, int max) {
    return this >= min && this <= max;
  }

  /// 짝수인지 확인
  bool get isEven => this % 2 == 0;

  /// 홀수인지 확인
  bool get isOdd => this % 2 != 0;

  /// 천 단위 구분 문자열
  String get toFormattedString {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// 파일 크기 문자열
  String toFileSizeString() {
    if (this < 1024) {
      return '$this B';
    } else if (this < 1024 * 1024) {
      return '${(this / 1024).toStringAsFixed(1)} KB';
    } else if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

/// double 확장
extension DoubleExtension on double {
  /// 소수점 자릿수 제한
  double toPrecision(int fractionDigits) {
    return double.parse(toStringAsFixed(fractionDigits));
  }

  /// 퍼센트 문자열
  String toPercentString({int fractionDigits = 0}) {
    return '${(this * 100).toStringAsFixed(fractionDigits)}%';
  }

  /// 통화 문자열
  String toCurrencyString({String symbol = '₩'}) {
    return '$symbol${toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}
