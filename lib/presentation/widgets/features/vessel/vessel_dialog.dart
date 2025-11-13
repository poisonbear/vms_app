// lib/presentation/widgets/features/vessel/vessel_dialog.dart

import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'vessel_info_card.dart';
import 'vessel_dialog_actions.dart';

/// 선박 정보 다이얼로그
class VesselDialog extends StatelessWidget {
  final VesselSearchModel vessel;
  final VoidCallback onTrackingRequested;

  const VesselDialog({
    super.key,
    required this.vessel,
    required this.onTrackingRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.s20),
      ),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.s20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VesselDialogHeader(vesselName: vessel.ship_nm ?? '선박명 없음'),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.s20),
                child: _buildContent(),
              ),
            ),
            VesselDialogActions(
              onClose: () => Navigator.of(context).pop(),
              onTracking: onTrackingRequested,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // MMSI - 복사 가능
        VesselInfoCard(
          icon: Icons.confirmation_number,
          label: 'MMSI',
          value: vessel.mmsi?.toString() ?? '-',
          enableCopy: true, // 복사 기능 활성화
        ),
        const SizedBox(height: AppSizes.s12),

        // 현재 위치 - 복사 가능
        VesselInfoCard(
          icon: Icons.location_on,
          label: '현재 위치',
          value: '${vessel.lttd?.toStringAsFixed(6) ?? '-'}\n'
              '${vessel.lntd?.toStringAsFixed(6) ?? '-'}',
          enableCopy: true, // 복사 기능 활성화
        ),
        const SizedBox(height: AppSizes.s12),

        Row(
          children: [
            Expanded(
              child: VesselInfoCard(
                icon: Icons.speed,
                label: '속도',
                value: vessel.sog != null
                    ? '${vessel.sog!.toStringAsFixed(1)} kn'
                    : '-',
                isCompact: true,
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            Expanded(
              child: VesselInfoCard(
                icon: Icons.explore,
                label: '침로',
                value: vessel.cog != null
                    ? '${vessel.cog!.toStringAsFixed(1)}°'
                    : '-',
                isCompact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s12),

        Row(
          children: [
            Expanded(
              child: VesselInfoCard(
                icon: Icons.category,
                label: '선종',
                value: _formatShipType(vessel),
                isCompact: true,
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            Expanded(
              child: VesselInfoCard(
                icon: Icons.waves,
                label: '흘수',
                value: vessel.draft != null
                    ? '${vessel.draft!.toStringAsFixed(1)} m'
                    : '-',
                isCompact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatShipType(VesselSearchModel vessel) {
    final shipCode = vessel.shiptype ?? vessel.ship_knd ?? vessel.ship_kdn;

    if (shipCode != null && shipCode.isNotEmpty) {
      final koreanName = ShipType.getKoreanName(shipCode);

      if (koreanName != '알 수 없음' && !koreanName.startsWith('알 수 없음')) {
        return '$shipCode($koreanName)';
      }

      if (vessel.shiptype_nm?.isNotEmpty == true) {
        return '$shipCode(${vessel.shiptype_nm})';
      }

      return shipCode;
    }

    return vessel.shiptype_nm ?? '-';
  }
}

class _VesselDialogHeader extends StatelessWidget {
  final String vesselName;

  const _VesselDialogHeader({required this.vesselName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.s50,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
      decoration: const BoxDecoration(
        color: AppColors.blueNavy,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.s20),
          topRight: Radius.circular(AppSizes.s20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_boat,
            color: AppColors.whiteType1,
            size: AppSizes.s24,
          ),
          const SizedBox(width: AppSizes.s8),
          Expanded(
            child: Text(
              vesselName,
              style: const TextStyle(
                fontSize: AppSizes.s16,
                fontWeight: FontWeights.w700,
                color: AppColors.whiteType1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.s4),
              child: const Icon(
                Icons.close,
                color: AppColors.whiteType1,
                size: AppSizes.s24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
