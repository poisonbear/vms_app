import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 선박 다이얼로그 액션 버튼들
class VesselDialogActions extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onTracking;

  const VesselDialogActions({
    super.key,
    required this.onClose,
    required this.onTracking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSizes.s20),
          bottomRight: Radius.circular(AppSizes.s20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black05,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: '닫기',
              onTap: onClose,
              backgroundColor: AppColors.grayType10,
              textColor: AppColors.grayType3,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: _ActionButton(
              label: '항적 보기',
              onTap: onTracking,
              backgroundColor: AppColors.blueNavy, // 변경: 하드코딩 → 상수 사용
              textColor: AppColors.whiteType1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizes.s48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.s8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.s15,
              fontWeight: FontWeights.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
