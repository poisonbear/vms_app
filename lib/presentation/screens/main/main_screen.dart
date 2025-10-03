import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/providers/route_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/screens/main/tabs/navigation_tab.dart';
import 'package:vms_app/presentation/screens/main/tabs/weather_tab.dart';
import 'package:vms_app/presentation/screens/main/tabs/emergency_tab.dart';
import 'package:vms_app/presentation/screens/profile/profile_screen.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:vms_app/core/utils/utils.dart';
import 'package:latlong2/latlong.dart';

// Helpers and Utils
import 'utils/vessel_focus_helper.dart';
import 'utils/navigation_utils.dart';
import 'utils/navigation_debug.dart';

// Controllers and Services
import 'controllers/main_screen_controller.dart';
import 'services/fcm_service.dart';
import 'services/location_service_manager.dart';
import 'services/vessel_data_manager.dart';

class MainScreen extends StatefulWidget {
  final String username;
  final RouteProvider? routeSearchViewModel;
  final int initTabIndex;
  final bool autoFocusLocation;

  const MainScreen({
    super.key,
    required this.username,
    this.routeSearchViewModel,
    this.initTabIndex = 0,
    this.autoFocusLocation = false,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // Controllers & Services
  late MainScreenController _controller;
  late FCMService _fcmService;
  late LocationServiceManager _locationManager;
  late VesselDataManager _vesselDataManager;

  // UI Controllers
  late AnimationController _flashController;
  PersistentBottomSheetController? _bottomSheetController;

  // MapControllerProvider 인스턴스
  late MapControllerProvider _mapControllerProvider;

  // Local UI State
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  int selectedIndex = -1;

  // 로딩 상태 관리 변수
  bool _isLoadingRoute = false;

  // FCM 관련 상태
  bool showEmergencyMessage = false;
  String emergencyMessage = '';

  @override
  void initState() {
    super.initState();

    // 컨트롤러 초기화
    _controller = MainScreenController(
      routeSearchViewModel: widget.routeSearchViewModel,
    );

    // MapControllerProvider 인스턴스 생성
    _mapControllerProvider = MapControllerProvider();

    // 서비스 초기화
    _locationManager = LocationServiceManager();
    _vesselDataManager = VesselDataManager();

    // FCM 서비스 초기화
    _fcmService = FCMService(
      flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
      popupService: _controller.popupService,
      onStartFlashing: () {
        _controller.startFlashing();
        _flashController.forward();
      },
      onStopFlashing: () {
        _controller.stopFlashing();
        if (_flashController.isAnimating) {
          _flashController.stop();
        }
      },
    );

    // 초기 인덱스 설정 (기본적으로 지도 표시를 위해 -1로 설정)
    selectedIndex = -1;  // 지도만 표시 (바텀시트 없음)
    _controller.setSelectedIndex(-1);

    // 애니메이션 컨트롤러 초기화
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_controller.isFlashing) {
          _flashController.forward();
        }
      }
    });

    // 초기화 작업들
    _initializeServices();
  }

  /// 서비스 초기화
  Future<void> _initializeServices() async {
    // FCM 토큰 초기화
    await _fcmService.initializeToken();

    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 선박 데이터 로드
      await _vesselDataManager.loadVesselDataAndUpdateMap(context);

      // 선박 업데이트 타이머 시작
      _controller.timerService.startPeriodicTimer(
        "vessel_update",
        const Duration(seconds: 2),
            () {
          if (!mounted) return;
          _vesselDataManager.loadVesselDataAndUpdateMap(context);
        },
      );

      // FCM 리스너 등록
      _fcmService.registerFCMListener(context);

      // 위치 권한 요청
      Future.delayed(const Duration(seconds: 300), () {
        _requestPermissionsSequentially();
      });

      // 자동 위치 포커스
      if (widget.autoFocusLocation) {
        AppLogger.d('========================================');
        AppLogger.d('🚀 자동 포커스 활성화: ${widget.autoFocusLocation}');
        AppLogger.d('👤 사용자: ${widget.username}');
        AppLogger.d('========================================');

        Future.delayed(const Duration(milliseconds: 500), () {
          _performAutoFocus();
        });
      }
    });

    // 날씨 정보 초기화
    Provider.of<NavigationProvider>(context, listen: false).getWeatherInfo();

    // 날씨 업데이트 타이머
    _controller.timerService.startPeriodicTimer(
      "main_timer",
      const Duration(seconds: 2),
          () {
        Provider.of<NavigationProvider>(context, listen: false)
            .getWeatherInfo()
            .then((_) {
          if (mounted) setState(() {});
        }).catchError((error) {});
      },
    );

    // 항행 경보 가져오기
    Provider.of<NavigationProvider>(context, listen: false)
        .getNavigationWarnings();
  }

  /// 위치 권한 요청
  Future<void> _requestPermissionsSequentially() async {
    // 위치 권한
    bool locationGranted = await _locationManager.checkAndRequestLocationPermission();
    if (locationGranted) {
      final location = await _locationManager.getCurrentLocation();
      if (location != null) {
        _controller.updateCurrentPosition(location);
      }
    } else {
      await Future.delayed(const Duration(seconds: 60));
      await PointRequestUtil.requestPermissionUntilGranted(context);
      final location = await _locationManager.getCurrentLocation();
      if (location != null) {
        _controller.updateCurrentPosition(location);
      }
    }

    // 알림 권한
    NotificationSettings notifSettings =
    await FirebaseMessaging.instance.getNotificationSettings();
    if (notifSettings.authorizationStatus != AuthorizationStatus.authorized &&
        notifSettings.authorizationStatus != AuthorizationStatus.provisional) {
      await FirebaseMessaging.instance.requestPermission();
    }
  }

  /// 자동 포커스 수행
  Future<void> _performAutoFocus() async {
    try {
      final userMmsi = context.read<UserState>().mmsi;
      if (userMmsi == null || userMmsi == 0) {
        AppLogger.w('사용자 MMSI가 없어 자동 포커스를 건너뜁니다');
        return;
      }

      final vesselProvider = context.read<VesselProvider>();

      if (vesselProvider.vessels.isEmpty) {
        await vesselProvider.getVesselList();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!mounted) return;

      VesselFocusHelper.focusOnUserVessel(
        mapController: _controller.mapController,
        vessels: vesselProvider.vessels,
        userMmsi: userMmsi,
        zoom: 13.0,
      );

      AppLogger.i('✅ 로그인 후 자동 포커스 완료 (MMSI: $userMmsi)');
    } catch (e) {
      AppLogger.e('자동 포커스 실패: $e');
    }
  }

  void routePop(BuildContext context, VesselSearchModel vessel) {
    _showVesselInfoDialog(context, vessel);
  }

  void _showVesselInfoDialog(BuildContext context, VesselSearchModel vessel) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignConstants.radiusXL),
          ),
          backgroundColor: const Color(0xFFF5F5F5),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더 영역
                Container(
                  padding: EdgeInsets.all(AppSizes.s20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(DesignConstants.radiusXL),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_boat,
                        color: AppColors.skyType2,
                        size: AppSizes.s28,
                      ),
                      SizedBox(width: AppSizes.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vessel.ship_nm ?? '선박명 없음',
                              style: TextStyle(
                                fontSize: AppSizes.s18,
                                fontWeight: FontWeights.w700,
                                color: AppColors.blackType2,
                              ),
                            ),
                            Text(
                              'MMSI: ${vessel.mmsi ?? 0}',
                              style: TextStyle(
                                fontSize: AppSizes.s14,
                                color: AppColors.grayType3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 본문 영역
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AppSizes.s20),
                    child: Column(
                      children: [
                        _buildInfoRow('위치', '${vessel.lttd?.toStringAsFixed(6) ?? '-'}, ${vessel.lntd?.toStringAsFixed(6) ?? '-'}'),
                        _buildInfoRow('속도', vessel.sog != null ? '${vessel.sog!.toStringAsFixed(1)} knots' : '-'),
                        _buildInfoRow('침로', vessel.cog != null ? '${vessel.cog!.toStringAsFixed(1)}°' : '-'),
                        _buildInfoRow('선종', vessel.ship_knd ?? '-'),
                        _buildInfoRow('흘수', vessel.draft != null ? '${vessel.draft!.toStringAsFixed(1)} m' : '-'),
                      ],
                    ),
                  ),
                ),

                // 버튼 영역 - 하단 고정
                Container(
                  padding: EdgeInsets.all(AppSizes.s16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.grayType4,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                          child: Container(
                            height: AppSizes.s44,
                            decoration: BoxDecoration(
                              color: AppColors.grayType4,
                              borderRadius: BorderRadius.circular(AppSizes.s8),
                            ),
                            child: Center(
                              child: TextWidgetString(
                                '닫기',
                                TextAligns.center,
                                AppSizes.i14,
                                FontWeights.w600,
                                AppColors.grayType7,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.s12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(dialogContext).pop();

                            // 선박 트래킹 시작
                            _controller.startTracking(vessel.mmsi ?? 0);

                            // 선박 위치로 지도 이동
                            if (vessel.lttd != null && vessel.lntd != null) {
                              final vesselLocation = LatLng(vessel.lttd!, vessel.lntd!);
                              _controller.mapController.move(vesselLocation, 13.0);
                            }

                            // 당일 항적 자동 조회
                            _loadTodayRoute(vessel.mmsi ?? 0);
                          },
                          child: Container(
                            height: AppSizes.s44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.skyType2,
                                  AppColors.skyType1,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppSizes.s8),
                            ),
                            child: Center(
                              child: TextWidgetString(
                                '항적보기',
                                TextAligns.center,
                                AppSizes.i14,
                                FontWeights.w600,
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.s80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.s14,
                color: AppColors.grayType3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.s14,
                fontWeight: FontWeights.w600,
                color: AppColors.blackType2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 당일 항적 조회
  Future<void> _loadTodayRoute(int mmsi) async {
    if (_isLoadingRoute) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final today = DateTime.now();
      final dateStr = "${today.year.toString().padLeft(4, '0')}-"
          "${today.month.toString().padLeft(2, '0')}-"
          "${today.day.toString().padLeft(2, '0')}";

      await _controller.routeSearchViewModel.getVesselRoute(
        regDt: dateStr,
        mmsi: mmsi,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  // 당일 항적보기 버튼 빌드
  Widget _buildTodayRouteButton(BuildContext context) {
    final role = context.watch<UserState>().role;
    final userMmsi = context.watch<UserState>().mmsi ?? 0;

    if (role != 'ROLE_USER' || userMmsi == 0) {
      return const SizedBox.shrink();
    }

    return Consumer<MainScreenController>(
      builder: (context, controller, child) {
        return AnimatedOpacity(
          opacity: controller.isOtherVesselsVisible ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: controller.isOtherVesselsVisible,
            child: GestureDetector(
              onTap: _isLoadingRoute ? null : () => _loadTodayRoute(userMmsi),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.s20,
                  vertical: AppSizes.s12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.skyType2,
                      AppColors.skyType1,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.s24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/kdn/ros/img/ship_on.svg',
                      width: AppSizes.s20,
                      height: AppSizes.s20,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: AppSizes.s8),
                    _isLoadingRoute
                        ? SizedBox(
                      width: AppSizes.s16,
                      height: AppSizes.s16,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      '당일 항적보기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.s14,
                        fontWeight: FontWeights.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onNavItemTapped(int index, BuildContext context) {
    NavigationDebugHelper.debugPrint('Navigation item tapped: $index, current: $selectedIndex',
        location: 'main_screen');

    // 토글 로직: 같은 탭을 다시 클릭하면 바텀시트를 닫음
    if (selectedIndex == index) {
      // 이미 선택된 탭을 다시 클릭한 경우 - 바텀시트 닫기
      _bottomSheetController?.close();
      _bottomSheetController = null;
      setState(() {
        selectedIndex = -1;
      });
      _controller.setSelectedIndex(-1);
      return;
    }

    // 다른 탭을 클릭한 경우 - 기존 바텀시트 닫고 새로운 것 열기
    _bottomSheetController?.close();

    // selectedIndex 업데이트
    setState(() {
      selectedIndex = index;
    });
    _controller.setSelectedIndex(index);

    // 긴급신고 (index 0)
    if (index == 0) {
      _bottomSheetController = showBottomSheet(
        context: context,
        builder: (context) => MainViewEmergencySheet(context, onClose: () {
          setState(() {
            selectedIndex = -1;
          });
          _controller.setSelectedIndex(-1);
        }),
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
      );

      // 바텀시트가 닫힐 때 selectedIndex 리셋
      _bottomSheetController?.closed.then((_) {
        if (mounted && selectedIndex == 0) {
          setState(() {
            selectedIndex = -1;
          });
          _controller.setSelectedIndex(-1);
        }
      });
    } else if (index == 1) {
      // 기상정보 (날씨)
      _bottomSheetController = Scaffold.of(context).showBottomSheet(
            (context) => PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) {
            if (didPop) return;
            setState(() {
              selectedIndex = -1;
            });
            _controller.setSelectedIndex(-1);
            Navigator.of(context).pop();
          },
          child: MainScreenWindy(context, onClose: () {
            setState(() {
              selectedIndex = -1;
            });
            _controller.setSelectedIndex(-1);
          }),
        ),
        backgroundColor: AppColors.blackType3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
      );

      // 바텀시트가 닫힐 때 selectedIndex 리셋
      _bottomSheetController?.closed.then((_) {
        if (mounted && selectedIndex == 1) {
          setState(() {
            selectedIndex = -1;
          });
          _controller.setSelectedIndex(-1);
        }
      });
    } else if (index == 2) {
      // 항행이력
      _bottomSheetController = showBottomSheet(
        context: context,
        builder: (context) => MainViewNavigationSheet(
          onClose: () {
            // 안전한 종료 처리
            if (_bottomSheetController != null) {
              _bottomSheetController?.close();
              _bottomSheetController = null;
            }
            _controller.resetNavigationHistory();
            setState(() {
              selectedIndex = -1;
            });
            _controller.setSelectedIndex(-1);
          },
          resetDate: true,
          resetSearch: true,
        ),
        backgroundColor: AppColors.blackType3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
      );

      // 바텀시트가 닫힐 때 selectedIndex 리셋
      _bottomSheetController?.closed.then((_) {
        if (mounted && selectedIndex == 2) {
          _controller.resetNavigationHistory();
          setState(() {
            selectedIndex = -1;
          });
          _controller.setSelectedIndex(-1);
        }
      });
    } else if (index == 3) {
      // 마이페이지
      if (mounted) {
        Navigator.push(
          context,
          createSlideTransition(
            MemberInformationView(username: widget.username),
          ),
        ).then((_) {
          setState(() {
            selectedIndex = -1;
          });
          _controller.setSelectedIndex(-1);
        });
      }
    }
  }

  @override
  void dispose() {
    // 애니메이션 컨트롤러 정리
    _flashController.stop();
    _flashController.dispose();

    // Bottom Sheet 정리
    _bottomSheetController?.close();
    _bottomSheetController = null;

    // 컨트롤러 정리
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserState>().role;
    final mmsi = context.watch<UserState>().mmsi ?? 0;

    final vesselsViewModel = context.watch<VesselProvider>();
    List<VesselSearchModel> vessels;

    if (role == 'ROLE_USER') {
      vessels = vesselsViewModel.vessels
          .where((vessel) => vessel.mmsi == mmsi)
          .toList();
    } else {
      vessels = vesselsViewModel.vessels;
    }

    // ✅ 핵심 수정: MultiProvider -> Scaffold -> Consumer 순서
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MainScreenController>.value(value: _controller),
        ChangeNotifierProvider<MapControllerProvider>.value(
          value: _mapControllerProvider,
        ),
        ChangeNotifierProvider<RouteProvider>.value(
          value: _controller.routeSearchViewModel,
        ),
      ],
      child: Scaffold(
        body: Consumer<MainScreenController>(
          builder: (context, controller, child) {
            return Stack(
              children: [
                // 1. 지도 레이어
                MainMapWidget(
                  mapController: controller.mapController,
                  currentPosition: controller.currentPosition,
                  vessels: vessels,
                  currentUserMmsi: mmsi,
                  isOtherVesselsVisible: controller.isOtherVesselsVisible,
                  isTrackingEnabled: controller.isTrackingEnabled,
                  onVesselTap: (vessel) {
                    routePop(context, vessel);
                  },
                ),

                // 2. 상단 파고/시정 버튼
                const WeatherControlButtons(),

                // 3. 우측 하단 지도 컨트롤 버튼 (항적초기화 버튼 통합됨)
                MapControlButtons(
                  isOtherVesselsVisible: controller.isOtherVesselsVisible,
                  onOtherVesselsToggle: controller.toggleOtherVesselsVisibility,
                  mapController: controller.mapController,
                  onHomeButtonTap: (context) => controller.moveToHome(),
                ),

                // 4. 플래싱 오버레이
                if (controller.isFlashing)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _flashController,
                        builder: (context, child) => Container(
                          color: Colors.red.withOpacity(
                            0.3 * _flashController.value,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 5. 상단 알림 메시지
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSizes.s10,
                  left: AppSizes.s20,
                  right: AppSizes.s20,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: selectedIndex == 2
                        ? Container(
                      key: const ValueKey('navigation_history'),
                      padding: EdgeInsets.all(AppSizes.s12),
                      decoration: BoxDecoration(
                        color: AppColors.skyType2.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(AppSizes.s8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: AppSizes.s20,
                          ),
                          SizedBox(width: AppSizes.s8),
                          Expanded(
                            child: Text(
                              '항행이력을 조회하려면 MMSI 또는 선명을 입력하세요',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppSizes.s14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                ),

                // 6. 당일 항적보기 버튼
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: _buildTodayRouteButton(context),
                ),

                // 7. ✨ 항행경보 표시 (새로 추가된 기능)
                Positioned(
                  bottom: 0,  // 하단 네비게이션 바 바로 위
                  left: 0,
                  right: 0,
                  child: Consumer<NavigationProvider>(
                    builder: (context, viewModel, child) {
                      final warnings = viewModel.combinedNavigationWarnings;

                      // 항행경보 바는 항상 표시됨
                      return Container(
                        height: AppSizes.s52,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.s12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.redType1.withOpacity(0.95),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/kdn/ros/img/circle-exclamation_white.svg',
                              width: AppSizes.s24,
                              height: AppSizes.s24,
                            ),
                            SizedBox(width: AppSizes.s8),
                            Expanded(
                              child: Marquee(
                                text: warnings.isEmpty ? '금일 항행경보가 없습니다.' : warnings,
                                style: TextStyle(
                                  color: AppColors.whiteType1,
                                  fontSize: AppSizes.s14,
                                  fontWeight: FontWeights.w700,
                                ),
                                scrollAxis: Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                blankSpace: 300.0,
                                velocity: 35.0,
                                pauseAfterRound: const Duration(seconds: 1),
                                startPadding: 10.0,
                                accelerationDuration: const Duration(seconds: 1),
                                accelerationCurve: Curves.linear,
                                decelerationDuration: const Duration(seconds: 1),
                                decelerationCurve: Curves.easeOut,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomNavigationWidget(
          selectedIndex: selectedIndex,
          onItemTapped: _onNavItemTapped,
        ),
      ),
    );
  }
}