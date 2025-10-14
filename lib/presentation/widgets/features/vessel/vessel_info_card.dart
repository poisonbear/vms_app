// lib/presentation/widgets/features/vessel/vessel_info_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 선박 정보 카드 위젯
class VesselInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isCompact;
  final bool enableCopy;  // 복사 기능 활성화

  const VesselInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isCompact = false,
    this.enableCopy = false,  // 기본값: 비활성화
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? AppSizes.s12 : AppSizes.s16),
      decoration: BoxDecoration(
        color: AppColors.grayType15,
        borderRadius: BorderRadius.circular(AppSizes.s12),
        border: Border.all(
          color: AppColors.grayType16,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.s8),
            decoration: BoxDecoration(
              color: AppColors.blueNavy.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.s8),
            ),
            child: Icon(
              icon,
              color: AppColors.blueNavy,
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
          // 🆕 복사 버튼
          if (enableCopy) ...[
            const SizedBox(width: AppSizes.s8),
            InkWell(
              onTap: () => _copyToClipboard(context),
              borderRadius: BorderRadius.circular(AppSizes.s6),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.s6),
                child: Icon(
                  Icons.content_copy,
                  size: isCompact ? AppSizes.s16 : AppSizes.s18,
                  color: AppColors.grayType6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 클립보드에 복사
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();  // 햅틱 피드백

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label이(가) 복사되었습니다'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}