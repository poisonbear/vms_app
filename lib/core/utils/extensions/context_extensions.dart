// lib/core/utils/extensions/context_extensions.dart

import 'package:flutter/material.dart';

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
  void showSnackBar(String message,
      {Duration? duration, SnackBarAction? action}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
        action: action,
      ),
    );
  }

  /// Dialog 표시
  Future<T?> showCustomDialog<T>({
    required Widget dialog,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    RouteSettings? routeSettings,
  }) {
    return showDialog<T>(
      context: this,
      builder: (context) => dialog,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      routeSettings: routeSettings,
    );
  }

  /// BottomSheet 표시
  Future<T?> showCustomBottomSheet<T>({
    required WidgetBuilder builder,
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
