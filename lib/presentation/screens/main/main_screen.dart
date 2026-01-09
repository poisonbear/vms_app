// lib/presentation/screens/main/main_screen.dart

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

// ==========================================
// MainScreen Widget
// ==========================================

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

// ==========================================
// MainScreenState
// ==========================================

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // ==========================================
  // Controllers & Services
  // ==========================================
  late MainScreenController _controller;
  late LocationServiceManager _locationManager;
  late VesselDataManager _vesselDataManager;
  FCMService? _fcmService;

  // ==========================================
  // UI Controllers
  // ==========================================
  late AnimationController _flashController;
  PersistentBottomSheetController? _bottomSheetController;
  late MapControllerProvider _mapControllerProvider;

  // ==========================================
  // Local UI State
  // ==========================================
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  int selectedIndex = -1;
  bool _isLoadingRoute = false;

  // ==========================================
  // FCM 관련 상태
  // ==========================================
  bool showEmergencyMessage = false;
  String emergencyMessage = '';

  // ==========================================
  // 🚀 최적화: 선박 필터링 캐싱
  // ==========================================
  List<VesselSearchModel>? _cachedVessels;
  String? _cachedRole;
  int? _cachedMmsi;

  // ==========================================
  // Lifecycle Methods
  // ==========================================

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _initializeServices();
  }

  void _initializeControllers() {
    _controller = MainScreenController(
      routeSearchViewModel: widget.routeSearchViewModel,
    );
    _mapControllerProvider = MapControllerProvider();
    _locationManager = LocationServiceManager();
    _vesselDataManager = VesselDataManager();
  }

  void _initializeAnimations() {
    selectedIndex = -1;
    _controller.setSelectedIndex(-1);

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
  }

  Future<void> _initializeServices() async {
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

    await _fcmService?.initializeToken();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialData();
      _setupPeriodicUpdates();
      _setupDelayedTasks();
    });

    _initializeWeatherAndWarnings();
  }

  Future<void> _loadInitialData() async {
    await _vesselDataManager.loadVesselDataAndUpdateMap(context);
    if (!mounted) return;
    if (!context.mounted) return;
    _fcmService?.registerFCMListener(context);
  }

  void _setupPeriodicUpdates() {
    _controller.timerService.startPeriodicTimer(
      "vessel_update",
      const Duration(seconds: 2),
          () {
        if (!mounted) return;
        if (!context.mounted) return;
        _vesselDataManager.loadVesselDataAndUpdateMap(context);
      },
    );

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
  }

  void _setupDelayedTasks() {
    Future.delayed(const Duration(seconds: 300), () {
      _requestPermissionsSequentially();
    });

    // 항상 초기 위치 설정 - 지도 완전 로드 후 실행 (1초 대기)
    Future.delayed(const Duration(milliseconds: 1000), () {
      _performAutoFocus();
    });

    if (widget.autoFocusLocation) {
      AppLogger.d('🚀 자동 포커스 활성화: ${widget.autoFocusLocation}');
    }
  }

  void _initializeWeatherAndWarnings() {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.getWeatherInfo();
    navProvider.getNavigationWarnings();
  }

  Future<void> _requestPermissionsSequentially() async {
    bool locationGranted =
    await _locationManager.checkAndRequestLocationPermission();
    if (locationGranted) {
      final location = await _locationManager.getCurrentLocation();
      if (location != null) {
        _controller.updateCurrentPosition(location);
      }
    } else {
      await Future.delayed(const Duration(seconds: 60));

      //mounted 체크 추가 (라인 164 근처)
      if (!mounted) return;
      if (!context.mounted) return;

      await PointRequestUtil.requestPermissionUntilGranted(context);
      final location = await _locationManager.getCurrentLocation();
      if (location != null) {
        _controller.updateCurrentPosition(location);
      }
    }

    NotificationSettings notifSettings =
    await FirebaseMessaging.instance.getNotificationSettings();
    if (notifSettings.authorizationStatus != AuthorizationStatus.authorized &&
        notifSettings.authorizationStatus != AuthorizationStatus.provisional) {
      await FirebaseMessaging.instance.requestPermission();
    }
  }

  Future<void> _performAutoFocus() async {
    // 기본 위치 (발전단지 중앙)
    const defaultLocation = LatLng(35.374509, 126.132268);

    try {
      if (!mounted) return;
      if (!context.mounted) return;

      // 지도 컨트롤러 준비 대기
      await Future.delayed(const Duration(milliseconds: 300));

      final userMmsi = context.read<UserState>().mmsi;
      if (userMmsi == null || userMmsi == 0) {
        // MMSI 없을 때 기본 위치로 이동
        _controller.mapController.moveAndRotate(defaultLocation, 12.0, 0.0);
        AppLogger.w('MMSI가 없어 기본 위치로 이동');
        return;
      }

      final vesselProvider = context.read<VesselProvider>();

      if (vesselProvider.vessels.isEmpty) {
        await vesselProvider.getVesselList();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!mounted) return;
      if (!context.mounted) return;

      // 사용자 선박 찾기
      final userVessel = vesselProvider.vessels
          .where((v) => v.mmsi == userMmsi)
          .firstOrNull;

      if (userVessel != null &&
          userVessel.lttd != null &&
          userVessel.lntd != null) {
        // 사용자 선박 위치로 이동
        final vesselLocation = LatLng(userVessel.lttd!, userVessel.lntd!);
        _controller.mapController.moveAndRotate(vesselLocation, 13.0, 0.0);
        AppLogger.i('로그인 후 자동 포커스 완료 (MMSI: $userMmsi)');
      } else {
        // 선박을 찾지 못한 경우 기본 위치로 이동
        _controller.mapController.moveAndRotate(defaultLocation, 12.0, 0.0);
        AppLogger.w('선박을 찾지 못해 기본 위치로 이동 (MMSI: $userMmsi)');
      }
    } catch (e) {
      AppLogger.e('자동 포커스 실패: $e');

      // 실패 시 기본 위치(발전단지)로 이동
      try {
        _controller.mapController.moveAndRotate(defaultLocation, 12.0, 0.0);
      } catch (e2) {
        AppLogger.e('기본 위치 이동도 실패: $e2');
      }
    }
  }

  @override
  void dispose() {
    _flashController.stop();
    _flashController.dispose();
    _bottomSheetController?.close();
    _bottomSheetController = null;
    _controller.dispose();
    super.dispose();
  }

  // ==========================================
  // Build Method
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final role = userState.role;
    final mmsi = userState.mmsi ?? 0;

    final vesselsViewModel = context.watch<VesselProvider>();
    final vessels = _getFilteredVessels(vesselsViewModel.vessels, role, mmsi);

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
                // 지도
                MapWidget(
                  mapController: controller.mapController,
                  currentPosition: controller.currentPosition,
                  vessels: vessels,
                  currentUserMmsi: mmsi,
                  isOtherVesselsVisible: controller.isOtherVesselsVisible,
                  isTrackingEnabled: controller.isTrackingEnabled,
                  onVesselTap: (vessel) => _showVesselDialog(context, vessel),
                ),

                // 기상 버튼
                const WeatherControlWidget(),

                // 맵 컨트롤 버튼
                MapControlWidget(
                  isOtherVesselsVisible: controller.isOtherVesselsVisible,
                  onOtherVesselsToggle: controller.toggleOtherVesselsVisibility,
                  mapController: controller.mapController,
                  onHomeButtonTap: (context) => controller.moveToHome(),
                ),

                // 플래싱 오버레이
                if (controller.isFlashing)
                  FlashOverlay(animation: _flashController),

                // 당일 항적 버튼
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSizes.s60,
                  right: AppSizes.s16,
                  child: TodayRouteButton(
                    onPressed: () => _loadTodayRoute(mmsi),
                    isLoading: _isLoadingRoute,
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 0, // 간격 0
          children: [
            // 항행경보 배너
            const NavigationWarningBanner(
              isVisible: true,
            ),

            // 하단 네비게이션 바
            BottomNavigationWidget(
              selectedIndex: selectedIndex,
              onItemTapped: _onNavItemTapped,
              showEmergencyTab: true,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Helper Methods
  // ==========================================

  List<VesselSearchModel> _getFilteredVessels(
      List<VesselSearchModel> allVessels,
      String? role,
      int mmsi,
      ) {
    if (_cachedVessels != null &&
        _cachedRole == role &&
        _cachedMmsi == mmsi &&
        _cachedVessels!.length == allVessels.length) {
      return _cachedVessels!;
    }

    // 시스템 관리자(ROLE_ADMIN), 발전단지 운영자(ROLE_OPERATOR)는 모든 선박 표시
    final filtered = role == 'ROLE_USER'
        ? allVessels.where((vessel) => vessel.mmsi == mmsi).toList()
        : allVessels;

    _cachedVessels = filtered;
    _cachedRole = role;
    _cachedMmsi = mmsi;

    return filtered;
  }

  // ==========================================
  // Navigation Handlers
  // ==========================================

  void _onNavItemTapped(int index, BuildContext context) {
    NavigationDebugHelper.debugPrint(
      'Navigation item tapped: $index, current: $selectedIndex',
      location: 'main_screen',
    );

    if (selectedIndex == index) {
      _bottomSheetController?.close();
      _bottomSheetController = null;
      setState(() => selectedIndex = -1);
      _controller.setSelectedIndex(-1);
      return;
    }

    _bottomSheetController?.close();
    setState(() => selectedIndex = index);
    _controller.setSelectedIndex(index);

    switch (index) {
      case 0:
        _showEmergencySheet(context);
        break;
      case 1:
        _showWeatherSheet(context);
        break;
      case 2:
        _showNavigationSheet(context);
        break;
      case 3:
        _navigateToProfile();
        break;
    }
  }

  void _showEmergencySheet(BuildContext context) {
    _bottomSheetController = showBottomSheet(
      context: context,
      builder: (context) => mainViewEmergencySheet(
        context,
        onClose: () {
          setState(() => selectedIndex = -1);
          _controller.setSelectedIndex(-1);
        },
      ),
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
    );

    _bottomSheetController?.closed.then((_) {
      if (mounted && selectedIndex == 0) {
        setState(() => selectedIndex = -1);
        _controller.setSelectedIndex(-1);
      }
    });
  }

  void _showWeatherSheet(BuildContext context) {
    _bottomSheetController = Scaffold.of(context).showBottomSheet(
          (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          setState(() => selectedIndex = -1);
          _controller.setSelectedIndex(-1);
          Navigator.of(context).pop();
        },
        child: MainScreenWindy(
          context,
          onClose: () {
            setState(() => selectedIndex = -1);
            _controller.setSelectedIndex(-1);
          },
        ),
      ),
      backgroundColor: AppColors.blackType3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
    );

    _bottomSheetController?.closed.then((_) {
      if (mounted && selectedIndex == 1) {
        setState(() => selectedIndex = -1);
        _controller.setSelectedIndex(-1);
      }
    });
  }

  void _showNavigationSheet(BuildContext context) {
    _bottomSheetController = showBottomSheet(
      context: context,
      builder: (context) => MainViewNavigationSheet(
        onClose: () {
          if (_bottomSheetController != null) {
            _bottomSheetController?.close();
            _bottomSheetController = null;
          }
          _controller.resetNavigationHistory();
          setState(() => selectedIndex = -1);
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

    _bottomSheetController?.closed.then((_) {
      if (mounted && selectedIndex == 2) {
        _controller.resetNavigationHistory();
        setState(() => selectedIndex = -1);
        _controller.setSelectedIndex(-1);
      }
    });
  }

  void _navigateToProfile() {
    if (mounted) {
      Navigator.push(
        context,
        createSlideTransition(
          MemberInformationView(username: widget.username),
        ),
      ).then((_) {
        setState(() => selectedIndex = -1);
        _controller.setSelectedIndex(-1);
      });
    }
  }

  // ==========================================
  // 선박 다이얼로그 호출
  // ==========================================

  void _showVesselDialog(BuildContext context, VesselSearchModel vessel) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => VesselDialog(
        vessel: vessel,
        onTrackingRequested: () {
          Navigator.of(dialogContext).pop();
          _startVesselTracking(vessel);
        },
      ),
    );
  }

  void _startVesselTracking(VesselSearchModel vessel) {
    _controller.startTracking(vessel.mmsi ?? 0);

    if (vessel.lttd != null && vessel.lntd != null) {
      final vesselLocation = LatLng(vessel.lttd!, vessel.lntd!);
      _controller.mapController.move(vesselLocation, 13.0);
    }

    _loadTodayRoute(vessel.mmsi ?? 0);
  }

  // ==========================================
  // 항적조회
  // ==========================================

  Future<void> _loadTodayRoute(int mmsi) async {
    if (_isLoadingRoute) return;

    setState(() => _isLoadingRoute = true);

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
        setState(() => _isLoadingRoute = false);
      }
    }
  }
}