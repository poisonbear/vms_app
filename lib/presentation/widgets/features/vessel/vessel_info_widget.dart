import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';

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
      padding: EdgeInsets.all(getSize16().toDouble()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(getSize12().toDouble()),
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
            _buildInfoRow('흘수', vessel!.draft != null ? '${vessel!.draft} m' : '-'),
            _buildInfoRow('속력', vessel!.sog != null ? '${vessel!.sog!.toStringAsFixed(1)} kn' : '-'),
            _buildInfoRow('침로', vessel!.cog != null ? '${vessel!.cog!.toStringAsFixed(1)}°' : '-'),
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
          padding: EdgeInsets.symmetric(vertical: getSize8().toDouble()),
          child: Text(
            label,
            style: TextStyle(
              fontSize: getSize14().toDouble(),
              fontWeight: getText500(),
              color: getColorGrayType6(),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: getSize8().toDouble()),
          child: Text(
            value,
            style: TextStyle(
              fontSize: getSize14().toDouble(),
              fontWeight: getText600(),
              color: getColorBlackType2(),
            ),
          ),
        ),
      ],
    );
  }
}

/// 선박 목록 위젯
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
            itemBuilder: (context, index) => _buildVesselCard(
              context,
              vessels[index],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(getSize16().toDouble()),
      child: TextField(
        decoration: InputDecoration(
          hintText: '선박명 또는 MMSI 검색',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(getSize8().toDouble()),
          ),
        ),
        onChanged: (value) {
          // TODO: 검색 기능 구현
        },
      ),
    );
  }

  Widget _buildVesselCard(BuildContext context, VesselSearchModel vessel) {
    final isSelected = vessel.mmsi == selectedMmsi;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: getSize8().toDouble(),
        vertical: getSize4().toDouble(),
      ),
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      child: ListTile(
        leading: Icon(
          Icons.directions_boat,
          color: isSelected
              ? Theme.of(context).primaryColor
              : getColorGrayType6(),
        ),
        title: Text(
          vessel.ship_nm ?? 'Unknown',
          style: TextStyle(
            fontWeight: isSelected ? getText700() : getText500(),
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
    if (vessel.lttd != null && vessel.lntd != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${vessel.lttd!.toStringAsFixed(4)}°',
            style: TextStyle(fontSize: getSize11().toDouble()),
          ),
          Text(
            '${vessel.lntd!.toStringAsFixed(4)}°',
            style: TextStyle(fontSize: getSize11().toDouble()),
          ),
        ],
      );
    }
    return null;
  }
}