import 'package:flutter/material.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String userRole;
  
  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userRole,
  });
  
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: onTap,
      items: _buildNavigationItems(),
    );
  }
  
  List<BottomNavigationBarItem> _buildNavigationItems() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.map),
        label: '지도',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.cloud),
        label: '날씨',
      ),
    ];
    
    if (userRole == 'ROLE_ADMIN') {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.directions_boat),
          label: '선박관리',
        ),
      );
    }
    
    items.addAll([
      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: '항적',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: '프로필',
      ),
    ]);
    
    return items;
  }
}
