import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';

class VesselMarkersLayer extends StatelessWidget {
  final List<VesselSearchModel> vessels;
  final int userMmsi;
  final bool isOtherVesselsVisible;
  final Function(VesselSearchModel) onVesselTap;

  const VesselMarkersLayer({
    super.key,
    required this.vessels,
    required this.userMmsi,
    required this.isOtherVesselsVisible,
    required this.onVesselTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 내 선박 마커
        MarkerLayer(
          markers: vessels
              .where((vessel) => (vessel.mmsi ?? 0) == userMmsi)
              .map((vessel) {
            return Marker(
              point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
              width: 25,
              height: 25,
              child: Transform.rotate(
                angle: (vessel.cog ?? 0) * (pi / 180),
                child: SvgPicture.asset(
                  'assets/kdn/home/img/myVessel.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            );
          }).toList(),
        ),
        // 다른 선박 마커
        Opacity(
          opacity: isOtherVesselsVisible ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !isOtherVesselsVisible,
            child: MarkerLayer(
              markers: vessels
                  .where((vessel) => (vessel.mmsi ?? 0) != userMmsi)
                  .map((vessel) {
                return Marker(
                  point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
                  width: 25,
                  height: 25,
                  child: GestureDetector(
                    onTap: () => onVesselTap(vessel),
                    child: Transform.rotate(
                      angle: (vessel.cog ?? 0) * (pi / 180),
                      child: SvgPicture.asset(
                        'assets/kdn/home/img/otherVessel.svg',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
