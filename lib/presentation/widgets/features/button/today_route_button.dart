import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/screens/main/controllers/main_screen_controller.dart';

/// 당일 항적 보기 버튼
class TodayRouteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const TodayRouteButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserState>().role;
    final userMmsi = context.watch<UserState>().mmsi ?? 0;

    // ROLE_USER만 표시
    if (role != 'ROLE_USER' || userMmsi == 0) {
      return const SizedBox.shrink();
    }

    return Consumer<MainScreenController>(
      builder: (context, controller, child) {
        return AnimatedOpacity(
          opacity: controller.isOtherVesselsVisible ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: controller.isOtherVesselsVisible,
            child: GestureDetector(
              onTap: isLoading ? null : onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s20,
                  vertical: AppSizes.s12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.skyType2, AppColors.skyType1],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.s24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/kdn/ros/img/ship_on.svg',
                      width: AppSizes.s20,
                      height: AppSizes.s20,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s8),
                    isLoading
                        ? const SizedBox(
                            width: AppSizes.s16,
                            height: AppSizes.s16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '당일 항적보기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppSizes.s14,
                              fontWeight: FontWeights.w600,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
