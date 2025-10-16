import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/data/models//vessel_model.dart';

/// 선박 마커 레이어 위젯
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
        _buildCurrentUserVesselLayer(),
        // 다른 선박 마커
        _buildOtherVesselsLayer(),
      ],
    );
  }

  /// 현재 사용자 선박 레이어
  Widget _buildCurrentUserVesselLayer() {
    return MarkerLayer(
      markers: vessels
          .where((vessel) => (vessel.mmsi ?? 0) == userMmsi)
          .map((vessel) => _buildVesselMarker(
                vessel: vessel,
                svgPath: 'assets/kdn/home/img/myVessel.svg',
                onTap: null,
              ))
          .toList(),
    );
  }

  /// 다른 선박 레이어
  Widget _buildOtherVesselsLayer() {
    return Opacity(
      opacity: isOtherVesselsVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !isOtherVesselsVisible,
        child: MarkerLayer(
          markers: vessels
              .where((vessel) => (vessel.mmsi ?? 0) != userMmsi)
              .map((vessel) => _buildVesselMarker(
                    vessel: vessel,
                    svgPath: 'assets/kdn/home/img/otherVessel.svg',
                    onTap: () => onVesselTap(vessel),
                  ))
              .toList(),
        ),
      ),
    );
  }

  /// 선박 마커 생성
  Marker _buildVesselMarker({
    required VesselSearchModel vessel,
    required String svgPath,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
      width: 25,
      height: 25,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: (vessel.cog ?? 0) * (pi / 180),
          child: SvgPicture.asset(
            svgPath,
            width: 40,
            height: 40,
          ),
        ),
      ),
    );
  }
}

/// 항로 트랙 위젯
class RouteTrackWidget extends StatelessWidget {
  final List<LatLng> routePoints;
  final Color trackColor;
  final double strokeWidth;
  final bool isDotted;
  final bool showMarkers;
  final double markerSize;

  const RouteTrackWidget({
    super.key,
    required this.routePoints,
    this.trackColor = Colors.blue,
    this.strokeWidth = 3.0,
    this.isDotted = false,
    this.showMarkers = false,
    this.markerSize = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    if (routePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 항로 선
        PolylineLayer(
          polylines: [
            Polyline(
              points: routePoints,
              strokeWidth: strokeWidth,
              color: trackColor,
              isDotted: isDotted,
            ),
          ],
        ),
        // 항로 마커 (옵션)
        if (showMarkers)
          MarkerLayer(
            markers: _buildRouteMarkers(),
          ),
      ],
    );
  }

  /// 항로 포인트 마커 생성
  List<Marker> _buildRouteMarkers() {
    return routePoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      final isStart = index == 0;
      final isEnd = index == routePoints.length - 1;

      double size = markerSize;
      if (isStart || isEnd) size = markerSize * 2;

      return Marker(
        point: point,
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            color: isStart
                ? Colors.green
                : isEnd
                    ? Colors.red
                    : trackColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isStart || isEnd ? 1.0 : 0.5,
            ),
          ),
        ),
      );
    }).toList();
  }
}
