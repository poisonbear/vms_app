import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/screens/main/utils/vessel_focus_helper.dart';

/// 지도 우측 하단 컨트롤 버튼들 (리팩토링)
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

          // 현재 위치 버튼 - VesselFocusHelper 사용
          if (vessels.any((vessel) => vessel.mmsi == mmsi))
            CircularButton(
              svgPath: 'assets/kdn/home/img/bouttom_location_img.svg',
              colorOn: getColorGrayType8(),
              colorOff: getColorGrayType8(),
              widthSize: getSize56(),
              heightSize: getSize56(),
              onTap: () {
                // VesselFocusHelper 사용으로 간소화
                VesselFocusHelper.focusOnUserVessel(
                  mapController: mapController,
                  vessels: vessels,
                  userMmsi: mmsi,
                  zoom: 13.0,
                );
              },
            ),
        ],
      ),
    );
  }
}
