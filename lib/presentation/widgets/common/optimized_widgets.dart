import 'package:flutter/material.dart';

/// 성능 최적화된 공통 위젯들
class OptimizedWidgets {
  OptimizedWidgets._();

  // const 생성자를 활용한 위젯
  static const loadingIndicator = CircularProgressIndicator();
  
  static const defaultPadding = EdgeInsets.all(16.0);
  static const smallPadding = EdgeInsets.all(8.0);
  static const largePadding = EdgeInsets.all(24.0);
  
  // 자주 사용되는 SizedBox를 const로
  static const height4 = SizedBox(height: 4);
  static const height8 = SizedBox(height: 8);
  static const height12 = SizedBox(height: 12);
  static const height16 = SizedBox(height: 16);
  static const height20 = SizedBox(height: 20);
  static const height24 = SizedBox(height: 24);
  
  static const width4 = SizedBox(width: 4);
  static const width8 = SizedBox(width: 8);
  static const width12 = SizedBox(width: 12);
  static const width16 = SizedBox(width: 16);
  static const width20 = SizedBox(width: 20);
  static const width24 = SizedBox(width: 24);
}

/// RepaintBoundary를 활용한 최적화 위젯
class OptimizedContainer extends StatelessWidget {
  final Widget child;
  final bool useRepaintBoundary;

  const OptimizedContainer({
    super.key,
    required this.child,
    this.useRepaintBoundary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useRepaintBoundary) {
      return RepaintBoundary(
        child: child,
      );
    }
    return child;
  }
}

/// 이미지 캐싱 최적화
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // 메모리 캐시 크기 제한
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      // 로딩 중 플레이스홀더
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      // 에러 처리
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.error);
      },
    );
  }
}
