// lib/features/main/widgets/main_drawer.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';

/// 메인 화면의 사이드 드로어
class MainDrawer extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;

  const MainDrawer({
    super.key,
    required this.username,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // 헤더
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.sky3,
                  AppColors.sky2,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.sky3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'VMS 사용자',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 메뉴 항목들
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: '대시보드',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('대시보드 기능 준비중입니다.')),
                    );
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.sailing_outlined,
                  title: '내 선박',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('내 선박 기능 준비중입니다.')),
                    );
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.route_outlined,
                  title: '항로 관리',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('항로 관리 기능 준비중입니다.')),
                    );
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: '분석 리포트',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('분석 리포트 기능 준비중입니다.')),
                    );
                  },
                ),

                const Divider(),

                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: '설정',
                  onTap: () {
                    Navigator.pop(context);
                    _showSettingsDialog(context);
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline,
                  title: '도움말',
                  onTap: () {
                    Navigator.pop(context);
                    _showHelpDialog(context);
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline,
                  title: '앱 정보',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),

          // 하단 로그아웃 버튼
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.red1),
                  title: const Text(
                    '로그아웃',
                    style: TextStyle(
                      color: AppColors.red1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 드로어 아이템 빌드
  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        bool isSelected = false,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.sky3 : AppColors.gray3,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.sky3 : AppColors.black2,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: AppColors.sky1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 설정 다이얼로그 표시
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('알림 설정'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 설정 기능 준비중입니다.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('언어 설정'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('언어 설정 기능 준비중입니다.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text('보안 설정'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('보안 설정 기능 준비중입니다.')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 도움말 다이얼로그 표시
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('도움말'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VMS (Vessel Management System)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('선박 관리 시스템 사용법:'),
              SizedBox(height: 8),
              Text('1. 지도 탭: 선박의 실시간 위치를 확인할 수 있습니다.'),
              SizedBox(height: 4),
              Text('2. 항행정보 탭: 항행경보 및 이력을 조회할 수 있습니다.'),
              SizedBox(height: 4),
              Text('3. 기상정보 탭: 실시간 기상 정보를 확인할 수 있습니다.'),
              SizedBox(height: 8),
              Text(
                '문의사항이 있으시면 관리자에게 연락주세요.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 앱 정보 다이얼로그 표시
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'VMS',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.sky3,
        ),
        child: const Icon(
          Icons.sailing,
          size: 30,
          color: Colors.white,
        ),
      ),
      children: const [
        Text('Vessel Management System'),
        SizedBox(height: 8),
        Text('선박 관리 및 모니터링을 위한 통합 플랫폼입니다.'),
        SizedBox(height: 8),
        Text('© 2024 VMS Development Team'),
      ],
    );
  }
}