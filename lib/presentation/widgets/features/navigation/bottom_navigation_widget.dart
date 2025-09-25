import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 하단 네비게이션 바 위젯 (통합 버전)
/// MainBottomNavigation과 BottomNavigationWidget을 통합
class BottomNavigationWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int, BuildContext) onItemTapped;
  final bool showEmergencyTab;  // 긴급신고 탭 표시 여부

  const BottomNavigationWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.showEmergencyTab = true,  // 기본값: 긴급신고 탭 표시
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
      child: SafeArea(
        top: false,
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
    // 색상 결정
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
              // 아이콘
              SizedBox(
                width: getSize24().toDouble(),
                height: getSize24().toDouble(),
                child: _buildIcon(
                  iconPath: isSelected ? iconOn : iconOff,
                  iconColor: iconColor,
                  isEmergency: isEmergency,
                ),
              ),
              SizedBox(height: getSize4().toDouble()),
              // 라벨
              Text(
                label,
                style: TextStyle(
                  fontSize: getSize12().toDouble(),
                  fontWeight: isSelected ? getText700() : getText500(),
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
      // 긴급신고 아이콘은 색상 필터 적용
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
      // 일반 아이콘
      return SvgPicture.asset(
        iconPath,
        fit: BoxFit.contain,
      );
    }
  }

  /// 아이템 색상 결정
  Color _getItemColor(bool isSelected, bool isEmergency, bool isIcon) {
    if (isEmergency) {
      // 긴급신고 탭은 빨간색 계열
      return isSelected
          ? getColorEmergencyRed()
          : getColorEmergencyRed400();
    } else {
      // 다른 탭들은 기존 색상
      return isSelected
          ? getColorGrayType8()
          : getColorGrayType2();
    }
  }
}

/// 간단한 버전의 하단 네비게이션 바 (기본 Flutter 위젯 사용)
/// 필요시 사용할 수 있는 대체 구현
class SimpleBottomNavigationWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const SimpleBottomNavigationWidget({
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

  BottomNavigationBarItem _buildNavItem(
      int index,
      String iconName,
      String label,
      ) {
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
              child: SvgPicture.asset(
                iconPath,
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