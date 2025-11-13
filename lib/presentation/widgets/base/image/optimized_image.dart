import 'package:flutter/material.dart';

/// 네트워크 이미지 최적화 위젯
/// 자동 캐싱, 로딩 인디케이터, 에러 핸들링 포함
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showLoadingProgress;
  final int? cacheWidth;
  final int? cacheHeight;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.showLoadingProgress = true,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // 메모리 캐시 크기 제한 - 성능 최적화
      cacheWidth: cacheWidth ?? width?.toInt(),
      cacheHeight: cacheHeight ?? height?.toInt(),
      // 로딩 중 표시
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        if (!showLoadingProgress && placeholder != null) {
          return placeholder!;
        }

        return Center(
          child: showLoadingProgress
              ? CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                )
              : placeholder ?? const CircularProgressIndicator(),
        );
      },
      // 에러 처리
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
            );
      },
    );
  }
}

/// Asset 이미지 최적화 위젯
class OptimizedAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final BlendMode? colorBlendMode;

  const OptimizedAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.color,
    this.colorBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      // 성능 최적화를 위한 캐시 설정
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}

/// 페이드 인 이미지 위젯
///
/// 이미지 로드 시 부드러운 페이드 효과
class FadeInImage extends StatelessWidget {
  final String imageUrl;
  final String? placeholderAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Duration fadeInDuration;

  const FadeInImage({
    super.key,
    required this.imageUrl,
    this.placeholderAsset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    if (placeholderAsset != null) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedSwitcher(
            duration: fadeInDuration,
            child: frame != null
                ? child
                : Image.asset(
                    placeholderAsset!,
                    width: width,
                    height: height,
                    fit: fit,
                  ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            placeholderAsset!,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    } else {
      return OptimizedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
      );
    }
  }
}

/// 원형 이미지 위젯
class CircularImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool isAsset;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CircularImage({
    super.key,
    required this.imageUrl,
    this.size = 50,
    this.isAsset = false,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: isAsset
            ? OptimizedAssetImage(
                assetPath: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : OptimizedNetworkImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: placeholder,
                errorWidget: errorWidget,
              ),
      ),
    );
  }
}
