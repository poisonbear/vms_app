import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 하단 네비게이션바 위젯
class BottomNavigationWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigationWidget({
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
          top: BorderSide(color: getColorGrayType4(), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: getColorGrayType8(),
        unselectedItemColor: getColorGrayType2(),
        selectedLabelStyle: TextStyle(fontSize: getSize16().toDouble(), fontWeight: getText700()),
        unselectedLabelStyle: TextStyle(fontSize: getSize16().toDouble(), fontWeight: getText700()),
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        items: [
          _buildNavItem(0, 'Home', '홈'),
          _buildNavItem(1, 'cloud-sun', '기상정보'),
          _buildNavItem(2, 'ship', '항행이력'),
          _buildNavItem(3, 'user-alt-1', '마이'),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(int index, String iconName, String label) {
    final isSelected = selectedIndex == index;
    final iconPath = 'assets/kdn/ros/img/${iconName}_${isSelected ? 'on' : 'off'}.svg';

    return BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.only(bottom: getSize8().toDouble()),
        child: Column(
          children: [
            SizedBox(height: getSize12().toDouble()),
            SizedBox(
              width: getSize24().toDouble(),
              height: getSize24().toDouble(),
              child: SvgPicture.asset(iconPath, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}
