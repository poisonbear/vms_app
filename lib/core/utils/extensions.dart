import 'package:flutter/material.dart';
import 'dart:async';  // ✅ Timer 사용을 위해 추가

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
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(this);
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

/// DateTime 확장
extension DateTimeExtension on DateTime {
  /// 오늘인지 확인
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// 어제인지 확인
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// 이번 주인지 확인
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// 날짜만 비교
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// 시작 시간 (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// 종료 시간 (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }

  /// 포맷된 날짜 문자열
  String toDateString() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  /// 포맷된 시간 문자열
  String toTimeString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

/// List 확장
extension ListExtension<T> on List<T> {
  /// 안전한 인덱스 접근
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// 첫 번째 요소 또는 null
  T? get firstOrNull => isEmpty ? null : first;

  /// 마지막 요소 또는 null
  T? get lastOrNull => isEmpty ? null : last;

  /// 중복 제거
  List<T> get distinct => toSet().toList();

  /// 조건에 맞는 첫 번째 요소 또는 null
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }

  /// 리스트를 청크로 나누기
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
}

/// Map 확장
extension MapExtension<K, V> on Map<K, V> {
  /// 안전한 값 가져오기
  T? getAs<T>(K key) {
    final value = this[key];
    return value is T ? value : null;
  }

  /// 여러 키 제거
  void removeKeys(Iterable<K> keys) {
    for (final key in keys) {
      remove(key);
    }
  }

  /// 조건부 추가
  void addIf(bool condition, K key, V value) {
    if (condition) {
      this[key] = value;
    }
  }

  /// null이 아닌 값만 추가
  void addIfNotNull(K key, V? value) {
    if (value != null) {
      this[key] = value;
    }
  }

  /// 깊은 복사
  Map<K, V> deepCopy() {
    return Map<K, V>.from(this);
  }
}

/// BuildContext 확장
extension BuildContextExtension on BuildContext {
  /// Theme 접근
  ThemeData get theme => Theme.of(this);

  /// TextTheme 접근
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// ColorScheme 접근
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// MediaQuery 접근
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// 화면 크기
  Size get screenSize => MediaQuery.of(this).size;

  /// 화면 너비
  double get screenWidth => MediaQuery.of(this).size.width;

  /// 화면 높이
  double get screenHeight => MediaQuery.of(this).size.height;

  /// 키보드 높이
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;

  /// 키보드 표시 여부
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Navigator 접근
  NavigatorState get navigator => Navigator.of(this);

  /// SnackBar 표시
  void showSnackBar(String message, {Duration? duration, SnackBarAction? action}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
        action: action,
      ),
    );
  }

  /// ✅ Dialog 표시 - 메서드 이름 변경 (showDialog → showCustomDialog)
  Future<T?> showCustomDialog<T>({
    required Widget dialog,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    RouteSettings? routeSettings,
  }) {
    // Flutter의 showDialog 함수를 명시적으로 호출
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      routeSettings: routeSettings,
      builder: (_) => dialog,
    );
  }

  /// BottomSheet 표시
  Future<T?> showBottomSheet<T>({
    required Widget Function(BuildContext) builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      builder: builder,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
    );
  }

  /// 포커스 해제
  void unfocus() {
    FocusScope.of(this).unfocus();
  }

  /// 키보드 숨기기
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// 현재 라우트 이름
  String? get currentRouteName {
    return ModalRoute.of(this)?.settings.name;
  }

  /// 태블릿인지 확인
  bool get isTablet {
    final shortestSide = MediaQuery.of(this).size.shortestSide;
    return shortestSide >= 600;
  }

  /// 가로 모드인지 확인
  bool get isLandscape {
    return MediaQuery.of(this).orientation == Orientation.landscape;
  }

  /// 세로 모드인지 확인
  bool get isPortrait {
    return MediaQuery.of(this).orientation == Orientation.portrait;
  }

  /// Safe Area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// 상태바 높이
  double get statusBarHeight => MediaQuery.of(this).padding.top;

  /// 네비게이션 바 높이
  double get navigationBarHeight => MediaQuery.of(this).padding.bottom;
}

/// Duration 확장
extension DurationExtension on Duration {
  /// 포맷된 시간 문자열 (HH:mm:ss)
  String toTimeString() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = (inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// 포맷된 분:초 문자열 (mm:ss)
  String toMinuteSecondString() {
    final minutes = inMinutes.toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 사람이 읽기 쉬운 형식
  String toReadableString() {
    if (inDays > 0) {
      return '$inDays일';
    } else if (inHours > 0) {
      return '$inHours시간';
    } else if (inMinutes > 0) {
      return '$inMinutes분';
    } else {
      return '$inSeconds초';
    }
  }
}

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

  /// 파일 크기 포맷
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
  /// 소수점 자리수 제한
  double toPrecision(int fractionDigits) {
    final mod = pow(10, fractionDigits).toDouble();
    return ((this * mod).round().toDouble() / mod);
  }

  /// 퍼센트 문자열
  String toPercentString({int fractionDigits = 0}) {
    return '${(this * 100).toStringAsFixed(fractionDigits)}%';
  }

  /// 통화 형식 문자열
  String toCurrencyString({String symbol = '₩'}) {
    return '$symbol${toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    )}';
  }
}

// ✅ pow 함수를 위한 import 추가
num pow(num x, num exponent) {
  num result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= x;
  }
  return result;
}