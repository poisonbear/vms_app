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
import 'package:vms_app/presentation/providers/route_search_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/screens/main/tabs/navigation_tab.dart';
import 'package:vms_app/presentation/screens/main/tabs/weather_tab.dart';
import 'package:vms_app/presentation/screens/main/tabs/emergency_tab.dart';
import 'package:vms_app/presentation/screens/profile/profile_screen.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/utils/helpers.dart';
import 'package:latlong2/latlong.dart';

// Helpers and Utils
import 'helpers/auto_location_helper.dart';
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
  final RouteSearchProvider? routeSearchViewModel;
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
                // 헤더 - 항행이력과 동일한 스타일
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: getSize16(),
                    vertical: getSize20(),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(DesignConstants.radiusXL),
                      topRight: Radius.circular(DesignConstants.radiusXL),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextWidgetString(
                        '선박 정보',
                        getTextleft(),
                        getSizeInt20(),
                        getText700(),
                        getColorBlackType2(),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: getSize24(),
                        height: getSize24(),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.close, color: Colors.black, size: getSize24()),
                          onPressed: () {
                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 선박 정보 컨텐츠
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: getSize16()),
                    child: Column(
                      children: [
                        _buildVesselInfoTable(vessel),
                        SizedBox(height: getSize20()),
                      ],
                    ),
                  ),
                ),

                // 버튼 영역 - 하단 고정
                Container(
                  padding: EdgeInsets.all(getSize16()),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    border: Border(
                      top: BorderSide(
                        color: getColorGrayType4(),
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
                            height: getSize44(),
                            decoration: BoxDecoration(
                              color: getColorGrayType4(),
                              borderRadius: BorderRadius.circular(getSize8()),
                            ),
                            child: Center(
                              child: TextWidgetString(
                                '닫기',
                                getTextcenter(),
                                getSizeInt14(),
                                getText600(),
                                getColorGrayType7(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: getSize12()),
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
                            height: getSize44(),
                            decoration: BoxDecoration(
                              color: getColorSkyType2(),
                              borderRadius: BorderRadius.circular(getSize8()),
                            ),
                            child: Center(
                              child: TextWidgetString(
                                '당일 항적보기',
                                getTextcenter(),
                                getSizeInt14(),
                                getText600(),
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

  Widget _buildVesselInfoTable(VesselSearchModel vessel) {
    return Container(
      margin: EdgeInsets.only(top: getSize10()),
      child: Column(
        children: [
          _buildInfoRow('선박명', vessel.ship_nm ?? '-'),
          _buildDivider(),
          _buildInfoRow('MMSI', vessel.mmsi?.toString() ?? '-'),
          _buildDivider(),
          _buildInfoRow('선종', vessel.ship_knd ?? '-'),
          _buildDivider(),
          _buildInfoRow('흘수', vessel.draft != null ? '${vessel.draft} m' : '-'),
          _buildDivider(),
          _buildInfoRow('속력', vessel.sog != null ? '${vessel.sog!.toStringAsFixed(1)} knots' : '-'),
          _buildDivider(),
          _buildInfoRow('침로', vessel.cog != null ? '${vessel.cog!.toStringAsFixed(1)}°' : '-'),
          _buildDivider(),
          _buildInfoRow('위치', _formatPosition(vessel)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: getColorGrayType4().withOpacity(0.3),
      margin: EdgeInsets.symmetric(vertical: getSize2()),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getSize12(),
        vertical: getSize14(),
      ),
      child: Row(
        children: [
          SizedBox(
            width: getSize80(),
            child: TextWidgetString(
              label,
              getTextleft(),
              getSizeInt14(),
              getText500(),
              getColorGrayType6(),
            ),
          ),
          Expanded(
            child: TextWidgetString(
              value,
              getTextleft(),
              getSizeInt14(),
              getText600(),
              getColorBlackType2(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPosition(VesselSearchModel vessel) {
    if (vessel.lttd != null && vessel.lntd != null) {
      return '${vessel.lttd!.toStringAsFixed(4)}°, ${vessel.lntd!.toStringAsFixed(4)}°';
    }
    return '-';
  }

  Future<void> _loadTodayRoute(int mmsi) async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final now = DateTime.now();
      await _controller.routeSearchViewModel.getVesselRoute(
        mmsi: mmsi,
        regDt: "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
      );
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  Widget _buildTodayRouteButton(BuildContext context) {
    return Consumer<MainScreenController>(
      builder: (context, controller, child) {
        final hasTracking = controller.selectedVesselMmsi != null;

        return AnimatedOpacity(
          opacity: hasTracking ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedSlide(
            offset: hasTracking ? Offset.zero : const Offset(0, 2),
            duration: const Duration(milliseconds: 300),
            child: Visibility(
              visible: hasTracking,
              child: InkWell(
                onTap: _isLoadingRoute
                    ? null
                    : () async {
                  setState(() {
                    _isLoadingRoute = true;
                  });

                  try {
                    // 당일 항적 조회 로직
                    final routeProvider = controller.routeSearchViewModel;
                    final mmsi = controller.selectedVesselMmsi;

                    if (mmsi != null) {
                      final now = DateTime.now();
                      // getVesselRoute 메서드 사용 (getRoute가 아님)
                      await routeProvider.getVesselRoute(
                        mmsi: mmsi,
                        regDt: "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
                      );
                    }
                  } finally {
                    setState(() {
                      _isLoadingRoute = false;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: getSize24(),
                    vertical: getSize12(),
                  ),
                  decoration: BoxDecoration(
                    color: getColorSkyType2(),
                    borderRadius: BorderRadius.circular(getSize24()),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                        width: getSize20(),
                        height: getSize20(),
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: getSize8()),
                      _isLoadingRoute
                          ? SizedBox(
                        width: getSize16(),
                        height: getSize16(),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        '당일 항적보기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: getSize14(),
                          fontWeight: getText600(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onNavItemTapped(int index, BuildContext context) {
    NavigationDebugHelper.debugPrint('Navigation item tapped: $index',
        location: 'main_screen');

    // 긴급신고 (index 0)
    if (index == 0) {
      _bottomSheetController?.close();
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
    } else if (index == 1) {
      // 기상정보 (날씨)
      _bottomSheetController?.close();
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
        backgroundColor: getColorBlackType3(),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
      );
    } else if (index == 2) {
      // 항행이력 - ✅ 핵심 수정 부분 (Provider 제거)
      _bottomSheetController?.close();
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
          },
          resetDate: true,
          resetSearch: true,
        ),
        backgroundColor: getColorBlackType3(),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
      );

      _bottomSheetController?.closed.then((_) {
        if (mounted) {
          _controller.resetNavigationHistory();
          setState(() {
            selectedIndex = -1;
          });
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
        ChangeNotifierProvider<RouteSearchProvider>.value(
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

                // 4. Refresh 버튼 제거됨 (MapControlButtons 내부로 통합)

                // 5. 플래싱 오버레이
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

                // 6. 상단 알림 메시지
                Positioned(
                  top: MediaQuery.of(context).padding.top + getSize10(),
                  left: getSize20(),
                  right: getSize20(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: selectedIndex == 2
                        ? Container(
                      key: const ValueKey('navigation_history'),
                      padding: EdgeInsets.all(getSize12()),
                      decoration: BoxDecoration(
                        color: getColorSkyType2().withOpacity(0.9),
                        borderRadius: BorderRadius.circular(getSize8()),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: getSize20(),
                          ),
                          SizedBox(width: getSize8()),
                          Expanded(
                            child: Text(
                              '항행이력을 조회하려면 MMSI 또는 선명을 입력하세요',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: getSize14(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                ),

                // 7. 당일 항적보기 버튼
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: _buildTodayRouteButton(context),
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