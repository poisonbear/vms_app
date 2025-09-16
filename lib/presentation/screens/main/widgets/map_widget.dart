import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/presentation/providers/route_search_provider.dart';
import '../utils/geo_utils.dart';

class MainMapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng? currentPosition;
  final List<VesselSearchModel> vessels;
  final int currentUserMmsi;
  final bool isOtherVesselsVisible;
  final bool isTrackingEnabled;
  final Function(VesselSearchModel) onVesselTap;

  const MainMapWidget({
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
    return Consumer<RouteSearchProvider>(
      builder: (context, routeSearchViewModel, child) {
        // 과거항적 처리
        var pastRouteLine = <LatLng>[];
        if (routeSearchViewModel.pastRoutes.isNotEmpty) {
          int cnt = 20;
          if (routeSearchViewModel.pastRoutes.length <= cnt) cnt = 1;

          // 첫 번째 포인트
          final firstPoint = routeSearchViewModel.pastRoutes.first;
          pastRouteLine.add(LatLng(firstPoint.lttd ?? 0, firstPoint.lntd ?? 0));

          // 중간 포인트들
          if (routeSearchViewModel.pastRoutes.length > 2) {
            for (int i = 1;
            i < routeSearchViewModel.pastRoutes.length - 1;
            i++) {
              if (i % cnt == 0) {
                final route = routeSearchViewModel.pastRoutes[i];
                pastRouteLine.add(LatLng(route.lttd ?? 0, route.lntd ?? 0));
              }
            }
          }

          // 마지막 포인트
          final lastPoint = routeSearchViewModel.pastRoutes.last;
          pastRouteLine.add(LatLng(lastPoint.lttd ?? 0, lastPoint.lntd ?? 0));
        }

        // 예측항로 처리
        var predRouteLine = <LatLng>[];
        predRouteLine.addAll(routeSearchViewModel.predRoutes
            .map((route) => LatLng(route.lttd ?? 0, route.lntd ?? 0))
            .toList());

        if (predRouteLine.isNotEmpty && pastRouteLine.isNotEmpty) {
          pastRouteLine.add(predRouteLine.first);
        }

        // 트래킹 비활성화 또는 네비게이션 히스토리 모드가 아닌 경우 항적 클리어
        if (!isTrackingEnabled &&
            routeSearchViewModel.isNavigationHistoryMode != true) {
          pastRouteLine.clear();
          predRouteLine.clear();
        }

        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter:
            currentPosition ?? const LatLng(35.374509, 126.132268),
            initialZoom: 12.0,
            maxZoom: 14.0,
            minZoom: 5.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onPositionChanged: (MapPosition position, bool hasGesture) {},
          ),
          children: [
            // 1. WMS 타일 레이어들 (전자해도, 수심, 터빈)
            TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                layers: const ['vms_space:enc_map'],
                format: 'image/png',
                transparent: true,
                version: '1.1.1',
              ),
            ),
            TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                layers: const ['vms_space:t_enc_sou_sp01'],
                format: 'image/png',
                transparent: true,
                version: '1.1.1',
              ),
            ),
            TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                layers: const ['vms_space:t_gis_tur_sp01'],
                format: 'image/png',
                transparent: true,
                version: '1.1.1',
              ),
            ),

            // 2. 과거항적 선 레이어
            if (pastRouteLine.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: pastRouteLine,
                    strokeWidth: 1.0,
                    color: Colors.orange,
                  ),
                ],
              ),

            // 3. 과거항적 포인트 레이어
            if (pastRouteLine.isNotEmpty)
              MarkerLayer(
                markers: pastRouteLine.asMap().entries.map((entry) {
                  int index = entry.key;
                  LatLng point = entry.value;

                  if (index == 0) {
                    return Marker(
                      point: point,
                      width: 10,
                      height: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    );
                  } else {
                    return Marker(
                      point: point,
                      width: 4,
                      height: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 0.5),
                        ),
                      ),
                    );
                  }
                }).toList(),
              ),

            // 4. 예측항로 선 레이어
            if (predRouteLine.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: predRouteLine,
                    strokeWidth: 1.0,
                    color: Colors.red,
                  ),
                ],
              ),

            // 5. 예측항로 포인트 레이어
            if (predRouteLine.isNotEmpty)
              MarkerLayer(
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
              ),

            // 6. 퇴각항로 선 레이어 - 선박표시 기능과 연동
            Opacity(
              opacity: isOtherVesselsVisible ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !isOtherVesselsVisible,
                child: PolylineLayer(
                  polylineCulling: false,
                  polylines: vessels
                      .where((v) => v.escapeRouteGeojson != null)
                      .map((v) {
                    final pts = GeoUtils.parseGeoJsonLineString(
                        v.escapeRouteGeojson ?? '');
                    return Polyline(
                      points: pts,
                      strokeWidth: 2.0,
                      color: Colors.black,
                      isDotted: true,
                    );
                  }).toList(),
                ),
              ),
            ),

            // 7. 퇴각항로 끝점 삼각형 - 선박표시 기능과 연동
            Opacity(
              opacity: isOtherVesselsVisible ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !isOtherVesselsVisible,
                child: PolygonLayer(
                  polygons: vessels
                      .where((v) => v.escapeRouteGeojson != null)
                      .map((v) {
                    final pts = GeoUtils.parseGeoJsonLineString(
                        v.escapeRouteGeojson ?? '');
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
                  })
                      .where((poly) => poly != null)
                      .cast<Polygon>()
                      .toList(),
                ),
              ),
            ),

            // 8. 현재 선박 레이어
            MarkerLayer(
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
            ),

            // 9. 다른 선박 레이어
            Opacity(
              opacity: isOtherVesselsVisible ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !isOtherVesselsVisible,
                child: MarkerLayer(
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}