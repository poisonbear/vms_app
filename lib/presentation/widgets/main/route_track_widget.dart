import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteTrackWidget extends StatelessWidget {
  final List<LatLng> routePoints;
  final Color trackColor;
  final double strokeWidth;
  final bool isDotted;
  
  const RouteTrackWidget({
    super.key,
    required this.routePoints,
    this.trackColor = Colors.blue,
    this.strokeWidth = 3.0,
    this.isDotted = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (routePoints.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return PolylineLayer(
      polylines: [
        Polyline(
          points: routePoints,
          strokeWidth: strokeWidth,
          color: trackColor,
          isDotted: isDotted,
        ),
      ],
    );
  }
}
