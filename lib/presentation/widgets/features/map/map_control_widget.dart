import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/route_provider.dart';
import 'package:vms_app/presentation/screens/main/controllers/main_screen_controller.dart';
import 'package:vms_app/presentation/screens/main/utils/vessel_focus_helper.dart';

/// 통합된 지도 컨트롤 위젯
class MapControlWidget extends StatelessWidget {
  final bool isOtherVesselsVisible;
  final bool isTrackingEnabled;
  final VoidCallback onOtherVesselsToggle;
  final VoidCallback? onTrackingToggle;
  final MapController mapController;
  final Function(BuildContext)? onHomeButtonTap;
  final bool useCustomStyle; // true: CircularButton, false: Material Design

  const MapControlWidget({
    super.key,
    required this.isOtherVesselsVisible,
    required this.onOtherVesselsToggle,
    required this.mapController,
    this.isTrackingEnabled = false,
    this.onTrackingToggle,
    this.onHomeButtonTap,
    this.useCustomStyle = true, // 기본값: 기존 스타일 유지
  });

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserState>().role;
    final mmsi = context.read<UserState>().mmsi ?? 0;
    //타입 명시
    final List<VesselSearchModel> vessels =
        context.watch<VesselProvider>().vessels;

    // MainScreenController와 RouteSearchProvider 가져오기
    final controller = context.watch<MainScreenController?>();
    final routeViewModel = context.watch<RouteProvider?>();

    return Positioned(
      right: AppSizes.s20,
      bottom: AppSizes.s20,
      child: Column(
        children: [
          // ✨ NEW: 항적초기화(Refresh) 버튼 - 최상단에 위치
          if (controller != null && routeViewModel != null)
            if ((routeViewModel.pastRoutes.isNotEmpty == true ||
                    routeViewModel.predRoutes.isNotEmpty == true) &&
                routeViewModel.isNavigationHistoryMode != true &&
                controller.isTrackingEnabled) ...[
              if (useCustomStyle)
                CircularButton(
                  svgPath: 'assets/kdn/home/img/refresh.svg',
                  colorOn: AppColors.grayType8,
                  colorOff: AppColors.grayType8,
                  widthSize: AppSizes.i56,
                  heightSize: AppSizes.i56,
                  onTap: () {
                    controller.stopTracking();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('항적 데이터가 초기화되었습니다.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                )
              else
                _buildMaterialButton(
                  context: context,
                  icon: Icons.refresh,
                  onTap: () {
                    controller.stopTracking();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('항적 데이터가 초기화되었습니다.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  isActive: false,
                  tooltip: '항적 초기화',
                ),
              const SizedBox(height: AppSizes.s12),
            ],

          // 관리자용 다른 선박 표시 버튼
          if (role == 'ROLE_ADMIN' || role == 'ROLE_OPER') ...[
            if (useCustomStyle)
              CircularButton(
                svgPath: 'assets/kdn/home/img/bouttom_ship_img.svg',
                colorOn: isOtherVesselsVisible
                    ? AppColors.grayType9
                    : AppColors.grayType8,
                colorOff: AppColors.grayType8,
                widthSize: AppSizes.i56,
                heightSize: AppSizes.i56,
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
            const SizedBox(height: AppSizes.s12),
          ],

          // 현재 위치 버튼
          if (vessels.any((vessel) => vessel.mmsi == mmsi))
            if (useCustomStyle)
              CircularButton(
                svgPath: 'assets/kdn/home/img/bouttom_location_img.svg',
                colorOn: AppColors.grayType8,
                colorOff: AppColors.grayType8,
                widthSize: AppSizes.i56,
                heightSize: AppSizes.i56,
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
            const SizedBox(height: AppSizes.s12),

          // 항적 표시 버튼 (옵션)
          if (onTrackingToggle != null) ...[
            if (useCustomStyle)
              CircularButton(
                svgPath: 'assets/kdn/home/img/ico_timeline.svg', // 아이콘 경로 확인 필요
                colorOn: isTrackingEnabled
                    ? AppColors.grayType9
                    : AppColors.grayType8,
                colorOff: AppColors.grayType8,
                widthSize: AppSizes.i56,
                heightSize: AppSizes.i56,
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
            const SizedBox(height: AppSizes.s12),
          ],

          // 홈 버튼 (옵션)
          if (onHomeButtonTap != null)
            if (useCustomStyle)
              CircularButton(
                svgPath: 'assets/kdn/home/img/ico_home.svg',
                colorOn: AppColors.grayType8,
                colorOff: AppColors.grayType8,
                widthSize: AppSizes.i56,
                heightSize: AppSizes.i56,
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
        width: AppSizes.s56,
        height: AppSizes.s56,
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.s28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: isActive ? Colors.white : AppColors.grayType7,
            size: AppSizes.s24,
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  //타입 수정: List<VesselSearchModel>로 명시
  void _focusOnUserLocation(List<VesselSearchModel> vessels, int mmsi) {
    VesselFocusHelper.focusOnUserVessel(
      mapController: mapController,
      vessels: vessels,
      userMmsi: mmsi,
      zoom: 13.0,
    );
  }
}

//기존 MapControlButtons 별칭 (하위 호환성)
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
