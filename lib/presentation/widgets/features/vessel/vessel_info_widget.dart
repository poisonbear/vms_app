// lib/presentation/widgets/features/vessel/vessel_info_widget.dart

import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/vessel_model.dart';

/// 선박 목록 위젯
class VesselListWidget extends StatefulWidget {
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
  State<VesselListWidget> createState() => _VesselListWidgetState();
}

class _VesselListWidgetState extends State<VesselListWidget> {
  //검색 기능을 위한 상태 변수
  String _searchQuery = '';
  List<VesselSearchModel> _filteredVessels = [];

  @override
  void initState() {
    super.initState();
    _filteredVessels = widget.vessels;
  }

  @override
  void didUpdateWidget(VesselListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // vessels 목록이 변경되면 필터 재적용
    if (oldWidget.vessels != widget.vessels) {
      _applyFilter(_searchQuery);
    }
  }

  ///검색 필터 적용
  void _applyFilter(String query) {
    setState(() {
      _searchQuery = query;

      if (query.isEmpty) {
        // 검색어가 없으면 전체 목록 표시
        _filteredVessels = widget.vessels;
      } else {
        // 선박명 또는 MMSI로 검색
        _filteredVessels = widget.vessels.where((vessel) {
          final shipName = vessel.ship_nm?.toLowerCase() ?? '';
          final mmsiStr = vessel.mmsi?.toString() ?? '';
          final lowerQuery = query.toLowerCase();

          return shipName.contains(lowerQuery) || mmsiStr.contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 필터링된 목록이 비어있을 때
    if (_filteredVessels.isEmpty) {
      return Column(
        children: [
          if (widget.showSearchBar) _buildSearchBar(context),
          Expanded(
            child: Center(
              child: Text(
                _searchQuery.isEmpty
                    ? (widget.emptyMessage ?? '등록된 선박이 없습니다.')
                    : '검색 결과가 없습니다.',
                style: const TextStyle(
                  fontSize: AppSizes.s16,
                  color: AppColors.grayType6,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (widget.showSearchBar) _buildSearchBar(context),

        //검색 결과 개수 표시 (검색 중일 때만)
        if (_searchQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16,
              vertical: AppSizes.s8,
            ),
            color: AppColors.grayType9.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(Icons.search,
                    size: AppSizes.s16, color: AppColors.grayType6),
                const SizedBox(width: AppSizes.s8),
                Text(
                  '검색 결과: ${_filteredVessels.length}건',
                  style: const TextStyle(
                    fontSize: AppSizes.s14,
                    color: AppColors.grayType6,
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.builder(
            itemCount: _filteredVessels.length,
            itemBuilder: (context, index) {
              final vessel = _filteredVessels[index];
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

  ///검색바 (검색 기능 구현 완료)
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: TextField(
        decoration: InputDecoration(
          hintText: '선박명 또는 MMSI 검색',
          hintStyle: const TextStyle(color: AppColors.grayType6),
          prefixIcon: const Icon(Icons.search, color: AppColors.grayType6),
          //검색어가 있을 때 X 버튼 표시
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.grayType6),
                  onPressed: () => _applyFilter(''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.s8),
            borderSide: const BorderSide(color: AppColors.grayType8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.s8),
            borderSide: const BorderSide(color: AppColors.grayType8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.s8),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppColors.whiteType1,
        ),
        onChanged: _applyFilter, //입력할 때마다 필터 적용
      ),
    );
  }

  /// 선박 카드 생성
  Widget _buildVesselCard(
    BuildContext context,
    VesselSearchModel vessel, {
    Key? key,
  }) {
    final isSelected = vessel.mmsi == widget.selectedMmsi;

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.s8,
        vertical: AppSizes.s4,
      ),
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
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
        onTap: () => widget.onVesselSelected(vessel),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (vessel.cog != null)
          Text(
            '${vessel.cog!.toStringAsFixed(0)}°',
            style: const TextStyle(
              fontSize: AppSizes.s12,
              color: AppColors.grayType6,
            ),
          ),
        const Icon(Icons.chevron_right, color: AppColors.grayType7),
      ],
    );
  }
}
