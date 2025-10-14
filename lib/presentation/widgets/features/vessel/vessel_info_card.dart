import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 선박 정보 카드 위젯
class VesselInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isCompact;

  const VesselInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? AppSizes.s12 : AppSizes.s16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(AppSizes.s12),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.s8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.s8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1E3A5F),
              size: isCompact ? AppSizes.s18 : AppSizes.s20,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isCompact ? AppSizes.s11 : AppSizes.s12,
                    fontWeight: FontWeights.w500,
                    color: AppColors.grayType3,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isCompact ? AppSizes.s14 : AppSizes.s16,
                    fontWeight: FontWeights.w700,
                    color: AppColors.blackType2,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}