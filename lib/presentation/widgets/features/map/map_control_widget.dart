import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';  // ✅ import 추가
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/screens/main/utils/vessel_focus_helper.dart';

/// 통합된 지도 컨트롤 위젯
class MapControlWidget extends StatelessWidget {
  final bool isOtherVesselsVisible;
  final bool isTrackingEnabled;
  final VoidCallback onOtherVesselsToggle;
  final VoidCallback? onTrackingToggle;
  final MapController mapController;
  final Function(BuildContext)? onHomeButtonTap;
  final bool useCustomStyle;  // true: CircularButton, false: Material Design

  const MapControlWidget({
    super.key,
    required this.isOtherVesselsVisible,
    required this.onOtherVesselsToggle,
    required this.mapController,
    this.isTrackingEnabled = false,
    this.onTrackingToggle,
    this.onHomeButtonTap,
    this.useCustomStyle = true,  // 기본값: 기존 스타일 유지
  });

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserState>().role;
    final mmsi = context.read<UserState>().mmsi ?? 0;
    // ✅ 타입 명시
    final List<VesselSearchModel> vessels = context.watch<VesselProvider>().vessels;

    return Positioned(
      right: getSize20(),
      bottom: getSize100(),
      child: Column(
        children: [
          // 관리자용 다른 선박 표시 버튼
          if (role == 'ROLE_ADMIN') ...[
            if (useCustomStyle)
              CircularButton(
                svgPath: 'assets/kdn/home/img/bouttom_ship_img.svg',
                colorOn: isOtherVesselsVisible ? getColorGrayType9() : getColorGrayType8(),
                colorOff: getColorGrayType8(),
                widthSize: getSizeInt56(),
                heightSize: getSizeInt56(),
                onTap: onOtherVesselsToggle,
              )
            else
              _buildMaterialButton(
                context: context,
                icon: Icons.directions_boat,
                onTap: onOtherVesselsToggle,
                isActive: isOtherVesselsVisible,
                tooltip: '다른 선박',
              ),
            SizedBox(height: getSize12()),
          ],

          // 현재 위치 버튼
          if (vessels.any((vessel) => vessel.mmsi == mmsi))
            if (useCustomStyle)
              CircularButton(
                svgPath: 'assets/kdn/home/img/bouttom_location_img.svg',
                colorOn: getColorGrayType8(),
                colorOff: getColorGrayType8(),
                widthSize: getSizeInt56(),
                heightSize: getSizeInt56(),
                onTap: () => _focusOnUserLocation(vessels, mmsi),
              )
            else
              _buildMaterialButton(
                context: context,
                icon: Icons.my_location,
                onTap: () => _focusOnUserLocation(vessels, mmsi),
                isActive: false,
                tooltip: '내 위치',
              ),

          if (vessels.any((vessel) => vessel.mmsi == mmsi))
            SizedBox(height: getSize12()),

          // 항적 표시 버튼 (옵션)
          if (onTrackingToggle != null) ...[
            if (useCustomStyle)
              CircularButton(
                svgPath: 'assets/kdn/home/img/ico_timeline.svg',  // 아이콘 경로 확인 필요
                colorOn: isTrackingEnabled ? getColorGrayType9() : getColorGrayType8(),
                colorOff: getColorGrayType8(),
                widthSize: getSizeInt56(),
                heightSize: getSizeInt56(),
                onTap: onTrackingToggle!,
              )
            else
              _buildMaterialButton(
                context: context,
                icon: Icons.timeline,
                onTap: onTrackingToggle!,
                isActive: isTrackingEnabled,
                tooltip: '항적 표시',
              ),
            SizedBox(height: getSize12()),
          ],

          // 홈 버튼 (옵션)
          if (onHomeButtonTap != null)
            if (useCustomStyle)
              CircularButton(
                svgPath: 'assets/kdn/home/img/ico_home.svg',
                colorOn: getColorGrayType8(),
                colorOff: getColorGrayType8(),
                widthSize: getSizeInt56(),
                heightSize: getSizeInt56(),
                onTap: () => onHomeButtonTap!(context),
              )
            else
              _buildMaterialButton(
                context: context,
                icon: Icons.home,
                onTap: () => onHomeButtonTap!(context),
                isActive: false,
                tooltip: '홈',
              ),
        ],
      ),
    );
  }

  // Material Design 스타일 버튼
  Widget _buildMaterialButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: getSize56(),
        height: getSize56(),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(getSize28()),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: isActive ? Colors.white : getColorGrayType7(),
            size: getSize24(),
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  // ✅ 타입 수정: List<VesselSearchModel>로 명시
  void _focusOnUserLocation(List<VesselSearchModel> vessels, int mmsi) {
    VesselFocusHelper.focusOnUserVessel(
      mapController: mapController,
      vessels: vessels,
      userMmsi: mmsi,
      zoom: 13.0,
    );
  }
}

// ✅ 기존 MapControlButtons 별칭 (하위 호환성)
@Deprecated('Use MapControlWidget instead')
class MapControlButtons extends MapControlWidget {
  const MapControlButtons({
    super.key,
    required super.isOtherVesselsVisible,
    required super.onOtherVesselsToggle,
    required super.mapController,
    VoidCallback? onCenterLocation,
    super.onHomeButtonTap,
  }) : super(
    useCustomStyle: true,
  );
}