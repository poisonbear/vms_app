import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';

/// 항행 경보 알림 배너
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
        final warnings = navProvider.navigationWarnings;
        if (warnings.isEmpty) return const SizedBox.shrink();

        return Container(
          height: AppSizes.s40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(AppSizes.s8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Marquee(
            text: warnings
                .where((text) => text.trim().isNotEmpty)
                .join('    ★    '),
            style: const TextStyle(
              fontSize: AppSizes.s14,
              fontWeight: FontWeights.w500,
              color: AppColors.blackType2,
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
          ),
        );
      },
    );
  }
}