import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';

/// 지도 우측 하단 컨트롤 버튼들
class MapControlButtons extends StatelessWidget {
  final bool isOtherVesselsVisible;
  final VoidCallback onOtherVesselsToggle;
  final MapController mapController;
  final Function(BuildContext) onHomeButtonTap;

  const MapControlButtons({
    super.key,
    required this.isOtherVesselsVisible,
    required this.onOtherVesselsToggle,
    required this.mapController,
    required this.onHomeButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserState>().role;
    final mmsi = context.read<UserState>().mmsi ?? 0;
    final vessels = context.watch<VesselProvider>().vessels;

    return Positioned(
      right: getSize20().toDouble(),
      bottom: getSize100().toDouble(),
      child: Column(
        children: [
          // 관리자만 접근 가능한 다른 선박 표시 버튼
          if (role == 'ROLE_ADMIN') ...[
            CircularButton(
              svgPath: 'assets/kdn/home/img/bouttom_ship_img.svg',
              colorOn: getColorGrayType9(),
              colorOff: getColorGrayType8(),
              widthSize: getSize56(),
              heightSize: getSize56(),
              onTap: onOtherVesselsToggle,
            ),
            const SizedBox(height: DesignConstants.spacing12),
          ],

          // 현재 위치 버튼
          if (vessels.any((vessel) => vessel.mmsi == mmsi))
            Builder(
              builder: (context) {
                return CircularButton(
                  svgPath: 'assets/kdn/home/img/bouttom_location_img.svg',
                  colorOn: getColorGrayType8(),
                  colorOff: getColorGrayType8(),
                  widthSize: getSize56(),
                  heightSize: getSize56(),
                  onTap: () async {
                    final myVessel = vessels.firstWhere(
                          (vessel) => vessel.mmsi == mmsi,
                      orElse: () => vessels.first,
                    );

                    final vesselPoint = LatLng(
                      myVessel.lttd ?? 35.3790988,
                      myVessel.lntd ?? 126.167763,
                    );

                    mapController.move(
                        vesselPoint,
                        mapController.camera.zoom
                    );
                                    },
                );
              },
            ),
          const SizedBox(height: DesignConstants.spacing12),

          // 홈 버튼
          CircularButton(
            svgPath: 'assets/kdn/home/img/ico_home.svg',
            colorOn: getColorGrayType8(),
            colorOff: getColorGrayType8(),
            widthSize: getSize56(),
            heightSize: getSize56(),
            onTap: () => onHomeButtonTap(context),
          ),
        ],
      ),
    );
  }
}

/// 상단 파고/시정 버튼들 (StatefulWidget으로 변경)
class WeatherControlButtons extends StatefulWidget {
  const WeatherControlButtons({super.key});

  @override
  State<WeatherControlButtons> createState() => _WeatherControlButtonsState();
}

class _WeatherControlButtonsState extends State<WeatherControlButtons> {
  bool isWaveSelected = true;
  bool isVisibilitySelected = true;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: getSize56().toDouble(),
      left: getSize20().toDouble(),
      child: Consumer<NavigationProvider>(
        builder: (context, viewModel, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 파고 버튼
              buildCircularButtonSlideOn(
                'assets/kdn/home/img/top_pago_img.svg',
                viewModel.getWaveColor(viewModel.wave),
                getSize56(),
                getSize56(),
                '파고',
                getSize160(),
                viewModel.getFormattedWaveThresholdText(viewModel.wave),
                isSelected: isWaveSelected,
                onTap: () {
                  setState(() {
                    isWaveSelected = !isWaveSelected;
                  });
                },
              ),

              // 시정 버튼
              buildCircularButtonSlideOn(
                'assets/kdn/home/img/top_visibility_img.svg',
                viewModel.getVisibilityColor(viewModel.visibility),
                getSize56(),
                getSize56(),
                '시정',
                getSize160(),
                viewModel.getFormattedVisibilityThresholdText(viewModel.visibility),
                isSelected: isVisibilitySelected,
                onTap: () {
                  setState(() {
                    isVisibilitySelected = !isVisibilitySelected;
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}