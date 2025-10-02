import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/presentation/providers/route_provider.dart';
import 'package:vms_app/presentation/screens/main/utils/geo_utils.dart';

/// 통합된 메인 지도 위젯
class MapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng? currentPosition;
  final List<VesselSearchModel> vessels;
  final int currentUserMmsi;
  final bool isOtherVesselsVisible;
  final bool isTrackingEnabled;
  final Function(VesselSearchModel) onVesselTap;

  const MapWidget({
    super.key,
    required this.mapController,
    this.currentPosition,
    required this.vessels,
    required this.currentUserMmsi,
    required this.isOtherVesselsVisible,
    required this.isTrackingEnabled,
    required this.onVesselTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, routeSearchViewModel, child) {
        // 항적 데이터 처리
        final pastRouteLine = _processPastRoute(routeSearchViewModel);
        final predRouteLine = _processPredRoute(routeSearchViewModel, pastRouteLine);

        // 트래킹 비활성화 또는 네비게이션 히스토리 모드가 아닌 경우 항적 클리어
        if (!isTrackingEnabled &&
            routeSearchViewModel.isNavigationHistoryMode != true) {
          pastRouteLine.clear();
          predRouteLine.clear();
        }

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
            onPositionChanged: (MapPosition position, bool hasGesture) {},
          ),
          children: [
            // 1. WMS 타일 레이어들
            ..._buildWMSLayers(),

            // 2. 과거항적 레이어
            if (pastRouteLine.isNotEmpty) ...[
              _buildPastRouteLine(pastRouteLine),
              _buildPastRouteMarkers(pastRouteLine),
            ],

            // 3. 예측항로 레이어
            if (predRouteLine.isNotEmpty) ...[
              _buildPredRouteLine(predRouteLine),
              _buildPredRouteMarkers(predRouteLine),
            ],

            // 4. 퇴각항로 레이어 (관리자만)
            if (isOtherVesselsVisible) ...[
              _buildEscapeRouteLine(vessels),
              _buildEscapeRouteEndpoints(vessels),
            ],

            // 5. 선박 마커 레이어
            _buildCurrentUserVessel(vessels, currentUserMmsi),
            if (isOtherVesselsVisible)
              _buildOtherVessels(vessels, currentUserMmsi, onVesselTap),
          ],
        );
      },
    );
  }

  /// WMS 타일 레이어 생성
  List<Widget> _buildWMSLayers() {
    final baseUrl = "${dotenv.env['GEOSERVER_URL']}?";
    final layers = [
      'vms_space:enc_map',        // 전자해도
      'vms_space:t_enc_sou_sp01', // 수심
      'vms_space:t_gis_tur_sp01', // 터빈
    ];

    return layers.map((layer) => TileLayer(
      wmsOptions: WMSTileLayerOptions(
        baseUrl: baseUrl,
        layers: [layer],
        format: 'image/png',
        transparent: true,
        version: '1.1.1',
      ),
    )).toList();
  }

  /// 과거 항적 처리
  List<LatLng> _processPastRoute(RouteProvider viewModel) {
    var pastRouteLine = <LatLng>[];

    if (viewModel.pastRoutes.isEmpty) return pastRouteLine;

    int cnt = viewModel.pastRoutes.length <= 20 ? 1 : 20;

    // 첫 번째 포인트
    final firstPoint = viewModel.pastRoutes.first;
    pastRouteLine.add(LatLng(firstPoint.lttd ?? 0, firstPoint.lntd ?? 0));

    // 중간 포인트들 (샘플링)
    if (viewModel.pastRoutes.length > 2) {
      for (int i = 1; i < viewModel.pastRoutes.length - 1; i++) {
        if (i % cnt == 0) {
          final route = viewModel.pastRoutes[i];
          pastRouteLine.add(LatLng(route.lttd ?? 0, route.lntd ?? 0));
        }
      }
    }

    // 마지막 포인트
    final lastPoint = viewModel.pastRoutes.last;
    pastRouteLine.add(LatLng(lastPoint.lttd ?? 0, lastPoint.lntd ?? 0));

    return pastRouteLine;
  }

  /// 예측 항로 처리
  List<LatLng> _processPredRoute(RouteProvider viewModel, List<LatLng> pastRouteLine) {
    var predRouteLine = viewModel.predRoutes
        .map((route) => LatLng(route.lttd ?? 0, route.lntd ?? 0))
        .toList();

    // 과거항적과 예측항로 연결
    if (predRouteLine.isNotEmpty && pastRouteLine.isNotEmpty) {
      pastRouteLine.add(predRouteLine.first);
    }

    return predRouteLine;
  }

  /// 과거 항적 선 레이어
  Widget _buildPastRouteLine(List<LatLng> pastRouteLine) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: pastRouteLine,
          strokeWidth: 1.0,
          color: Colors.orange,
        ),
      ],
    );
  }

  /// 과거 항적 마커 레이어
  Widget _buildPastRouteMarkers(List<LatLng> pastRouteLine) {
    return MarkerLayer(
      markers: pastRouteLine.asMap().entries.map((entry) {
        int index = entry.key;
        LatLng point = entry.value;

        // 시작점은 크게, 나머지는 작게
        final isStartPoint = index == 0;
        final size = isStartPoint ? 10.0 : 4.0;
        final borderWidth = isStartPoint ? 1.0 : 0.5;

        return Marker(
          point: point,
          width: size,
          height: size,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: borderWidth),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 예측 항로 선 레이어
  Widget _buildPredRouteLine(List<LatLng> predRouteLine) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: predRouteLine,
          strokeWidth: 1.0,
          color: Colors.red,
        ),
      ],
    );
  }

  /// 예측 항로 마커 레이어
  Widget _buildPredRouteMarkers(List<LatLng> predRouteLine) {
    return MarkerLayer(
      markers: predRouteLine.map((point) {
        return Marker(
          point: point,
          width: 4,
          height: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 0.5),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 퇴각 항로 선 레이어
  Widget _buildEscapeRouteLine(List<VesselSearchModel> vessels) {
    return PolylineLayer(
      polylineCulling: false,
      polylines: vessels
          .where((v) => v.escapeRouteGeojson != null)
          .map((v) {
        final pts = GeoUtils.parseGeoJsonLineString(v.escapeRouteGeojson ?? '');
        return Polyline(
          points: pts,
          strokeWidth: 2.0,
          color: Colors.black,
          isDotted: true,
        );
      }).toList(),
    );
  }

  /// 퇴각 항로 끝점 삼각형 레이어
  Widget _buildEscapeRouteEndpoints(List<VesselSearchModel> vessels) {
    return PolygonLayer(
      polygons: vessels
          .where((v) => v.escapeRouteGeojson != null)
          .map((v) => _createTrianglePolygon(v))
          .where((poly) => poly != null)
          .cast<Polygon>()
          .toList(),
    );
  }

  /// 삼각형 폴리곤 생성
  Polygon? _createTrianglePolygon(VesselSearchModel vessel) {
    final pts = GeoUtils.parseGeoJsonLineString(vessel.escapeRouteGeojson ?? '');
    if (pts.length < 2) return null;

    final end = pts.last;
    final prev = pts[pts.length - 2];

    final dx = end.longitude - prev.longitude;
    final dy = end.latitude - prev.latitude;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist == 0) return null;

    final ux = dx / dist;
    final uy = dy / dist;
    final vx = -uy;
    final vy = ux;

    double size = 0.0005;

    final apex = LatLng(
      end.latitude + uy * size,
      end.longitude + ux * size,
    );

    final baseCenter = LatLng(
      end.latitude - uy * (size * 0.5),
      end.longitude - ux * (size * 0.5),
    );

    final halfWidth = size / sqrt(3);

    final b1 = LatLng(
      baseCenter.latitude + vy * halfWidth,
      baseCenter.longitude + vx * halfWidth,
    );
    final b2 = LatLng(
      baseCenter.latitude - vy * halfWidth,
      baseCenter.longitude - vx * halfWidth,
    );

    return Polygon(
      points: [apex, b1, b2],
      color: Colors.black,
      borderColor: Colors.black,
      borderStrokeWidth: 1,
      isFilled: true,
    );
  }

  /// 현재 사용자 선박 마커
  Widget _buildCurrentUserVessel(List<VesselSearchModel> vessels, int currentUserMmsi) {
    return MarkerLayer(
      markers: vessels
          .where((vessel) => (vessel.mmsi ?? 0) == currentUserMmsi)
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
    );
  }

  /// 다른 선박 마커
  Widget _buildOtherVessels(
      List<VesselSearchModel> vessels,
      int currentUserMmsi,
      Function(VesselSearchModel) onVesselTap,
      ) {
    return MarkerLayer(
      markers: vessels
          .where((vessel) => (vessel.mmsi ?? 0) != currentUserMmsi)
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
    );
  }
}

/// 기존 MainMapWidget 별칭 (하위 호환성)
@Deprecated('Use MapWidget instead')
class MainMapWidget extends MapWidget {
  const MainMapWidget({
    super.key,
    required super.mapController,
    super.currentPosition,
    required super.vessels,
    required super.currentUserMmsi,
    required super.isOtherVesselsVisible,
    required super.isTrackingEnabled,
    required super.onVesselTap,
  });
}