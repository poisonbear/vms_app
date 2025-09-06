import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/presentation/providers/route_search_provider.dart';

/// 메인 지도 위젯 - FlutterMap과 모든 레이어 관리
class MapWidget extends StatelessWidget {
  final LatLng? currentPosition;
  final List<VesselSearchModel> vessels;
  final int currentUserMmsi;
  final bool isOtherVesselsVisible;
  final MapController mapController;
  final Function(VesselSearchModel) onVesselTap;

  const MapWidget({
    super.key,
    this.currentPosition,
    required this.vessels,
    required this.currentUserMmsi,
    required this.isOtherVesselsVisible,
    required this.mapController,
    required this.onVesselTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteSearchProvider>(
      builder: (context, routeSearchViewModel, child) {
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentPosition ?? const LatLng(35.374509, 126.132268),
            initialZoom: 12.0,
            maxZoom: 14.0,
            minZoom: 5.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            _buildBaseLayers(),
            _buildRoutePolylines(routeSearchViewModel),
            _buildRouteMarkers(routeSearchViewModel),
            _buildEscapeRoutes(),
            _buildVesselMarkers(),
          ],
        );
      },
    );
  }

  /// 기본 레이어 (전자해도, 터빈)
  Widget _buildBaseLayers() {
    return TileLayer(
      wmsOptions: WMSTileLayerOptions(
        baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
        layers: const ['vms_space:enc_map'],
        format: 'image/png',
        transparent: true,
        version: '1.1.1',
      ),
    );
  }

  /// 항로 폴리라인
  Widget _buildRoutePolylines(RouteSearchProvider routeSearchViewModel) {
    // 간단한 구현 - 실제로는 더 복잡한 로직 필요
    return const PolylineLayer(polylines: []);
  }

  /// 항로 마커
  Widget _buildRouteMarkers(RouteSearchProvider routeSearchViewModel) {
    return const MarkerLayer(markers: []);
  }

  /// 퇴각항로
  Widget _buildEscapeRoutes() {
    return const PolylineLayer(polylines: []);
  }

  /// 선박 마커
  Widget _buildVesselMarkers() {
    return MarkerLayer(
      markers: vessels.map((vessel) {
        final isCurrentUser = vessel.mmsi == currentUserMmsi;

        return Marker(
          point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
          width: 25,
          height: 25,
          child: GestureDetector(
            onTap: () => isCurrentUser ? null : onVesselTap(vessel),
            child: Transform.rotate(
              angle: (vessel.cog ?? 0) * (pi / 180),
              child: SvgPicture.asset(
                isCurrentUser ? 'assets/kdn/home/img/myVessel.svg' : 'assets/kdn/home/img/otherVessel.svg',
                width: 40,
                height: 40,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
