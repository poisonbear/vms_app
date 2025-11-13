// lib/presentation/widgets/features/map/map_layer.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/data/models/navigation_model.dart';
import 'package:vms_app/core/constants/constants.dart';

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
        _buildCurrentUserVesselLayer(),
        _buildOtherVesselsLayer(),
      ],
    );
  }

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
        if (showMarkers)
          MarkerLayer(
            markers: _buildRouteMarkers(),
          ),
      ],
    );
  }

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

/// 항행경보 표시 레이어 위젯
class NavigationWarningLayer extends StatelessWidget {
  final List<NavigationWarningModel> warnings;
  final bool isVisible;
  final double currentZoom;

  const NavigationWarningLayer({
    super.key,
    required this.warnings,
    this.isVisible = true,
    this.currentZoom = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        _buildPolygonLayer(),
        _buildCircleLayer(),
        _buildLabelLayer(),
      ],
    );
  }

  Widget _buildPolygonLayer() {
    final polygonWarnings = warnings.where(
      (w) => w.shapeType == MapConstants.warningShapePolygon,
    );

    if (polygonWarnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return PolygonLayer(
      polygons: polygonWarnings.map((warning) {
        return Polygon(
          points: warning.polygonPoints,
          color: Colors.transparent,
          borderColor: Color(warning.warningColor)
              .withValues(alpha: MapConstants.warningBorderOpacity),
          borderStrokeWidth: MapConstants.warningBorderWidth,
          isFilled: true,
          isDotted: false,
        );
      }).toList(),
    );
  }

  Widget _buildCircleLayer() {
    final circleWarnings = warnings.where(
      (w) => w.shapeType == MapConstants.warningShapeCircle,
    );

    if (circleWarnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return CircleLayer(
      circles: circleWarnings
          .map((warning) {
            final center = warning.circleCenter;
            if (center == null) return null;

            final radiusInDegrees =
                warning.radiusNM * MapConstants.nmToDegreesLat;

            return CircleMarker(
              point: center,
              radius: radiusInDegrees * 111320,
              useRadiusInMeter: true,
              color: Colors.transparent,
              borderColor: Color(warning.warningColor)
                  .withValues(alpha: MapConstants.warningBorderOpacity),
              borderStrokeWidth: MapConstants.warningBorderWidth,
            );
          })
          .whereType<CircleMarker>()
          .toList(),
    );
  }

  Widget _buildLabelLayer() {
    return MarkerLayer(
      markers: warnings
          .map((warning) {
            final center = warning.labelCenter;
            if (center == null) return null;

            final scale = _calculateScale(currentZoom);

            return Marker(
              point: center,
              width: 200 * scale,
              height: 60 * scale,
              child: _buildLabel(warning, scale),
            );
          })
          .whereType<Marker>()
          .toList(),
    );
  }

  double _calculateScale(double zoom) {
    //const baseZoom = 12.0;
    final scale = 0.6 + ((zoom - 10.0) * 0.2);
    return scale.clamp(0.4, 1.6);
  }

  Widget _buildLabel(NavigationWarningModel warning, double scale) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: MapConstants.warningLabelPaddingHorizontal * scale,
        vertical: MapConstants.warningLabelPaddingVertical * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4 * scale),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            warning.areaNm,
            style: TextStyle(
              color: Colors.white,
              fontSize: MapConstants.warningLabelFontSize * scale,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2 * scale,
                  offset: Offset(1 * scale, 1 * scale),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2 * scale),
          Text(
            warning.ntiHh,
            style: TextStyle(
              color: Colors.white,
              fontSize: MapConstants.warningLabelFontSizeSmall * scale,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2 * scale,
                  offset: Offset(1 * scale, 1 * scale),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
