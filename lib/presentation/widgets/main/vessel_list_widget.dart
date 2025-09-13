import 'package:flutter/material.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';

class VesselListWidget extends StatelessWidget {
  final List<VesselSearchModel> vessels;
  final int? selectedMmsi;
  final ValueChanged<int> onVesselSelected;

  const VesselListWidget({
    super.key,
    required this.vessels,
    this.selectedMmsi,
    required this.onVesselSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (vessels.isEmpty) {
      return const Center(
        child: Text('등록된 선박이 없습니다.'),
      );
    }

    return ListView.builder(
      itemCount: vessels.length,
      itemBuilder: (context, index) {
        final vessel = vessels[index];
        final isSelected = vessel.mmsi == selectedMmsi;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
          child: ListTile(
            leading: Icon(
              Icons.directions_boat,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            title: Text(
              vessel.ship_nm ?? 'Unknown',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MMSI: ${vessel.mmsi ?? '-'}'),
                Text('선박종류: ${vessel.ship_knd ?? '-'}'),
                if (vessel.sog != null) Text('속력: ${vessel.sog!.toStringAsFixed(1)} knots'),
                if (vessel.cog != null) Text('침로: ${vessel.cog!.toStringAsFixed(1)}°'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (vessel.lttd != null && vessel.lntd != null)
                  Text(
                    '${vessel.lttd!.toStringAsFixed(4)}°\n${vessel.lntd!.toStringAsFixed(4)}°',
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
              ],
            ),
            onTap: () {
              if (vessel.mmsi != null) {
                onVesselSelected(vessel.mmsi!);
              }
            },
          ),
        );
      },
    );
  }
}
