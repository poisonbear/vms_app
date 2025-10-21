// lib/presentation/widgets/features/map/map_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/presentation/providers/route_provider.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/widgets/features/map/map_layer.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 통합된 메인 지도 위젯 (StatefulWidget으로 변경)
class MapWidget extends StatefulWidget {
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
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  double _currentZoom = 12.0; // 현재 줌 레벨 상태

  @override
  Widget build(BuildContext context) {
    return Consumer2<RouteProvider, NavigationProvider>(
      builder: (context, routeSearchViewModel, navigationProvider, child) {
        // 항적 데이터 처리
        final pastRouteLine = _processPastRoute(routeSearchViewModel);
        final predRouteLine =
            _processPredRoute(routeSearchViewModel, pastRouteLine);

        // 트래킹 비활성화 또는 네비게이션 히스토리 모드가 아닌 경우 항적 클리어
        if (!widget.isTrackingEnabled &&
            routeSearchViewModel.isNavigationHistoryMode != true) {
          pastRouteLine.clear();
          predRouteLine.clear();
        }

        // 항행경보 데이터
        final navigationWarnings = navigationProvider.navigationWarningDetails;

        return FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter:
                widget.currentPosition ?? const LatLng(35.374509, 126.132268),
            initialZoom: 12.0,
            maxZoom: 14.0,
            minZoom: 5.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onPositionChanged: (MapPosition position, bool hasGesture) {
              // 줌 레벨 변경 감지 및 상태 업데이트
              if (position.zoom != null && position.zoom != _currentZoom) {
                setState(() {
                  _currentZoom = position.zoom!;
                });
              }
            },
          ),
          children: [
            // 1. WMS 타일 레이어들
            ..._buildWMSLayers(),

            // 2. 항행경보 레이어 (지도 배경 위, 다른 레이어 아래)
            NavigationWarningLayer(
              warnings: navigationWarnings,
              isVisible: true,
              currentZoom: _currentZoom, // 현재 줌 레벨 전달
            ),

            // 3. 과거항적 레이어
            if (pastRouteLine.isNotEmpty) ...[
              _buildPastRouteLine(pastRouteLine),
              _buildPastRouteMarkers(pastRouteLine),
            ],

            // 4. 예측항로 레이어
            if (predRouteLine.isNotEmpty) ...[
              _buildPredRouteLine(predRouteLine),
              _buildPredRouteMarkers(predRouteLine),
            ],

            // 5. 퇴각항로 레이어 (관리자만)
            if (widget.isOtherVesselsVisible) ...[
              _buildEscapeRouteLine(widget.vessels),
              _buildEscapeRouteEndpoints(widget.vessels),
            ],

            // 6. 선박 마커 레이어
            _buildCurrentUserVessel(widget.vessels, widget.currentUserMmsi),
            if (widget.isOtherVesselsVisible)
              _buildOtherVessels(
                  widget.vessels, widget.currentUserMmsi, widget.onVesselTap),
          ],
        );
      },
    );
  }

  /// WMS 타일 레이어 생성
  List<Widget> _buildWMSLayers() {
    final baseUrl = "${ApiConfig.geoserverUrl}?";
    final layers = [
      'vms_space:enc_map', // 전자해도
      'vms_space:t_enc_sou_sp01', // 수심
      'vms_space:t_gis_tur_sp01', // 터빈
    ];

    return layers
        .map((layer) => TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: baseUrl,
                layers: [layer],
                format: 'image/png',
                transparent: true,
                version: '1.1.1',
              ),
            ))
        .toList();
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
  List<LatLng> _processPredRoute(
      RouteProvider viewModel, List<LatLng> pastRouteLine) {
    var predRouteLine = viewModel.predRoutes
        .map((route) => LatLng(route.lttd ?? 0, route.lntd ?? 0))
        .toList();

    // 예측 항로가 있고 과거 항로의 마지막 점이 있으면 연결
    if (predRouteLine.isNotEmpty && pastRouteLine.isNotEmpty) {
      predRouteLine.insert(0, pastRouteLine.last);
    }

    return predRouteLine;
  }

  /// 과거항적 선
  Widget _buildPastRouteLine(List<LatLng> pastRouteLine) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: pastRouteLine,
          strokeWidth: 3.0,
          color: AppColors.primary,
        ),
      ],
    );
  }

  /// 과거항적 마커
  Widget _buildPastRouteMarkers(List<LatLng> pastRouteLine) {
    return MarkerLayer(
      markers: [
        // 시작점 마커 (녹색)
        if (pastRouteLine.isNotEmpty)
          Marker(
            point: pastRouteLine.first,
            width: 12,
            height: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        // 끝점 마커 (빨강)
        if (pastRouteLine.length > 1)
          Marker(
            point: pastRouteLine.last,
            width: 12,
            height: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  /// 예측항로 선
  Widget _buildPredRouteLine(List<LatLng> predRouteLine) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: predRouteLine,
          strokeWidth: 3.0,
          color: Colors.orange,
          isDotted: true,
        ),
      ],
    );
  }

  /// 예측항로 마커
  Widget _buildPredRouteMarkers(List<LatLng> predRouteLine) {
    return MarkerLayer(
      markers: predRouteLine.length > 1
          ? [
              Marker(
                point: predRouteLine.last,
                width: 12,
                height: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ]
          : [],
    );
  }

  /// 퇴각항로 선
  Widget _buildEscapeRouteLine(List<VesselSearchModel> vessels) {
    // VesselSearchModel에 escapeRoute가 없으므로 빈 리스트 반환
    return const PolylineLayer(polylines: []);
  }

  /// 퇴각항로 끝점
  Widget _buildEscapeRouteEndpoints(List<VesselSearchModel> vessels) {
    // VesselSearchModel에 escapeRoute가 없으므로 빈 마커 반환
    return const MarkerLayer(markers: []);
  }

  /// 현재 사용자 선박
  Widget _buildCurrentUserVessel(
      List<VesselSearchModel> vessels, int currentUserMmsi) {
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

  /// 다른 선박들
  Widget _buildOtherVessels(List<VesselSearchModel> vessels,
      int currentUserMmsi, Function(VesselSearchModel) onVesselTap) {
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
