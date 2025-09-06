import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/presentation/providers/route_search_provider.dart';

class MainMapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng? currentPosition;
  final List<Widget> overlayWidgets;

  const MainMapWidget({
    super.key,
    required this.mapController,
    this.currentPosition,
    this.overlayWidgets = const [],
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
        predRouteLine.addAll((routeSearchViewModel.predRoutes ?? [])
            .map((route) => LatLng(route.lttd ?? 0, route.lntd ?? 0))
            .toList());

        if (predRouteLine.isNotEmpty && pastRouteLine.isNotEmpty) {
          pastRouteLine.add(predRouteLine.first);
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
          ),
          children: [
            // 전자해도 레이어들
            TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                layers: const ['vms_space:enc_map'],
                format: 'image/png',
                transparent: true,
                version: '1.1.1',
              ),
            ),
            // 추가 레이어들...
            ...overlayWidgets,
          ],
        );
      },
    );
  }
}
