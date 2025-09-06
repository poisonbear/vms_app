#!/bin/bash

echo "🔧 1단계: BottomNavigationBar 위젯 분리 시작..."
echo ""

# 1. bottom_navigation.dart 파일 생성
echo "📝 Creating widgets/bottom_navigation.dart..."
cat > lib/presentation/screens/main/widgets/bottom_navigation.dart << 'EOF'
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
            color: getColorgray_Type4(),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: getColorgray_Type8(),
        unselectedItemColor: getColorgray_Type2(),
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
            iconOn: 'assets/kdn/ros/img/Home_on.svg',
            iconOff: 'assets/kdn/ros/img/Home_off.svg',
            label: '홈',
            isSelected: selectedIndex == 0,
          ),
          _buildNavItem(
            iconOn: 'assets/kdn/ros/img/Ship_on.svg',
            iconOff: 'assets/kdn/ros/img/Ship_off.svg',
            label: '항로추천',
            isSelected: selectedIndex == 1,
          ),
          _buildNavItem(
            iconOn: 'assets/kdn/ros/img/Wether_on.svg',
            iconOff: 'assets/kdn/ros/img/Wether_off.svg',
            label: '날씨',
            isSelected: selectedIndex == 2,
          ),
          _buildNavItem(
            iconOn: 'assets/kdn/ros/img/Person_on.svg',
            iconOff: 'assets/kdn/ros/img/Person_off.svg',
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
EOF

echo "✅ bottom_navigation.dart 생성 완료!"
echo ""

# 2. main_screen.dart 수정 스크립트 생성
echo "📝 Creating modification script..."
cat > modify_main_screen_step1.dart << 'EOF'
// main_screen.dart 수정 가이드

// 1. 상단에 import 추가:
import 'widgets/bottom_navigation.dart';

// 2. build 메서드의 bottomNavigationBar 부분을 다음으로 교체:
/*
기존 코드:
bottomNavigationBar: Container(
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border(
      top: BorderSide(color: getColorgray_Type4(), width: 1),
    ),
  ),
  child: Builder(
    builder: (context) => BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      // ... 긴 코드 ...
      items: <BottomNavigationBarItem>[
        // ... 아이템들 ...
      ],
    ),
  ),
),

새 코드:
bottomNavigationBar: MainBottomNavigation(
  selectedIndex: selectedIndex,
  onItemTapped: _onItemTapped,
),
*/

// 3. _onItemTapped 메서드 확인 (수정 필요 없음):
void _onItemTapped(int index, BuildContext context) {
  setState(() {
    selectedIndex = index;
  });
  
  // 기존 로직 유지
  if (index == 0) {
    // 홈 화면 처리
  } else if (index == 1) {
    // 항로추천 화면 처리
  } else if (index == 2) {
    // 날씨 화면 처리
  } else if (index == 3) {
    // 내정보 화면 처리
  }
}
EOF

echo "📋 수정 가이드 생성 완료!"
echo ""
echo "======================================"
echo "📌 1단계 작업 요약"
echo "======================================"
echo ""
echo "✅ 생성된 파일:"
echo "   - lib/presentation/screens/main/widgets/bottom_navigation.dart"
echo ""
echo "📝 main_screen.dart 수정 방법:"
echo ""
echo "1. import 추가:"
echo "   import 'widgets/bottom_navigation.dart';"
echo ""
echo "2. bottomNavigationBar 교체:"
echo "   기존: Container(... BottomNavigationBar(...))"
echo "   신규: MainBottomNavigation("
echo "          selectedIndex: selectedIndex,"
echo "          onItemTapped: _onItemTapped,"
echo "        )"
echo ""
echo "3. 네비게이션 탭 정보:"
echo "   - 홈 (Home_on/off.svg)"
echo "   - 기상정보 (cloud-sun_on/off.svg)"
echo "   - 항행이력 (ship_on/off.svg)"
echo "   - 마이 (user-alt-1_on/off.svg)"
echo ""
echo "4. 테스트:"
echo "   - flutter analyze"
echo "   - 앱 실행하여 하단 네비게이션 동작 확인"
echo ""
echo "⚠️  주의: _onItemTapped 메서드는 그대로 유지"
echo ""
echo "======================================"
echo "다음 단계로 진행하시려면 테스트 후 알려주세요!"
echo "======================================"
