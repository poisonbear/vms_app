// lib/presentation/widgets/features/notification/navigation_warning_banner.dart

import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';

/// 항행 경보 알림 배너 (강조된 디자인)
class NavigationWarningBanner extends StatelessWidget {
  final bool isVisible;

  const NavigationWarningBanner({
    super.key,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        final warningText = navProvider.combinedNavigationWarnings;
        final hasWarning = navProvider.navigationWarnings.isNotEmpty;

        return Container(
          height: AppSizes.s44,
          width: double.infinity,
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            // 경보 있으면 진한 빨강, 없으면 연한 빨강
            color:
                hasWarning ? const Color(0xFFD32F2F) : const Color(0xFFE57373),
            // 상단에 그림자
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 경고 아이콘
              if (hasWarning)
                const Padding(
                  padding:
                      EdgeInsets.only(left: AppSizes.s12, right: AppSizes.s8),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

              // 텍스트
              Expanded(
                child: warningText.length > 50
                    ? Marquee(
                        text: warningText,
                        style: const TextStyle(
                          fontSize: AppSizes.s14,
                          fontWeight: FontWeights.w600,
                          color: Colors.white,
                          height: 1.0,
                        ),
                        scrollAxis: Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        blankSpace: 100.0,
                        velocity: 30.0,
                        pauseAfterRound: const Duration(seconds: 2),
                        startPadding: 10.0,
                        accelerationDuration: const Duration(seconds: 1),
                        accelerationCurve: Curves.linear,
                        decelerationDuration: const Duration(milliseconds: 500),
                        decelerationCurve: Curves.easeOut,
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: hasWarning ? AppSizes.s8 : AppSizes.s16,
                        ),
                        child: Text(
                          warningText,
                          style: const TextStyle(
                            fontSize: AppSizes.s14,
                            fontWeight: FontWeights.w600,
                            color: Colors.white,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),

              // 오른쪽 여백 (아이콘과 균형)
              if (hasWarning) const SizedBox(width: AppSizes.s44),
            ],
          ),
        );
      },
    );
  }
}
