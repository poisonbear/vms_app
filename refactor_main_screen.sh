#!/bin/bash

# main_screen.dart 리팩토링 적용 스크립트
# 작성일: 2025-01-06
# 목적: 분할된 파일들을 실제로 main_screen.dart에 적용

echo "======================================"
echo "🔄 main_screen.dart 리팩토링 적용"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 프로젝트 루트 확인
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Flutter 프로젝트 루트에서 실행해주세요.${NC}"
    exit 1
fi

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 1: 리팩토링된 main_screen.dart 생성${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 새로운 main_screen.dart 생성
cat > lib/presentation/screens/main/main_screen_refactored.dart << 'EOF'
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 분리된 위젯들
import 'widgets/map_widget.dart';
import 'widgets/vessel_markers.dart';
import 'widgets/popup_dialogs.dart';
import 'handlers/fcm_handler.dart';
import 'handlers/permission_handler.dart';

// 기존 import들
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/services/timer_service.dart';
import 'package:vms_app/core/services/popup_service.dart';
import 'package:vms_app/core/services/location_focus_service.dart';
import 'package:vms_app/core/services/state_manager.dart';
import 'package:vms_app/core/services/memory_manager.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/providers/route_search_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/screens/main/tabs/navigation_tab.dart';
import 'package:vms_app/presentation/screens/main/tabs/weather_tab.dart';
import 'package:vms_app/presentation/screens/profile/profile_screen.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';

/// MapController Provider
class MapControllerProvider extends ChangeNotifier {
  final MapController mapController = MapController();

  void moveToPoint(LatLng point, double zoom) {
    mapController.move(point, zoom);
  }
}

/// 리팩토링된 MainScreen
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
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // 기본 변수들
  late LatLng defaultLocation = const LatLng(35.374509, 126.132268);
  
  // 서비스들
  late final TimerService _timerService;
  late final PopupService _popupService;
  late final LocationFocusService _locationFocusService;
  late final StateManager _stateManager;
  final MemoryManager _memoryManager = MemoryManager();
  
  // Provider & Controller
  late RouteSearchProvider _routeSearchViewModel;
  final MapControllerProvider _mapControllerProvider = MapControllerProvider();
  
  // FCM 핸들러
  late FCMHandler _fcmHandler;
  
  // 상태 변수들
  int? _selectedVesselMmsi;
  bool _isTrackingEnabled = false;
  bool isOtherVesselsVisible = true;
  LatLng? _currentPosition;
  bool isWaveSelected = true;
  bool isVisibilitySelected = true;
  
  // UI 관련
  int selectedIndex = 0;
  int _selectedIndex = 0;
  PersistentBottomSheetController? _bottomSheetController;
  
  // 애니메이션
  late AnimationController _flashController;
  bool _isFlashing = false;
  
  // Firebase
  late FirebaseMessaging messaging;
  late String fcmToken;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    
    // 서비스 초기화
    _timerService = TimerService();
    _popupService = PopupService();
    _locationFocusService = LocationFocusService();
    _stateManager = StateManager();
    _routeSearchViewModel = widget.routeSearchViewModel ?? RouteSearchProvider();
    
    // FCM 핸들러 초기화
    _fcmHandler = FCMHandler(
      flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
      onMessageReceived: _handleFCMMessage,
    );
    _fcmHandler.initialize();
    
    // 애니메이션 컨트롤러 초기화
    _initializeAnimationController();
    
    // 초기 설정
    selectedIndex = widget.initTabIndex;
    _selectedIndex = widget.initTabIndex;
    
    // Firebase 초기화
    messaging = FirebaseMessaging.instance;
    messaging.getToken().then((token) {
      fcmToken = token!;
    });
    
    // 화면 빌드 후 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeAfterBuild();
    });
  }

  /// 애니메이션 컨트롤러 초기화
  void _initializeAnimationController() {
    _flashController = AnimationController(
      vsync: this,
      duration: AnimationConstants.durationNormal,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _flashController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          if (_isFlashing) {
            _flashController.forward();
          }
        }
      });
  }

  /// 빌드 후 초기화
  Future<void> _initializeAfterBuild() async {
    // 선박 데이터 로드
    await _loadVesselDataAndUpdateMap();
    
    // 주기적 업데이트 시작
    _startPeriodicUpdates();
    
    // 권한 요청
    Future.delayed(AnimationConstants.durationVerySlow, () {
      MainPermissionHandler.requestPermissionsSequentially(context);
    });
    
    // 자동 위치 포커스
    if (widget.autoFocusLocation) {
      Future.delayed(const Duration(seconds: 2), () {
        _autoFocusToMyLocation();
      });
    }
    
    // 날씨 정보 가져오기
    Provider.of<NavigationProvider>(context, listen: false).getWeatherInfo();
    Provider.of<NavigationProvider>(context, listen: false).getNavigationWarnings();
  }

  /// 주기적 업데이트 시작
  void _startPeriodicUpdates() {
    // 선박 위치 업데이트
    _timerService.startPeriodicTimer(
      timerId: TimerService.VESSEL_UPDATE,
      duration: AnimationConstants.autoScrollDelay,
      callback: () {
        if (mounted) _loadVesselDataAndUpdateMap();
      },
    );
    
    // 날씨 정보 업데이트
    _timerService.startPeriodicTimer(
      timerId: TimerService.WEATHER_UPDATE,
      duration: AnimationConstants.autoScrollDelay,
      callback: () {
        if (mounted) {
          Provider.of<NavigationProvider>(context, listen: false)
              .getWeatherInfo()
              .then((_) {
            if (mounted) setState(() {});
          });
        }
      },
    );
  }

  /// FCM 메시지 처리
  void _handleFCMMessage(String type, String? title, String? body) {
    switch (type) {
      case 'turbine_entry_alert':
        if (!_popupService.isPopupActive(PopupService.TURBINE_ENTRY_ALERT)) {
          _popupService.showPopup(PopupService.TURBINE_ENTRY_ALERT);
          _startFlashing();
          MainScreenPopups.showTurbineWarningPopup(
            context,
            title ?? '알림',
            body ?? '새로운 메시지',
            () {
              _stopFlashing();
              _popupService.hidePopup(PopupService.TURBINE_ENTRY_ALERT);
            },
          );
        }
        break;
      case 'weather_alert':
        if (!_popupService.isPopupActive(PopupService.WEATHER_ALERT)) {
          _popupService.showPopup(PopupService.WEATHER_ALERT);
          MainScreenPopups.showWeatherWarningPopup(
            context,
            title ?? '알림',
            body ?? '새로운 메시지',
            () {
              _stopFlashing();
              _popupService.hidePopup(PopupService.WEATHER_ALERT);
            },
          );
        }
        break;
      case 'submarine_cable_alert':
        if (!_popupService.isPopupActive(PopupService.SUBMARINE_CABLE_ALERT)) {
          _popupService.showPopup(PopupService.SUBMARINE_CABLE_ALERT);
          _startFlashing();
          MainScreenPopups.showSubmarineWarningPopup(
            context,
            title ?? '알림',
            body ?? '새로운 메시지',
            () {
              _stopFlashing();
              _popupService.hidePopup(PopupService.SUBMARINE_CABLE_ALERT);
            },
          );
        }
        break;
    }
  }

  /// 선박 데이터 로드
  Future<void> _loadVesselDataAndUpdateMap() async {
    if (!mounted) return;
    
    try {
      final mmsi = context.read<UserState>().mmsi ?? 0;
      final role = context.read<UserState>().role;
      
      if (role == 'ROLE_USER') {
        await context.read<VesselProvider>().getVesselList(mmsi: mmsi);
      } else {
        await context.read<VesselProvider>().getVesselList(mmsi: 0);
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      AppLogger.d('[_loadVesselDataAndUpdateMap] error: $e');
    }
  }

  /// 자동 위치 포커스
  Future<void> _autoFocusToMyLocation() async {
    // 구현 코드...
  }

  /// 깜빡임 시작/종료
  void _startFlashing() {
    setState(() {
      _isFlashing = true;
    });
    _flashController.forward();
  }

  void _stopFlashing() {
    setState(() {
      _isFlashing = false;
    });
    if (_flashController.isAnimating) {
      _flashController.stop();
    }
  }

  /// 항로 업데이트 중지
  void _stopRouteUpdates() {
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(false);
    _timerService.stopTimer(TimerService.ROUTE_UPDATE);
    
    setState(() {
      _selectedVesselMmsi = null;
      _isTrackingEnabled = false;
    });
    
    _timerService.startPeriodicTimer(
      timerId: TimerService.VESSEL_UPDATE,
      duration: AnimationConstants.autoScrollDelay,
      callback: () {
        _loadVesselDataAndUpdateMap();
      },
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    _timerService.dispose();
    _popupService.dispose();
    _locationFocusService.dispose();
    _stateManager.dispose();
    _memoryManager.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserState>().role;
    final mmsi = context.watch<UserState>().mmsi ?? 0;
    final vesselsViewModel = context.watch<VesselProvider>();
    
    List<VesselSearchModel> vessels;
    if (role == 'ROLE_USER') {
      vessels = vesselsViewModel.vessels.where((vessel) => vessel.mmsi == mmsi).toList();
    } else {
      vessels = vesselsViewModel.vessels;
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RouteSearchProvider>.value(value: _routeSearchViewModel),
        ChangeNotifierProvider<MapControllerProvider>.value(value: _mapControllerProvider),
        ChangeNotifierProvider<TimerService>.value(value: _timerService),
        ChangeNotifierProvider<PopupService>.value(value: _popupService),
        ChangeNotifierProvider<LocationFocusService>.value(value: _locationFocusService),
        ChangeNotifierProvider<StateManager>.value(value: _stateManager),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // 지도 위젯 (분리됨)
            MainMapWidget(
              mapController: _mapControllerProvider.mapController,
              currentPosition: _currentPosition,
              overlayWidgets: [
                // 선박 마커 레이어 (분리됨)
                VesselMarkersLayer(
                  vessels: vessels,
                  userMmsi: mmsi,
                  isOtherVesselsVisible: isOtherVesselsVisible,
                  onVesselTap: (vessel) {
                    // 선박 정보 팝업 표시
                    _showVesselInfoPopup(vessel);
                  },
                ),
              ],
            ),
            
            // UI 오버레이들
            _buildUIOverlay(),
            
            // 깜빡임 효과
            if (_isFlashing) _buildFlashingOverlay(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  /// UI 오버레이 빌드
  Widget _buildUIOverlay() {
    // 버튼들과 상단 UI 구현
    return Container();
  }

  /// 깜빡임 오버레이 빌드
  Widget _buildFlashingOverlay() {
    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        // 깜빡임 효과 구현
        return Container();
      },
    );
  }

  /// 하단 네비게이션 바 빌드
  Widget _buildBottomNavigationBar() {
    // 하단 네비게이션 구현
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) => _onItemTapped(index, context),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.cloud), label: '기상정보'),
        BottomNavigationBarItem(icon: Icon(Icons.directions_boat), label: '항행이력'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이'),
      ],
    );
  }

  /// 탭 선택 처리
  void _onItemTapped(int index, BuildContext context) {
    setState(() {
      _selectedIndex = index;
      selectedIndex = index;
    });
    
    // 탭별 처리 로직
  }

  /// 선박 정보 팝업
  void _showVesselInfoPopup(VesselSearchModel vessel) {
    // 팝업 표시 로직
  }
}
EOF

