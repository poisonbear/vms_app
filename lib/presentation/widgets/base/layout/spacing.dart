import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 간격 및 패딩 상수
/// const 위젯으로 성능 최적화
class Spacing {
  Spacing._();

  // ========================================
  // Vertical Spacing (높이)
  // ========================================
  static const Widget v4 = SizedBox(height: 4);
  static const Widget v8 = SizedBox(height: 8);
  static const Widget v12 = SizedBox(height: 12);
  static const Widget v16 = SizedBox(height: 16);
  static const Widget v20 = SizedBox(height: 20);
  static const Widget v24 = SizedBox(height: 24);
  static const Widget v28 = SizedBox(height: 28);
  static const Widget v32 = SizedBox(height: 32);
  static const Widget v40 = SizedBox(height: 40);
  static const Widget v48 = SizedBox(height: 48);
  static const Widget v56 = SizedBox(height: 56);
  static const Widget v64 = SizedBox(height: 64);

  // ========================================
  // Horizontal Spacing (너비)
  // ========================================
  static const Widget h4 = SizedBox(width: 4);
  static const Widget h8 = SizedBox(width: 8);
  static const Widget h12 = SizedBox(width: 12);
  static const Widget h16 = SizedBox(width: 16);
  static const Widget h20 = SizedBox(width: 20);
  static const Widget h24 = SizedBox(width: 24);
  static const Widget h28 = SizedBox(width: 28);
  static const Widget h32 = SizedBox(width: 32);
  static const Widget h40 = SizedBox(width: 40);
  static const Widget h48 = SizedBox(width: 48);
  static const Widget h56 = SizedBox(width: 56);
  static const Widget h64 = SizedBox(width: 64);

  // ========================================
  // Legacy Support (기존 코드 호환)
  // ========================================
  @Deprecated('Use Spacing.v4 instead')
  static const Widget height4 = v4;
  @Deprecated('Use Spacing.v8 instead')
  static const Widget height8 = v8;
  @Deprecated('Use Spacing.v12 instead')
  static const Widget height12 = v12;
  @Deprecated('Use Spacing.v16 instead')
  static const Widget height16 = v16;
  @Deprecated('Use Spacing.v20 instead')
  static const Widget height20 = v20;
  @Deprecated('Use Spacing.v24 instead')
  static const Widget height24 = v24;

  @Deprecated('Use Spacing.h4 instead')
  static const Widget width4 = h4;
  @Deprecated('Use Spacing.h8 instead')
  static const Widget width8 = h8;
  @Deprecated('Use Spacing.h12 instead')
  static const Widget width12 = h12;
  @Deprecated('Use Spacing.h16 instead')
  static const Widget width16 = h16;
  @Deprecated('Use Spacing.h20 instead')
  static const Widget width20 = h20;
  @Deprecated('Use Spacing.h24 instead')
  static const Widget width24 = h24;
}

/// 패딩 상수
class Paddings {
  Paddings._();

  // ========================================
  // All Padding
  // ========================================
  static const EdgeInsets all4 = EdgeInsets.all(4.0);
  static const EdgeInsets all8 = EdgeInsets.all(8.0);
  static const EdgeInsets all12 = EdgeInsets.all(12.0);
  static const EdgeInsets all16 = EdgeInsets.all(16.0);
  static const EdgeInsets all20 = EdgeInsets.all(20.0);
  static const EdgeInsets all24 = EdgeInsets.all(24.0);
  static const EdgeInsets all32 = EdgeInsets.all(32.0);

  // ========================================
  // Horizontal Padding
  // ========================================
  static const EdgeInsets horizontal4 = EdgeInsets.symmetric(horizontal: 4.0);
  static const EdgeInsets horizontal8 = EdgeInsets.symmetric(horizontal: 8.0);
  static const EdgeInsets horizontal12 = EdgeInsets.symmetric(horizontal: 12.0);
  static const EdgeInsets horizontal16 = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets horizontal20 = EdgeInsets.symmetric(horizontal: 20.0);
  static const EdgeInsets horizontal24 = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets horizontal32 = EdgeInsets.symmetric(horizontal: 32.0);

  // ========================================
  // Vertical Padding
  // ========================================
  static const EdgeInsets vertical4 = EdgeInsets.symmetric(vertical: 4.0);
  static const EdgeInsets vertical8 = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets vertical12 = EdgeInsets.symmetric(vertical: 12.0);
  static const EdgeInsets vertical16 = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets vertical20 = EdgeInsets.symmetric(vertical: 20.0);
  static const EdgeInsets vertical24 = EdgeInsets.symmetric(vertical: 24.0);
  static const EdgeInsets vertical32 = EdgeInsets.symmetric(vertical: 32.0);

  // ========================================
  // Common Patterns
  // ========================================
  static const EdgeInsets pagePadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );

  // ========================================
  // Legacy Support (기존 코드 호환)
  // ========================================
  @Deprecated('Use Paddings.all16 instead')
  static const EdgeInsets defaultPadding = all16;
  @Deprecated('Use Paddings.all8 instead')
  static const EdgeInsets smallPadding = all8;
  @Deprecated('Use Paddings.all24 instead')
  static const EdgeInsets largePadding = all24;
}

/// OptimizedWidgets 호환성 (기존 코드를 위한 별칭)
@Deprecated('Use Spacing class instead')
class OptimizedWidgets {
  OptimizedWidgets._();

  // Loading
  static const Widget loadingIndicator = CircularProgressIndicator();

  // Padding - Paddings 클래스로 리다이렉트
  static const EdgeInsets defaultPadding = Paddings.defaultPadding;
  static const EdgeInsets smallPadding = Paddings.smallPadding;
  static const EdgeInsets largePadding = Paddings.largePadding;

  // Spacing - Spacing 클래스로 리다이렉트
  static const Widget height4 = Spacing.height4;
  static const Widget height8 = Spacing.height8;
  static const Widget height12 = Spacing.height12;
  static const Widget height16 = Spacing.height16;
  static const Widget height20 = Spacing.height20;
  static const Widget height24 = Spacing.height24;

  static const Widget width4 = Spacing.width4;
  static const Widget width8 = Spacing.width8;
  static const Widget width12 = Spacing.width12;
  static const Widget width16 = Spacing.width16;
  static const Widget width20 = Spacing.width20;
  static const Widget width24 = Spacing.width24;
}
