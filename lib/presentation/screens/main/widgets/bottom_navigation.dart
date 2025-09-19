import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 메인 화면 하단 네비게이션 바
class MainBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int, BuildContext) onItemTapped;

  const MainBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: getColorGrayType4(),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: getColorGrayType8(),
        unselectedItemColor: getColorGrayType2(),
        selectedLabelStyle: TextStyle(
          fontSize: getSize16().toDouble(),
          fontWeight: getText700(),
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: getSize16().toDouble(),
          fontWeight: getText700(),
        ),
        currentIndex: selectedIndex,
        onTap: (index) => onItemTapped(index, context),
        items: <BottomNavigationBarItem>[
          _buildNavItem(
            iconOn: 'assets/kdn/home/img/ico_emergency_on.svg',
            iconOff: 'assets/kdn/home/img/ico_emergency_off.svg',
            label: '긴급신고',
            isSelected: selectedIndex == 0,
          ),
          _buildNavItem(
            iconOn: 'assets/kdn/ros/img/cloud-sun_on.svg',
            iconOff: 'assets/kdn/ros/img/cloud-sun_off.svg',
            label: '기상정보',
            isSelected: selectedIndex == 1,
          ),
          _buildNavItem(
            iconOn: 'assets/kdn/ros/img/ship_on.svg',
            iconOff: 'assets/kdn/ros/img/ship_off.svg',
            label: '항행이력',
            isSelected: selectedIndex == 2,
          ),
          _buildNavItem(
            iconOn: 'assets/kdn/ros/img/user-alt-1_on.svg',
            iconOff: 'assets/kdn/ros/img/user-alt-1_off.svg',
            label: '내정보',
            isSelected: selectedIndex == 3,
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required String iconOn,
    required String iconOff,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.only(bottom: getSize8().toDouble()),
        child: Column(
          children: [
            SizedBox(height: getSize12().toDouble()),
            SizedBox(
              width: getSize24().toDouble(),
              height: getSize24().toDouble(),
              child: SvgPicture.asset(
                isSelected ? iconOn : iconOff,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}
