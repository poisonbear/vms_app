// lib/features/main/views/main_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/error/error_reporter.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../vessel/cubit/vessel_cubit.dart';
import '../../navigation/cubit/navigation_cubit.dart';
import '../../auth/views/login_view.dart';
import '../widgets/main_drawer.dart';
import '../widgets/vessel_map_widget.dart';
import '../widgets/navigation_info_widget.dart';
import '../widgets/weather_info_widget.dart';

/// 메인 화면
class MainView extends StatefulWidget {
  final String username;

  const MainView({
    super.key,
    required this.username,
  });

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 초기 데이터 로드
  Future<void> _initializeData() async {
    try {
      // 선박 목록 로드
      context.read<VesselCubit>().loadVesselList();

      // 날씨 정보 로드
      context.read<NavigationCubit>().loadWeatherInfo();

      // 항행 경보 로드
      context.read<NavigationCubit>().loadNavigationWarnings();
    } catch (e) {
      if (mounted) {
        ErrorReporter.reportError(context, e);
      }
    }
  }

  /// 로그아웃 처리
  Future<void> _performLogout() async {
    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.logout();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorReporter.reportError(context, e);
      }
    }
  }

  /// 확인 다이얼로그 표시
  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('VMS'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        actions: [
          // 알림 버튼
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 알림 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 기능 준비중입니다.')),
              );
            },
          ),

          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeData,
          ),
        ],
      ),
      drawer: MainDrawer(
        username: widget.username,
        onLogout: () async {
          final confirmed = await _showConfirmDialog(
            '로그아웃',
            '정말 로그아웃 하시겠습니까?',
          );
          if (confirmed) {
            _performLogout();
          }
        },
      ),
      body: Column(
        children: [
          // 탭 바
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelColor: AppColors.sky3,
              unselectedLabelColor: AppColors.gray2,
              indicatorColor: AppColors.sky3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.map_outlined),
                  text: '지도',
                ),
                Tab(
                  icon: Icon(Icons.directions_boat_outlined),
                  text: '항행정보',
                ),
                Tab(
                  icon: Icon(Icons.cloud_outlined),
                  text: '기상정보',
                ),
              ],
            ),
          ),

          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                // 지도 탭
                VesselMapWidget(),

                // 항행정보 탭
                NavigationInfoWidget(),

                // 기상정보 탭
                WeatherInfoWidget(),
              ],
            ),
          ),
        ],
      ),

      // 플로팅 액션 버튼
      floatingActionButton: _currentIndex == 0 // 지도 탭에서만 표시
          ? FloatingActionButton(
        onPressed: () {
          // 내 위치로 이동 또는 선박 검색
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 기능 준비중입니다.')),
          );
        },
        backgroundColor: AppColors.sky3,
        child: const Icon(Icons.my_location, color: Colors.white),
      )
          : null,
    );
  }
}