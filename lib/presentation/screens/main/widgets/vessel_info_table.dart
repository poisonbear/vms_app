import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 선박 정보 테이블 위젯
class VesselInfoTable extends StatelessWidget {
  final String? shipName;
  final int? mmsi;
  final String? vesselType;
  final double? draft;
  final double? sog;
  final double? cog;

  const VesselInfoTable({
    super.key,
    this.shipName,
    this.mmsi,
    this.vesselType,
    this.draft,
    this.sog,
    this.cog,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(80),
        1: FlexColumnWidth(),
      },
      children: [
        _buildInfoRow('선박명', shipName ?? '-'),
        _buildInfoRow('MMSI', mmsi?.toString() ?? '-'),
        _buildInfoRow('선종', vesselType ?? '-'),
        _buildInfoRow('흘수', draft != null ? '$draft m' : '-'),
        _buildInfoRow('대지속도', sog != null ? '$sog kn' : '-'),
        _buildInfoRow('대지침로', cog != null ? '$cog°' : '-'),
      ],
    );
  }

  TableRow _buildInfoRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: getSize10().toDouble()),
          child: Text(
            label,
            style: TextStyle(
              fontSize: DesignConstants.fontSizeS,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: getSize10().toDouble()),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: DesignConstants.fontSizeL,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
