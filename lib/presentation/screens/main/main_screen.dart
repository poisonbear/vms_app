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
    // Scaffold context를 미리 저장
    final scaffoldContext = context;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(getSize16()),
          ),
          child: Container(
            padding: EdgeInsets.all(getSize20()),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.directions_boat,
                            color: getColorSkyType2(),
                            size: getSize28(),
                          ),
                          SizedBox(width: getSize8()),
                          TextWidgetString(
                            '선박 정보',
                            getTextleft(),
                            getSizeInt24(),
                            getTextbold(),
                            getColorBlackType1(),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: getColorGrayType8(),
                          size: getSize24(),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  Divider(
                    height: getSize24(),
                    thickness: 1,
                    color: getColorGrayType4(),
                  ),

                  // 선박 정보 테이블
                  VesselInfoTable(
                    vessel: vessel,
                    showExtendedInfo: true,
                  ),

                  SizedBox(height: getSize24()),

                  // 버튼 영역
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: getSize16(),
                            vertical: getSize8(),
                          ),
                        ),
                        child: Text(
                          '닫기',
                          style: TextStyle(
                            color: getColorGrayType7(),
                            fontSize: getSize14(),
                          ),
                        ),
                      ),
                      SizedBox(width: getSize8()),
                      ElevatedButton(
                        onPressed: _isLoadingRoute ? null : () async {  // 로딩 중에는 버튼 비활성화
                          // Dialog context와 Scaffold context를 분리
                          final scaffoldContext = context;

                          // 선박 정보 팝업 먼저 닫기
                          Navigator.of(dialogContext).pop();

                          // 약간의 딜레이를 주어 Dialog가 완전히 닫히도록 함
                          await Future.delayed(const Duration(milliseconds: 100));

                          // 로딩 상태 시작
                          if (mounted) {
                            setState(() {
                              _isLoadingRoute = true;
                            });
                          }

                          try {
                            // 당일 항적 조회 시작
                            _controller.startTracking(vessel.mmsi ?? 0);

                            // 항행이력 탭 열기
                            _onNavItemTapped(2, scaffoldContext);

                            // RouteSearchProvider를 통해 항적 조회 실행
                            if (mounted) {
                              final routeSearchProvider = scaffoldContext.read<RouteSearchProvider>();

                              // 오늘 날짜로 설정
                              final today = DateTime.now();
                              final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

                              // 항적 조회 - getVesselRoute 메서드 사용
                              await routeSearchProvider.getVesselRoute(
                                mmsi: vessel.mmsi,
                                regDt: dateStr,
                              );

                              // 성공 메시지 표시
                              if (mounted) {
                                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('당일 항적을 조회했습니다.'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            AppLogger.e('항적 조회 실패: $e');
                            if (mounted) {
                              // Dialog가 닫힌 후에 SnackBar 표시
                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                const SnackBar(
                                  content: Text('항적 조회 중 오류가 발생했습니다.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } finally {
                            // 로딩 상태 종료
                            if (mounted) {
                              setState(() {
                                _isLoadingRoute = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getColorSkyType2(),
                          padding: EdgeInsets.symmetric(
                            horizontal: getSize20(),
                            vertical: getSize8(),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(getSize8()),
                          ),
                        ),
                        child: _isLoadingRoute
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
                      ),
                    ],
                  ),
                ],
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
      // 항행이력
      _bottomSheetController?.close();
      _bottomSheetController = showBottomSheet(
        context: context,
        builder: (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider<MainScreenController>.value(value: _controller),
              ChangeNotifierProvider<MapControllerProvider>.value(
                value: _mapControllerProvider,
              ),
              ChangeNotifierProvider<RouteSearchProvider>.value(
                value: _controller.routeSearchViewModel,
              ),
            ],
            child: Consumer<MainScreenController>(
              builder: (context, controller, child) {
                NavigationDebugHelper.debugPrint('Building NavigationSheet in BottomSheet',
                    location: 'main.bottom_sheet.build');
                NavigationDebugHelper.checkProviderAccess(context, 'main.bottom_sheet');

                return MainViewNavigationSheet(
                  onClose: () {
                    _bottomSheetController?.close();
                    _controller.resetNavigationHistory();
                    setState(() {
                      selectedIndex = -1;
                    });
                  },
                  resetDate: true,
                  resetSearch: true,
                );
              },
            )
        ),
        backgroundColor: getColorBlackType3(),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
      );

      _bottomSheetController?.closed.then((_) {
        _controller.resetNavigationHistory();
        setState(() {
          selectedIndex = -1;
        });
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
      child: Consumer<MainScreenController>(
        builder: (context, controller, child) {
          return Scaffold(
            body: Stack(
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

                // 6. 하단 네비게이션 바 (먼저 배치)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomNavigationWidget(
                    selectedIndex: selectedIndex,
                    onItemTapped: _onNavItemTapped,  // 2개 파라미터 전달
                  ),
                ),

                // 7. 상단 알림 메시지
                Positioned(
                  top: MediaQuery.of(context).padding.top + getSize10(),
                  left: getSize20(),
                  right: getSize20(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: selectedIndex == 2
                        ? Container(
                      key: const ValueKey('navigation_hint'),
                      padding: EdgeInsets.symmetric(
                        horizontal: getSize16(),
                        vertical: getSize8(),
                      ),
                      decoration: BoxDecoration(
                        color: getColorBlackType3().withOpacity(0.9),
                        borderRadius: BorderRadius.circular(getSize20()),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: getSize16(),
                          ),
                          SizedBox(width: getSize8()),
                          Expanded(
                            child: Text(
                              '항행이력 조회 중입니다',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: getSize14(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ),

                // 8. 긴급 메시지 표시 영역 (최상단)
                if (showEmergencyMessage && emergencyMessage.isNotEmpty)
                  Positioned(
                    top: MediaQuery.of(context).padding.top,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 4,
                      child: Container(
                        height: getSize40(),
                        color: Colors.red,
                        child: Marquee(
                          text: emergencyMessage,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: getSize16(),
                            fontWeight: FontWeight.bold,
                          ),
                          scrollAxis: Axis.horizontal,
                          velocity: 30.0,
                          blankSpace: 200.0,
                          pauseAfterRound: const Duration(seconds: 1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}