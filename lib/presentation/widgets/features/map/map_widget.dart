// lib/presentation/widgets/features/map/map_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/presentation/providers/route_provider.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/widgets/features/map/map_layer.dart';

/// 통합된 메인 지도 위젯
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
  double _currentZoom = 12.0;

  // 팝업 상태 관리
  int? _selectedMarkerIndex;
  Offset? _popupPosition;

  /// 팝업 닫기 메서드
  void _closePopup() {
    if (_selectedMarkerIndex != null) {
      setState(() {
        _selectedMarkerIndex = null;
        _popupPosition = null;
      });
    }
  }

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

        return GestureDetector(
          // 지도 탭 시 팝업 닫기
          onTap: _closePopup,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              FlutterMap(
                mapController: widget.mapController,
                options: MapOptions(
                  initialCenter: widget.currentPosition ??
                      const LatLng(35.374509, 126.132268),
                  initialZoom: 12.0,
                  maxZoom: 14.0,
                  minZoom: 5.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onPositionChanged: (MapPosition position, bool hasGesture) {
                    // 줌 레벨 변경 감지 및 상태 업데이트
                    if (position.zoom != null &&
                        position.zoom != _currentZoom) {
                      setState(() {
                        _currentZoom = position.zoom!;
                      });
                    }
                  },
                  onTap: (tapPosition, point) {
                    // 지도 탭 시 팝업 닫기
                    _closePopup();
                  },
                ),
                children: [
                  // 1. WMS 타일 레이어들
                  ..._buildWMSLayers(),

                  // 2. 항행경보 레이어 (지도 배경 위, 다른 레이어 아래)
                  NavigationWarningLayer(
                    warnings: navigationWarnings,
                    isVisible: true,
                    currentZoom: _currentZoom,
                  ),

                  // 3. 과거항적 레이어
                  if (pastRouteLine.isNotEmpty) ...[
                    _buildPastRouteLine(pastRouteLine),
                    _buildPastRouteMarkers(pastRouteLine, routeSearchViewModel),
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
                  _buildCurrentUserVessel(
                      widget.vessels, widget.currentUserMmsi),
                  if (widget.isOtherVesselsVisible)
                    _buildOtherVessels(widget.vessels, widget.currentUserMmsi,
                        widget.onVesselTap),
                ],
              ),

              // 7. 팝업 오버레이
              if (_selectedMarkerIndex != null && _popupPosition != null)
                _buildTrackPointPopup(routeSearchViewModel),
            ],
          ),
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

  /// 과거항적 선 - 시간 흐름에 따른 색상 그라디언트
  /// 구간별로 색상이 변하는 여러 Polyline 생성
  Widget _buildPastRouteLine(List<LatLng> pastRouteLine) {
    if (pastRouteLine.length < 2) {
      return const PolylineLayer(polylines: []);
    }

    List<Polyline> polylines = [];

    // 구간별 색상 계산 (초록 → 노랑 → 주황 → 빨강)
    for (int i = 0; i < pastRouteLine.length - 1; i++) {
      final progress = i / (pastRouteLine.length - 1);
      final color = _getGradientColor(progress);

      polylines.add(
        Polyline(
          points: [pastRouteLine[i], pastRouteLine[i + 1]],
          strokeWidth: 2.0,
          color: color,
        ),
      );
    }

    return PolylineLayer(polylines: polylines);
  }

  /// 진행 상황에 따른 그라디언트 색상 계산
  Color _getGradientColor(double progress) {
    if (progress < 0.33) {
      return Color.lerp(Colors.green, Colors.yellow, progress / 0.33)!;
    } else if (progress < 0.66) {
      return Color.lerp(
          Colors.yellow, Colors.orange, (progress - 0.33) / 0.33)!;
    } else {
      return Color.lerp(Colors.orange, Colors.red, (progress - 0.66) / 0.34)!;
    }
  }

  /// 과거항적 마커
  Widget _buildPastRouteMarkers(
      List<LatLng> pastRouteLine, RouteProvider viewModel) {
    List<Marker> markers = [];

    if (viewModel.pastRoutes.isEmpty) return MarkerLayer(markers: markers);

    //시작점 마커 (초록색)
    if (pastRouteLine.isNotEmpty && viewModel.pastRoutes.isNotEmpty) {
      final startRoute = viewModel.pastRoutes.first;
      final isSelected = _selectedMarkerIndex == 0;

      markers.add(
        Marker(
          point: pastRouteLine.first,
          width: isSelected ? 32 : 24,
          height: isSelected ? 32 : 24,
          child: GestureDetector(
            onTap: () {
              _showTrackPointPopup(0, startRoute);
            },
            behavior: HitTestBehavior.opaque,
            child: Center(
              //AnimatedContainer 대신 일반 Container 사용
              child: Container(
                width: isSelected ? 18 : 14,
                height: isSelected ? 18 : 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 3.0 : 2.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.5),
                            blurRadius: 10.0,
                            spreadRadius: 3.0,
                          ),
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 20.0,
                            spreadRadius: 5.0,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 중간 포인트 마커
    if (pastRouteLine.length > 2) {
      int cnt = viewModel.pastRoutes.length <= 20 ? 1 : 20;

      for (int i = 1; i < viewModel.pastRoutes.length - 1; i++) {
        if (i % cnt == 0) {
          final route = viewModel.pastRoutes[i];
          final sog = route.sog;

          if (sog == null || sog <= 3.0) {
            continue;
          }

          final point = LatLng(route.lttd ?? 0, route.lntd ?? 0);
          final markerIndex = i;
          final isSelected = _selectedMarkerIndex == markerIndex;

          // 시간 진행률 계산
          final progress = i / (viewModel.pastRoutes.length - 1);
          final markerColor = _getGradientColor(progress);

          markers.add(
            Marker(
              point: point,
              width: isSelected ? 32 : 24,
              height: isSelected ? 32 : 24,
              child: GestureDetector(
                onTap: () {
                  _showTrackPointPopup(markerIndex, route);
                },
                behavior: HitTestBehavior.opaque,
                child: Center(
                  //AnimatedContainer 대신 일반 Container 사용
                  child: Container(
                    width: isSelected ? 12 : 8,
                    height: isSelected ? 12 : 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: markerColor,
                        width: isSelected ? 2.0 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: markerColor.withValues(alpha: 0.5),
                                blurRadius: 8.0,
                                spreadRadius: 2.0,
                              ),
                              BoxShadow(
                                color: markerColor.withValues(alpha: 0.3),
                                blurRadius: 16.0,
                                spreadRadius: 4.0,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      //내부 컨테이너도 일반 Container로
                      child: Container(
                        width: isSelected ? 5 : 3,
                        height: isSelected ? 5 : 3,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    //끝점 마커 (빨강색)
    if (pastRouteLine.length > 1 && viewModel.pastRoutes.isNotEmpty) {
      final endRoute = viewModel.pastRoutes.last;
      final endIndex = viewModel.pastRoutes.length - 1;
      final isSelected = _selectedMarkerIndex == endIndex;

      markers.add(
        Marker(
          point: pastRouteLine.last,
          width: isSelected ? 32 : 24,
          height: isSelected ? 32 : 24,
          child: GestureDetector(
            onTap: () {
              _showTrackPointPopup(endIndex, endRoute);
            },
            behavior: HitTestBehavior.opaque,
            child: Center(
              //AnimatedContainer 대신 일반 Container 사용
              child: Container(
                width: isSelected ? 18 : 14,
                height: isSelected ? 18 : 14,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 3.0 : 2.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 10.0,
                            spreadRadius: 3.0,
                          ),
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 20.0,
                            spreadRadius: 5.0,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  /// 중간 포인트 클릭 시 팝업 표시
  void _showTrackPointPopup(int markerIndex, PastRouteSearchModel route) {
    setState(() {
      _selectedMarkerIndex = markerIndex;

      // 화면 좌표 계산
      final latLng = LatLng(route.lttd ?? 0, route.lntd ?? 0);
      final point = widget.mapController.camera.latLngToScreenPoint(latLng);
      _popupPosition = Offset(point.x, point.y);
    });
  }

  /// 항적 포인트 팝업 위젯 - 항행이력 탭 스타일 적용
  Widget _buildTrackPointPopup(RouteProvider viewModel) {
    if (_selectedMarkerIndex == null) return const SizedBox.shrink();

    final route = viewModel.pastRoutes[_selectedMarkerIndex!];
    final screenSize = MediaQuery.of(context).size;

    // 팝업 크기
    const popupWidth = 220.0;
    const popupHeight = 160.0;

    // 팝업 위치 계산 (화면 밖으로 나가지 않도록)
    double left = (_popupPosition?.dx ?? 0) - popupWidth / 2;
    double top = (_popupPosition?.dy ?? 0) - popupHeight - 30;

    if (left < 10) left = 10;
    if (left + popupWidth > screenSize.width - 10) {
      left = screenSize.width - popupWidth - 10;
    }
    if (top < 10) {
      top = (_popupPosition?.dy ?? 0) + 30;
    }

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: popupWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A5F), // 네이비 색상
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '항적 정보',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMarkerIndex = null;
                          _popupPosition = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.transparent,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 본문
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.access_time,
                      '수신시각',
                      _formatRegDt(route.regDt),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.my_location,
                      '위도',
                      _formatLatitude(route.lttd),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.location_on,
                      '경도',
                      _formatLongitude(route.lntd),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.speed,
                      '속도',
                      '${route.sog?.toStringAsFixed(1) ?? '-'} knots', //sog로 통일
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 정보 행 위젯 (항행이력 탭 스타일)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// regDt 포맷팅 (int? -> String)
  /// regDt는 Unix timestamp (milliseconds) 또는 YYYYMMDDHHmmss 형식일 수 있음
  String _formatRegDt(int? regDt) {
    if (regDt == null) return '-';

    final regDtStr = regDt.toString();

    try {
      //STEP 1: Unix timestamp 확인 (길이가 10자리 이상이면서 큰 숫자)
      // Unix timestamp는 1970년 이후의 밀리초 또는 초 단위
      // 현재 시간 기준 약 1700000000000 (13자리) 이상

      // Unix timestamp (밀리초)인지 확인 (13자리)
      if (regDtStr.length == 13) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(regDt);
        return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }

      // Unix timestamp (초)인지 확인 (10자리이면서 큰 값)
      // 2000년 이후: 946684800 이상
      if (regDtStr.length == 10 && regDt > 946684800) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(regDt * 1000);
        return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }

      //STEP 2: YYYYMMDDHHmmss 형식 확인 (날짜/시간 형식)
      // 이 형식은 연도가 1900~2100 범위여야 함

      // YYYYMMDDHHmmss 형식인 경우 (14자리)
      if (regDtStr.length == 14) {
        final yearInt = int.tryParse(regDtStr.substring(0, 4));
        if (yearInt != null && yearInt >= 1900 && yearInt <= 2100) {
          final year = regDtStr.substring(0, 4);
          final month = regDtStr.substring(4, 6);
          final day = regDtStr.substring(6, 8);
          final hour = regDtStr.substring(8, 10);
          final minute = regDtStr.substring(10, 12);
          return '$year.$month.$day $hour:$minute';
        }
      }

      // YYYYMMDDHHmm 형식인 경우 (12자리)
      if (regDtStr.length == 12) {
        final yearInt = int.tryParse(regDtStr.substring(0, 4));
        if (yearInt != null && yearInt >= 1900 && yearInt <= 2100) {
          final year = regDtStr.substring(0, 4);
          final month = regDtStr.substring(4, 6);
          final day = regDtStr.substring(6, 8);
          final hour = regDtStr.substring(8, 10);
          final minute = regDtStr.substring(10, 12);
          return '$year.$month.$day $hour:$minute';
        }
      }

      // YYYYMMDDHH 형식인 경우 (10자리 - timestamp가 아닌 경우)
      if (regDtStr.length == 10) {
        final yearInt = int.tryParse(regDtStr.substring(0, 4));
        if (yearInt != null && yearInt >= 1900 && yearInt <= 2100) {
          final year = regDtStr.substring(0, 4);
          final month = regDtStr.substring(4, 6);
          final day = regDtStr.substring(6, 8);
          final hour = regDtStr.substring(8, 10);
          return '$year.$month.$day $hour:00';
        }
      }

      // YYYYMMDD 형식인 경우 (8자리)
      if (regDtStr.length == 8) {
        final yearInt = int.tryParse(regDtStr.substring(0, 4));
        if (yearInt != null && yearInt >= 1900 && yearInt <= 2100) {
          final year = regDtStr.substring(0, 4);
          final month = regDtStr.substring(4, 6);
          final day = regDtStr.substring(6, 8);
          return '$year.$month.$day';
        }
      }

      // 그 외의 경우 원본 문자열 반환
      return regDtStr;
    } catch (e) {
      // 파싱 실패 시 원본 문자열 반환
      return regDtStr;
    }
  }

  /// 위도 포맷팅
  String _formatLatitude(double? lat) {
    if (lat == null) return '-';
    final direction = lat >= 0 ? 'N' : 'S';
    return '${lat.abs().toStringAsFixed(5)}° $direction';
  }

  /// 경도 포맷팅
  String _formatLongitude(double? lng) {
    if (lng == null) return '-';
    final direction = lng >= 0 ? 'E' : 'W';
    return '${lng.abs().toStringAsFixed(5)}° $direction';
  }

  /// 예측항로 선
  Widget _buildPredRouteLine(List<LatLng> predRouteLine) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: predRouteLine,
          strokeWidth: 2.0, // 3.0의 2/3
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