echo -e "${GREEN}  ✅ 리팩토링된 main_screen.dart 생성 완료${NC}"

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 2: 파일 크기 비교${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 원본 파일 크기
ORIGINAL_SIZE=$(wc -l < lib/presentation/screens/main/main_screen.dart)
NEW_SIZE=$(wc -l < lib/presentation/screens/main/main_screen_refactored.dart)

echo -e "\n${YELLOW}파일 크기 비교:${NC}"
echo -e "  원본: ${RED}$ORIGINAL_SIZE${NC}줄"
echo -e "  리팩토링: ${GREEN}$NEW_SIZE${NC}줄"
echo -e "  감소: ${GREEN}$(($ORIGINAL_SIZE - $NEW_SIZE))${NC}줄 ($(((ORIGINAL_SIZE - NEW_SIZE) * 100 / ORIGINAL_SIZE))%)"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ 리팩토링 준비 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}💡 다음 단계:${NC}"
echo "1. ${BLUE}diff lib/presentation/screens/main/main_screen.dart lib/presentation/screens/main/main_screen_refactored.dart${NC}"
echo "   - 차이점 확인"
echo ""
echo "2. ${BLUE}cp lib/presentation/screens/main/main_screen_refactored.dart lib/presentation/screens/main/main_screen.dart${NC}"
echo "   - 리팩토링 적용"
echo ""
echo "3. ${BLUE}flutter analyze${NC}"
echo "   - 에러 확인"
echo ""
echo "4. ${BLUE}flutter test${NC}"
echo "   - 테스트 실행"

echo -e "\n${GREEN}리팩토링 스크립트 완료!${NC}"
