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

  /// 선박 정보 팝업
  Future<void> routePop(BuildContext context, VesselSearchModel vessel) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(seconds: 300),
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: getSize26(),
                left: getSize20(),
                right: getSize20(),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(getSize20()),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: getSize10(),
                          offset: Offset(getSize0(), getSize4()),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            TextWidgetString('선박 정보', getTextleft(), getSizeInt24(),
                                getTextbold(), getColorBlackType1()),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Icon(Icons.close, color: getColorGrayType8()),
                            ),
                          ],
                        ),
                        SizedBox(height: getSize16()),
                        VesselInfoTable(
                          vessel: vessel,
                          showExtendedInfo: true,  // 확장 정보 표시 (선택사항)
                        ),
                        SizedBox(height: getSize20()),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _controller.startTracking(vessel.mmsi ?? 0);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: getColorSkyType2(),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(DesignConstants.radiusS),
                                ),
                              ),
                              child: TextWidgetString('항로 조회', getTextcenter(), getSizeInt16(),
                                  getText600(), getColorWhiteType1()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 네비게이션 아이템 탭 처리
  void _onItemTapped(int index, BuildContext context) {
    // 이미 선택된 탭을 다시 누르면 바텀시트 닫기
    if (selectedIndex == index && _bottomSheetController != null) {
      _bottomSheetController!.close();
      setState(() {
        selectedIndex = -1;  // 지도 화면으로
      });
      _controller.setSelectedIndex(-1);
      return;
    }

    setState(() {
      selectedIndex = index;
    });
    _controller.setSelectedIndex(index);

    // 기존 바텀시트 닫기
    if (_bottomSheetController != null) {
      _bottomSheetController!.close();
      _bottomSheetController = null;
    }

    _controller.stopTracking();
    _controller.routeSearchViewModel.setNavigationHistoryMode(true);

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
      // 항행 이력
      NavigationDebugHelper.debugPrint('항행이력 탭 클릭', location: 'main_screen');
      NavigationDebugHelper.checkProviderAccess(context, 'main_screen.before');

      _bottomSheetController = Scaffold.of(context).showBottomSheet(
            (bottomSheetContext) => MultiProvider(
            providers: [
              ChangeNotifierProvider<RouteSearchProvider>.value(
                value: _controller.routeSearchViewModel,
              ),
              ChangeNotifierProvider<MapControllerProvider>.value(
                value: _mapControllerProvider,
              ),
            ],
            child: Builder(
              builder: (providerContext) {
                NavigationDebugHelper.debugPrint('Provider 설정 완료', location: 'main_screen');
                NavigationDebugHelper.checkProviderAccess(providerContext, 'main_screen.after');

                return PopScope(
                  canPop: false,
                  onPopInvoked: (bool didPop) {
                    if (didPop) return;
                    _controller.resetNavigationHistory();
                    setState(() {
                      selectedIndex = -1;
                    });
                    Navigator.of(context).pop();
                  },
                  child: MainViewNavigationSheet(
                    onClose: () {
                      _controller.resetNavigationHistory();
                      setState(() {
                        selectedIndex = -1;
                      });
                    },
                    resetDate: true,
                    resetSearch: true,
                  ),
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

                // 4. Refresh 버튼
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

                // 5. 하단 항행경보 마키
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Consumer<NavigationProvider>(
                    builder: (context, viewModel, child) {
                      return Container(
                        height: getSize52(),
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
                              width: getSize24(),
                              height: getSize24(),
                            ),
                            SizedBox(width: getSize8()),
                            Expanded(
                              child: Marquee(
                                text: viewModel.combinedNavigationWarnings,
                                style: TextStyle(
                                  color: getColorWhiteType1(),
                                  fontSize: DesignConstants.fontSizeM,
                                  fontWeight: getText700(),
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

                // 6. 플래시 오버레이
                FlashOverlay(
                  flashController: _flashController,
                  isFlashing: controller.isFlashing,
                ),
              ],
            ),
            // ✅ 하단 네비게이션 바 (경광등 아이콘 적용)
            bottomNavigationBar: BottomNavigationWidget(
              selectedIndex: selectedIndex == -1 ? 0 : selectedIndex,  // -1일 때도 첫 번째 탭으로 표시
              onItemTapped: _onItemTapped,
              showEmergencyTab: true,
            ),
          );
        },
      ),
    );
  }
}