// lib/presentation/widgets/features/navigation/bottom_navigation_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vms_app/core/constants/constants.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int, BuildContext) onItemTapped;
  final bool showEmergencyTab;

  const BottomNavigationWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.showEmergencyTab = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero, //마진 제거
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.grayType4,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false, //상단 SafeArea 비활성화
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildNavigationItems(context),
          ),
        ),
      ),
    );
  }

  /// 네비게이션 아이템 목록 생성
  List<Widget> _buildNavigationItems(BuildContext context) {
    final List<Widget> items = [];

    // 긴급신고 탭 (조건부 표시)
    if (showEmergencyTab) {
      items.add(
        _buildCustomNavItem(
          context: context,
          index: 0,
          iconOn: 'assets/kdn/home/img/ico_emergency_on.svg',
          iconOff: 'assets/kdn/home/img/ico_emergency_off.svg',
          label: '긴급신고',
          isSelected: selectedIndex == 0,
          isEmergency: true,
          onTap: onItemTapped,
        ),
      );
    } else {
      // 긴급신고 대신 홈 탭 표시
      items.add(
        _buildCustomNavItem(
          context: context,
          index: 0,
          iconOn: 'assets/kdn/ros/img/Home_on.svg',
          iconOff: 'assets/kdn/ros/img/Home_off.svg',
          label: '홈',
          isSelected: selectedIndex == 0,
          isEmergency: false,
          onTap: onItemTapped,
        ),
      );
    }

    // 기상정보 탭
    items.add(
      _buildCustomNavItem(
        context: context,
        index: 1,
        iconOn: 'assets/kdn/ros/img/cloud-sun_on.svg',
        iconOff: 'assets/kdn/ros/img/cloud-sun_off.svg',
        label: '기상정보',
        isSelected: selectedIndex == 1,
        isEmergency: false,
        onTap: onItemTapped,
      ),
    );

    // 항행이력 탭
    items.add(
      _buildCustomNavItem(
        context: context,
        index: 2,
        iconOn: 'assets/kdn/ros/img/ship_on.svg',
        iconOff: 'assets/kdn/ros/img/ship_off.svg',
        label: '항행이력',
        isSelected: selectedIndex == 2,
        isEmergency: false,
        onTap: onItemTapped,
      ),
    );

    // 내정보/마이 탭
    items.add(
      _buildCustomNavItem(
        context: context,
        index: 3,
        iconOn: 'assets/kdn/ros/img/user-alt-1_on.svg',
        iconOff: 'assets/kdn/ros/img/user-alt-1_off.svg',
        label: '내정보',
        isSelected: selectedIndex == 3,
        isEmergency: false,
        onTap: onItemTapped,
      ),
    );

    return items;
  }

  /// 커스텀 네비게이션 아이템 빌더
  Widget _buildCustomNavItem({
    required BuildContext context,
    required int index,
    required String iconOn,
    required String iconOff,
    required String label,
    required bool isSelected,
    required bool isEmergency,
    required Function(int, BuildContext) onTap,
  }) {
    final Color iconColor = _getItemColor(isSelected, isEmergency, true);
    final Color textColor = _getItemColor(isSelected, isEmergency, false);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index, context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: AppSizes.s24.toDouble(),
                height: AppSizes.s24.toDouble(),
                child: _buildIcon(
                  iconPath: isSelected ? iconOn : iconOff,
                  iconColor: iconColor,
                  isEmergency: isEmergency,
                ),
              ),
              SizedBox(height: AppSizes.s4.toDouble()),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.s12.toDouble(),
                  fontWeight: isSelected ? FontWeights.w700 : FontWeights.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 아이콘 위젯 생성
  Widget _buildIcon({
    required String iconPath,
    required Color iconColor,
    required bool isEmergency,
  }) {
    if (isEmergency) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          iconColor,
          BlendMode.srcIn,
        ),
        child: SvgPicture.asset(
          iconPath,
          fit: BoxFit.contain,
        ),
      );
    } else {
      return SvgPicture.asset(
        iconPath,
        fit: BoxFit.contain,
      );
    }
  }

  /// 아이템 색상 결정
  Color _getItemColor(bool isSelected, bool isEmergency, bool isIcon) {
    if (isEmergency) {
      return isSelected ? AppColors.emergencyRed : AppColors.emergencyRed400;
    } else {
      return isSelected ? AppColors.grayType8 : AppColors.grayType2;
    }
  }
}
