// lib/presentation/widgets/features/vessel/vessel_info_widget.dart

import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/vessel_model.dart';

/// 선박 정보 테이블 위젯
class VesselInfoTable extends StatelessWidget {
  final VesselSearchModel? vessel;
  final bool showExtendedInfo;

  const VesselInfoTable({
    super.key,
    this.vessel,
    this.showExtendedInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    if (vessel == null) {
      return const Center(child: Text('선박 정보 없음'));
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.s12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(80),
          1: FlexColumnWidth(),
        },
        children: [
          _buildInfoRow('선박명', vessel!.ship_nm ?? '-'),
          _buildInfoRow('MMSI', vessel!.mmsi?.toString() ?? '-'),
          _buildInfoRow('선종', vessel!.ship_knd ?? '-'),
          if (showExtendedInfo) ...[
            _buildInfoRow(
                '흘수', vessel!.draft != null ? '${vessel!.draft} m' : '-'),
            _buildInfoRow(
                '속력',
                vessel!.sog != null
                    ? '${vessel!.sog!.toStringAsFixed(1)} kn'
                    : '-'),
            _buildInfoRow(
                '침로',
                vessel!.cog != null
                    ? '${vessel!.cog!.toStringAsFixed(1)}°'
                    : '-'),
            _buildInfoRow('위치', _formatPosition()),
          ],
        ],
      ),
    );
  }

  String _formatPosition() {
    if (vessel?.lttd != null && vessel?.lntd != null) {
      return '${vessel!.lttd!.toStringAsFixed(4)}°, ${vessel!.lntd!.toStringAsFixed(4)}°';
    }
    return '-';
  }

  TableRow _buildInfoRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.s8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppSizes.s14,
              fontWeight: FontWeights.w500,
              color: AppColors.grayType6,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.s8),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.s14,
              fontWeight: FontWeights.w600,
              color: AppColors.blackType2,
            ),
          ),
        ),
      ],
    );
  }
}

/// 선박 목록 위젯
/// ✅ 최적화: ListView.builder에 ValueKey 추가
class VesselListWidget extends StatelessWidget {
  final List<VesselSearchModel> vessels;
  final int? selectedMmsi;
  final ValueChanged<VesselSearchModel> onVesselSelected;
  final bool showSearchBar;
  final String? emptyMessage;

  const VesselListWidget({
    super.key,
    required this.vessels,
    this.selectedMmsi,
    required this.onVesselSelected,
    this.showSearchBar = false,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (vessels.isEmpty) {
      return Center(
        child: Text(emptyMessage ?? '등록된 선박이 없습니다.'),
      );
    }

    return Column(
      children: [
        if (showSearchBar) _buildSearchBar(context),
        Expanded(
          child: ListView.builder(
            itemCount: vessels.length,
            // ✅ 최적화: ValueKey 추가
            itemBuilder: (context, index) {
              final vessel = vessels[index];
              return _buildVesselCard(
                context,
                vessel,
                key: ValueKey('vessel_${vessel.mmsi}'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: TextField(
        decoration: InputDecoration(
          hintText: '선박명 또는 MMSI 검색',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.s8),
          ),
        ),
        onChanged: (value) {
          // TODO: 검색 기능 구현
        },
      ),
    );
  }

  // ✅ 최적화: Key 파라미터 추가
  Widget _buildVesselCard(
    BuildContext context,
    VesselSearchModel vessel, {
    Key? key,
  }) {
    final isSelected = vessel.mmsi == selectedMmsi;

    return Card(
      key: key, // ✅ Key 적용
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.s8,
        vertical: AppSizes.s4,
      ),
      elevation: isSelected ? 4 : 1,
      color:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          Icons.directions_boat,
          color:
              isSelected ? Theme.of(context).primaryColor : AppColors.grayType6,
        ),
        title: Text(
          vessel.ship_nm ?? 'Unknown',
          style: TextStyle(
            fontWeight: isSelected ? FontWeights.w700 : FontWeights.w500,
          ),
        ),
        subtitle: _buildVesselSubtitle(vessel),
        trailing: _buildVesselTrailing(vessel),
        onTap: () => onVesselSelected(vessel),
      ),
    );
  }

  Widget _buildVesselSubtitle(VesselSearchModel vessel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MMSI: ${vessel.mmsi ?? '-'}'),
        Text('선종: ${vessel.ship_knd ?? '-'}'),
        if (vessel.sog != null)
          Text('속력: ${vessel.sog!.toStringAsFixed(1)} knots'),
      ],
    );
  }

  Widget? _buildVesselTrailing(VesselSearchModel vessel) {
    if (vessel.mmsi == selectedMmsi) {
      return const Icon(
        Icons.check_circle,
        color: AppColors.primary,
      );
    }
    return null;
  }
}
