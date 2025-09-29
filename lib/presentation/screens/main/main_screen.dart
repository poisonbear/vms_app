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
import 'package:latlong2/latlong.dart';  // LatLng import 추가 (올바른 경로)

// AutoLocationHelper import
import 'helpers/auto_location_helper.dart';

import 'controllers/main_screen_controller.dart';
import 'services/fcm_service.dart';
import 'services/location_service_manager.dart';
import 'services/vessel_data_manager.dart';
import 'utils/permission_utils.dart';
import 'utils/navigation_utils.dart';
import 'utils/navigation_debug.dart';

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
  int selectedIndex = 0;

  // 로딩 상태 관리 변수 추가
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();

    // 컨트롤러 초기화
    _controller = MainScreenController(
      routeSearchViewModel: widget.routeSearchViewModel,
    );

    // 서비스 초기화
    _locationManager = LocationServiceManager();
    _vesselDataManager = VesselDataManager();

    // MapControllerProvider 인스턴스 생성
    _mapControllerProvider = MapControllerProvider();

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
      duration: AppDurations.seconds60,
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
        AppDurations.seconds2,
            () {
          if (!mounted) return;
          _vesselDataManager.loadVesselDataAndUpdateMap(context);
        },
      );

      // FCM 리스너 등록
      _fcmService.registerFCMListener(context);

      // 위치 권한 요청
      Future.delayed(AppDurations.seconds300, () {
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
      AppDurations.seconds2,
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
      await Future.delayed(AppDurations.seconds60);
      await PointRequestUtil.requestPermissionUntilGranted(context);
      final location = await _locationManager.getCurrentLocation();
      if (location != null) {
        _controller.updateCurrentPosition(location);
      }
    }

    // 알림 권한
    NotificationSettings notifSettings =
    await FirebaseMessaging.instance.getNotificationSettings();
    if (notifSettings.authorizationStatus != AuthorizationStatus.authorized) {
      await Future.delayed(AppDurations.seconds60);
      await NotificationRequestUtil.requestPermissionUntilGranted(context);
      await _fcmService.requestNotificationPermission();
    }
  }

  /// 자동 위치 포커스 (AutoLocationHelper 사용)
  Future<void> _performAutoFocus() async {
    if (!mounted) return;

    AppLogger.d('📍 내 위치찾기 자동 실행 시작...');

    try {
      // AutoLocationHelper를 사용하여 자동 포커스 실행
      await AutoLocationHelper.executeAutoFocus(
        context: context,
        mapController: _controller.mapController,
      );

      AppLogger.d('✅ 내 위치찾기 자동 실행 완료');
    } catch (e) {
      AppLogger.e('내 위치찾기 자동 실행 실패: $e');
    }
  }

  /// 선박 정보 팝업 - 수정된 버전 (300초 → 300밀리초)
  Future<void> routePop(BuildContext context, VesselSearchModel vessel) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,  // 배경 어둡게
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 10,  // 그림자 효과로 시인성 향상
          insetPadding: EdgeInsets.symmetric(
            horizontal: getSize20(),
            vertical: getSize26(),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(getSize20()),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignConstants.radiusM),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
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
                    const Spacer(),
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
                      onPressed: () => Navigator.of(context).pop(),
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
                        Navigator.of(context).pop();  // 선박 정보 팝업 닫기

                        // 로딩 상태 시작
                        setState(() {
                          _isLoadingRoute = true;
                        });

                        try {
                          // 당일 항적 조회 시작
                          _controller.startTracking(vessel.mmsi ?? 0);

                          // 당일 날짜 생성 (YYYY-MM-DD 형식)
                          final today = DateTime.now();
                          final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

                          AppLogger.d('📅 당일 항적 조회 시작 - MMSI: ${vessel.mmsi}, Date: $todayStr');

                          // RouteSearchProvider를 통해 당일 항적 데이터 조회
                          await _controller.routeSearchViewModel.getVesselRoute(
                            mmsi: vessel.mmsi,
                            regDt: todayStr,
                          );

                          AppLogger.d('✅ 당일 항적 조회 완료 - 과거: ${_controller.routeSearchViewModel.pastRoutes.length}개, 예측: ${_controller.routeSearchViewModel.predRoutes.length}개');

                          // 항적이 있는 경우 첫 번째 위치로 지도 이동
                          if (_controller.routeSearchViewModel.pastRoutes.isNotEmpty) {
                            final firstPoint = LatLng(
                              _controller.routeSearchViewModel.pastRoutes.first.lttd ?? 35.3790988,
                              _controller.routeSearchViewModel.pastRoutes.first.lntd ?? 126.167763,
                            );
                            _controller.mapController.move(firstPoint, 13.0);

                            // 성공 알림
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${vessel.ship_nm ?? "선박"}의 당일 항적을 표시합니다'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: getColorSkyType2(),
                                ),
                              );
                            }
                          } else {
                            // 항적이 없는 경우
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${vessel.ship_nm ?? "선박"}의 당일 항적이 없습니다'),
                                  duration: Duration(seconds: 3),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }

                        } catch (e) {
                          AppLogger.e('❌ 당일 항적 조회 실패: $e');

                          // 에러 알림
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('항적 조회 중 오류가 발생했습니다'),
                                duration: Duration(seconds: 3),
                                backgroundColor: Colors.red,
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
                          vertical: getSize10(),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(getSize8()),
                        ),
                      ),
                      child: Text(
                        '항적보기',
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
        );
      },
    );
  }

  /// 하단 네비게이션 바 선택 처리
  void _onNavItemTapped(int index, BuildContext context) {
    NavigationDebugHelper.debugPrint('Nav item tapped: $index', location: 'main.nav_tap');

    setState(() {
      selectedIndex = index;
    });

    _controller.setSelectedIndex(index);

    if (index == 0) {
      // ✅ 긴급신고 탭
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
          child: MainViewEmergencySheet(context, onClose: () {
            setState(() {
              selectedIndex = -1;
            });
            _controller.setSelectedIndex(-1);
          }),
        ),
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignConstants.radiusXL),
          ),
        ),
      );
    } else if (index == 1) {
      // 날씨 정보
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

                // 3. 우측 하단 지도 컨트롤 버튼
                MapControlButtons(
                  isOtherVesselsVisible: controller.isOtherVesselsVisible,
                  onOtherVesselsToggle: controller.toggleOtherVesselsVisibility,
                  mapController: controller.mapController,
                  onHomeButtonTap: (context) => controller.moveToHome(),
                ),

                // 4. Refresh 버튼 (복원)
                Positioned(
                  right: getSize20(),
                  top: MediaQuery.of(context).size.height / 2 - 100,
                  child: Consumer<RouteSearchProvider>(
                    builder: (context, routeViewModel, _) {
                      if ((routeViewModel.pastRoutes.isNotEmpty == true ||
                          (routeViewModel.predRoutes.isNotEmpty == true)) &&
                          routeViewModel.isNavigationHistoryMode != true &&
                          controller.isTrackingEnabled) {
                        return CircularButton(
                          svgPath: 'assets/kdn/home/img/refresh.svg',
                          colorOn: getColorGrayType8(),
                          colorOff: getColorGrayType8(),
                          widthSize: getSizeInt56(),
                          heightSize: getSizeInt56(),
                          onTap: () {
                            controller.stopTracking();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('항적 데이터가 초기화되었습니다.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

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

                // 7. 하단 항행경보 마키 (네비게이션 바 바로 위에 배치)
                Positioned(
                  bottom: 60,  // 네비게이션 바 높이만큼 위로
                  left: 0,
                  right: 0,
                  child: Consumer<NavigationProvider>(
                    builder: (context, viewModel, child) {
                      return Container(
                        height: getSize40(),  // 높이를 52에서 40으로 줄임
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesignConstants.spacing12),
                        decoration: BoxDecoration(
                          color: getColorRedType1(),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/kdn/ros/img/circle-exclamation_white.svg',
                              width: getSize20(),  // 아이콘 크기도 조정
                              height: getSize20(),
                            ),
                            SizedBox(width: getSize8()),
                            Expanded(
                              child: Marquee(
                                text: viewModel.combinedNavigationWarnings,
                                style: TextStyle(
                                  color: getColorWhiteType1(),
                                  fontSize: DesignConstants.fontSizeS,  // 폰트 크기도 조정
                                  fontWeight: getText600(),
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

                // 8. 로딩 오버레이 (항적 로딩 중일 때만 표시)
                if (_isLoadingRoute)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(getSize24()),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(getSize12()),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(getColorSkyType2()),
                              ),
                              SizedBox(height: getSize16()),
                              Text(
                                '당일 항적을 불러오는 중...',
                                style: TextStyle(
                                  fontSize: getSize14(),
                                  fontWeight: getText600(),
                                  color: getColorBlackType2(),
                                ),
                              ),
                            ],
                          ),
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