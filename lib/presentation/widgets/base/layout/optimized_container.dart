import 'package:flutter/material.dart';

/// 복잡한 위젯 트리에서 불필요한 리페인트를 방지
/// 애니메이션이나 자주 업데이트되는 위젯을 감쌀 때 유용
class OptimizedContainer extends StatelessWidget {
  final Widget child;
  final bool useRepaintBoundary;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  const OptimizedContainer({
    super.key,
    required this.child,
    this.useRepaintBoundary = true,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
    this.width,
    this.height,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment,
      constraints: constraints,
      child: child,
    );

    if (useRepaintBoundary) {
      return RepaintBoundary(child: result);
    }
    return result;
  }
}

/// 성능 최적화를 위한 리스트 아이템 컨테이너
///
/// ListView나 GridView에서 각 아이템을 감싸는 용도
class OptimizedListItem extends StatelessWidget {
  final Widget child;
  final Key? itemKey;
  final bool useRepaintBoundary;
  final bool addAutomaticKeepAlive;

  const OptimizedListItem({
    super.key,
    required this.child,
    this.itemKey,
    this.useRepaintBoundary = true,
    this.addAutomaticKeepAlive = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget item = KeyedSubtree(
      key: itemKey,
      child: child,
    );

    if (useRepaintBoundary) {
      item = RepaintBoundary(child: item);
    }

    if (addAutomaticKeepAlive) {
      item = AutomaticKeepAlive(
        child: item,
      );
    }

    return item;
  }
}

/// 애니메이션 최적화 컨테이너
///
/// 애니메이션 위젯을 감싸서 성능 최적화
class AnimatedOptimizedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;

  const AnimatedOptimizedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOut,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: decoration,
        alignment: alignment,
        child: child,
      ),
    );
  }
}

/// AutomaticKeepAlive 래퍼
///
/// 스크롤 시 위젯 상태를 유지
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({
    super.key,
    required this.child,
  });

  @override
  _KeepAliveWrapperState createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
