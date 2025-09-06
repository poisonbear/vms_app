import 'dart:async';
import 'package:vms_app/core/services/timer_service.dart';
import 'package:vms_app/core/services/popup_service.dart';
import 'package:vms_app/core/services/location_focus_service.dart';
import 'package:vms_app/core/services/state_manager.dart';
import 'package:vms_app/core/services/memory_manager.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/core/utils/permission_manager.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/providers/route_search_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/screens/main/tabs/navigation_tab.dart';
import 'package:vms_app/presentation/screens/main/tabs/weather_tab.dart';
import 'package:vms_app/presentation/screens/profile/profile_screen.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/geo_utils.dart';
import 'utils/location_utils.dart';
import 'widgets/vessel_info_table.dart';
import 'widgets/popup_dialogs.dart';
import 'widgets/bottom_navigation.dart';
import 'widgets/flash_overlay.dart';
import 'widgets/map_control_buttons.dart';

// MapControllerProvider 지도조작을 위한 컨트롤러 생성
class MapControllerProvider extends ChangeNotifier {
  final MapController mapController = MapController();

  void moveToPoint(LatLng point, double zoom) {
    mapController.move(point, zoom);
  }
}

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
  late LatLng defaultLocation = const LatLng(35.374509, 126.132268);

  final Map<String, bool> _activePopups = {
    'turbine_entry_alert': false,
    'weather_alert': false,
    'submarine_cable_alert': false,
  };

  late final PopupService _popupService;
  late final LocationFocusService _locationFocusService;
  late final StateManager _stateManager;
  final MemoryManager _memoryManager = MemoryManager();

  late RouteSearchProvider _routeSearchViewModel;
  final MapControllerProvider _mapControllerProvider = MapControllerProvider();

  int? _selectedVesselMmsi;
  bool _isTrackingEnabled = false;
  bool isOtherVesselsVisible = true;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final MainLocationService _locationService = MainLocationService();
  final MainUpdatePoint _updatePoint = MainUpdatePoint();
  bool positionStreamStarted = false;
  late FirebaseMessaging messaging;
  late String fcmToken;
  LatLng? _currentPosition;

  bool _isFCMListenerRegistered = false;

  late AnimationController _flashController;
  bool _isFlashing = false;

  late final TimerService _timerService;

  void _resetNavigationHistory() {
    _stopRouteUpdates();
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(false);
    setState(() {
      _selectedIndex = 0;
      selectedIndex = 0;
    });
  }

  Future<void> _autoFocusToMyLocation() async {
    try {
      AppLogger.d('🎯 자동 위치 포커스 시작...');

      final prefs = await SharedPreferences.getInstance();
      final isFirstAutoFocus = prefs.getBool('first_auto_focus') ?? true;

      if (!isFirstAutoFocus && !widget.autoFocusLocation) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.d('❌ 위치 권한 거부됨');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.d('❌ 위치 권한이 영구 거부됨');
        showTopSnackBar(context, '설정에서 위치 권한을 허용해주세요.');
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.d('❌ 위치 서비스가 비활성화됨');
        showTopSnackBar(context, '위치 서비스를 활성화해주세요.');
        return;
      }

      AppLogger.d('📍 현재 위치 가져오는 중...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      AppLogger.d('✅ 위치 획득 - 위도: ${position.latitude}, 경도: ${position.longitude}');

      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        _mapControllerProvider.mapController.move(currentLocation, 13.0);
        setState(() {
          _currentPosition = currentLocation;
        });

        await prefs.setBool('first_auto_focus', false);
        showTopSnackBar(context, '현재 위치로 이동했습니다.');
      }
    } catch (e) {
      AppLogger.e('❌ 자동 위치 포커스 오류: $e');

      if (mounted) {
        defaultLocation = const LatLng(35.374509, 126.132268);
        _mapControllerProvider.mapController.move(defaultLocation, 12.0);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _timerService = TimerService();
    _popupService = PopupService();
    _locationFocusService = LocationFocusService();
    _stateManager = StateManager();
    _routeSearchViewModel = widget.routeSearchViewModel ?? RouteSearchProvider();

    selectedIndex = widget.initTabIndex;
    _selectedIndex = widget.initTabIndex;

    messaging = FirebaseMessaging.instance;

    messaging.getToken().then((token) {
      fcmToken = token!;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadVesselDataAndUpdateMap();
      _timerService.startPeriodicTimer(
          timerId: "vessel_update",
          duration: AnimationConstants.autoScrollDelay,
          callback: () {
            if (!mounted) return;
            _loadVesselDataAndUpdateMap();
          });
    });

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(AnimationConstants.durationVerySlow, () {
        _requestPermissionsSequentially();
      });

      if (widget.autoFocusLocation) {
        Future.delayed(const Duration(seconds: 2), () {
          _autoFocusToMyLocation();
        });
      }
    });

    if (!_isFCMListenerRegistered) {
      _isFCMListenerRegistered = true;

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final data = message.data;
        final type = data['type'];

        _showForegroundNotification(message);

        if (type == 'turbine_entry_alert' &&
            !_popupService.isPopupActive(PopupService.TURBINE_ENTRY_ALERT)) {
          _popupService.showPopup(PopupService.TURBINE_ENTRY_ALERT);
          _startFlashing();
          MainScreenPopups.showTurbineWarningPopup(
              context,
              message.notification?.title ?? '알림',
              message.notification?.body ?? '새로운 메시지',
                  () {
                _stopFlashing();
                _popupService.hidePopup(PopupService.TURBINE_ENTRY_ALERT);
              });
        } else if (type == 'weather_alert' &&
            !_popupService.isPopupActive(PopupService.WEATHER_ALERT)) {
          _popupService.showPopup(PopupService.WEATHER_ALERT);
          MainScreenPopups.showWeatherWarningPopup(
              context,
              message.notification?.title ?? '알림',
              message.notification?.body ?? '새로운 메시지',
                  () {
                _stopFlashing();
                _popupService.hidePopup(PopupService.WEATHER_ALERT);
              });
        } else if (type == 'submarine_cable_alert' &&
            !_popupService.isPopupActive(PopupService.SUBMARINE_CABLE_ALERT)) {
          _popupService.showPopup(PopupService.SUBMARINE_CABLE_ALERT);
          _startFlashing();
          MainScreenPopups.showSubmarineWarningPopup(
              context,
              message.notification?.title ?? '알림',
              message.notification?.body ?? '새로운 메시지',
                  () {
                _stopFlashing();
                _popupService.hidePopup(PopupService.SUBMARINE_CABLE_ALERT);
              });
        }
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});

    Provider.of<NavigationProvider>(context, listen: false).getWeatherInfo();

    _timerService.startPeriodicTimer(
        timerId: "main_timer",
        duration: AnimationConstants.autoScrollDelay,
        callback: () {
          Provider.of<NavigationProvider>(context, listen: false)
              .getWeatherInfo()
              .then((_) {
            if (mounted) {
              setState(() {});
            }
          }).catchError((error) {});
        });

    Provider.of<NavigationProvider>(context, listen: false)
        .getNavigationWarnings();
  }

  // 선박정보 팝업 함수 (올바르게 수정됨)
  Future<void> routePop(BuildContext context, VesselSearchModel vessel) {
    double currentZoom = _mapControllerProvider.mapController.camera.zoom;
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: getSize300()),
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: getSize26().toDouble(),
                left: getSize20().toDouble(),
                right: getSize20().toDouble(),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(getSize20().toDouble()),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: getSize10().toDouble(),
                          offset: Offset(getSize0().toDouble(), getSize4().toDouble()),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            TextWidgetString('선박 정보', getTextleft(), getSize24(),
                                getTextbold(), getColorblack_type1()),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Icon(Icons.close, color: getColorgray_Type8()),
                            ),
                          ],
                        ),
                        SizedBox(height: getSize16().toDouble()),
                        VesselInfoTable(
                          shipName: vessel.ship_nm,
                          mmsi: vessel.mmsi,
                          vesselType: vessel.ship_knd,
                          draft: vessel.draft,
                          sog: vessel.sog,
                          cog: vessel.cog,
                        ),
                        SizedBox(height: getSize20().toDouble()),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // 항로 조회 로직
                                _selectedVesselMmsi = vessel.mmsi;
                                _isTrackingEnabled = true;
                                // 항로 업데이트 시작
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: getColorsky_Type2(),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(DesignConstants.radiusS),
                                ),
                              ),
                              child: TextWidgetString('항로 조회', getTextcenter(), getSize16(),
                                  getText600(), getColorwhite_type1()),
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

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      AppLogger.d('[_loadVesselDataAndUpdateMap] error: $e');
    }
  }

  Future<void> _requestPermissionsSequentially() async {
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always) {
      AppLogger.d('✅ 이미 위치 권한이 허용되어 있습니다.');
      await _updateCurrentLocation();
    } else {
      await Future.delayed(AnimationConstants.durationNormal);
      await PointRequestUtil.requestPermissionUntilGranted(context);
      await _updateCurrentLocation();
    }

    NotificationSettings notifSettings =
    await FirebaseMessaging.instance.getNotificationSettings();
    if (notifSettings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.d('✅ 이미 알림 권한이 허용되어 있습니다.');
    } else {
      await Future.delayed(AnimationConstants.durationNormal);
      await NotificationRequestUtil.requestPermissionUntilGranted(context);
      await _requestNotificationPermission();
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    _timerService.dispose();
    _popupService.dispose();
    _locationFocusService.dispose();
    _stateManager.dispose();
    _memoryManager.disposeAll();
    _timerService.stopTimer(TimerService.WEATHER_UPDATE);
    _timerService.stopTimer(TimerService.ROUTE_UPDATE);
    _timerService.stopTimer(TimerService.VESSEL_UPDATE);
    super.dispose();
  }

  void _stopRouteUpdates() {
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(false);

    _timerService.stopTimer(TimerService.ROUTE_UPDATE);

    setState(() {
      _selectedVesselMmsi = null;
      _isTrackingEnabled = false;
    });

    _timerService.startPeriodicTimer(
      timerId: "vessel_update",
      duration: AnimationConstants.autoScrollDelay,
      callback: () {
        _loadVesselDataAndUpdateMap();
      },
    );
  }

  Future<void> _requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.d('✅ 알림 권한 허용됨');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.d('❌ 알림 권한 거부됨');
    } else {
      AppLogger.d('⚠️ 알림 권한 상태: ${settings.authorizationStatus}');
    }
  }

  Future<void> _updateCurrentLocation() async {
    Position? position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final int notificationId =
    DateTime.now().millisecondsSinceEpoch.remainder(100000);

    AndroidNotificationDetails androidPlatformChannelSpecifics =
    const AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: '중요 알림을 위한 채널입니다.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      styleInformation: BigTextStyleInformation(''),
    );

    NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      message.notification?.title ?? '알림',
      message.notification?.body ?? '알림 내용이 없습니다.',
      platformChannelSpecifics,
    );
  }

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

  int selectedIndex = 0;
  Color getItemColor(int index) {
    return selectedIndex == index
        ? getColorgray_Type8()
        : getColorblack_type2();
  }

  int _selectedIndex = 0;
  PersistentBottomSheetController? _bottomSheetController;

  void _onItemTapped(int index, BuildContext context) {
    setState(() {
      _selectedIndex = index;
      selectedIndex = index;
    });

    if (_bottomSheetController != null) {
      _bottomSheetController!.close();
      _bottomSheetController = null;
    }

    _stopRouteUpdates();
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(true);

    if (index != 0) {
      if (index == 1) {
        _bottomSheetController = Scaffold.of(context).showBottomSheet(
              (context) => WillPopScope(
            onWillPop: () async {
              setState(() {
                _selectedIndex = 0;
                selectedIndex = 0;
              });
              return true;
            },
            child: MainScreenWindy(context, onClose: () {
              setState(() {
                _selectedIndex = 0;
                selectedIndex = 0;
              });
            }),
          ),
          backgroundColor: getColorblack_type3(),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
        );
      } else if (index == 2) {
        _bottomSheetController = Scaffold.of(context).showBottomSheet(
              (context) => WillPopScope(
            onWillPop: () async {
              _resetNavigationHistory();
              return true;
            },
            child: MainViewNavigationSheet(
              onClose: () {
                _resetNavigationHistory();
              },
              resetDate: true,
              resetSearch: true,
            ),
          ),
          backgroundColor: getColorblack_type3(),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
        );

        _bottomSheetController?.closed.then((_) {
          _resetNavigationHistory();
        });
      } else if (index == 3) {
        Navigator.push(
          context,
          createSlideTransition(
            MemberInformationView(
              username: widget.username,
            ),
          ),
        ).then((_) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
        });
      }
    }
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
        ChangeNotifierProvider<RouteSearchProvider>.value(
          value: _routeSearchViewModel,
        ),
        ChangeNotifierProvider<MapControllerProvider>.value(
          value: _mapControllerProvider,
        ),
        ChangeNotifierProvider<TimerService>.value(value: _timerService),
        ChangeNotifierProvider<PopupService>.value(value: _popupService),
        ChangeNotifierProvider<LocationFocusService>.value(
            value: _locationFocusService),
        ChangeNotifierProvider<StateManager>.value(value: _stateManager),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // 1. 지도 레이어
            Consumer<RouteSearchProvider>(
              builder: (context, routeSearchViewModel, child) {
                final mapController =
                    Provider.of<MapControllerProvider>(context).mapController;

                int cnt = 20;
                if ((routeSearchViewModel.pastRoutes.length ?? 0) <= cnt) {
                  cnt = 1;
                }

                var pastRouteLine = <LatLng>[];

                if (routeSearchViewModel.pastRoutes.isNotEmpty == true) {
                  final firstPoint = routeSearchViewModel.pastRoutes.first;
                  pastRouteLine
                      .add(LatLng(firstPoint.lttd ?? 0, firstPoint.lntd ?? 0));

                  if ((routeSearchViewModel.pastRoutes.length ?? 0) > 2) {
                    for (int i = 1;
                    i < (routeSearchViewModel.pastRoutes.length ?? 0) - 1;
                    i++) {
                      if (i % cnt == 0) {
                        final route = routeSearchViewModel.pastRoutes[i];
                        pastRouteLine
                            .add(LatLng(route.lttd ?? 0, route.lntd ?? 0));
                      }
                    }
                  }

                  final lastPoint = routeSearchViewModel.pastRoutes.last;
                  pastRouteLine
                      .add(LatLng(lastPoint.lttd ?? 0, lastPoint.lntd ?? 0));
                }

                var predRouteLine = <LatLng>[];
                predRouteLine.addAll((routeSearchViewModel.predRoutes ?? [])
                    .map((route) => LatLng(route.lttd ?? 0, route.lntd ?? 0))
                    .toList());

                if (predRouteLine.isNotEmpty) {
                  pastRouteLine.add(predRouteLine.first);
                }

                if (!_isTrackingEnabled &&
                    routeSearchViewModel.isNavigationHistoryMode != true) {
                  pastRouteLine.clear();
                  predRouteLine.clear();
                }

                return FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter:
                    _currentPosition ?? const LatLng(35.374509, 126.132268),
                    initialZoom: 12.0,
                    maxZoom: 14.0,
                    minZoom: 5.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onPositionChanged:
                        (MapPosition position, bool hasGesture) {},
                  ),
                  children: [
                    // WMS 타일 레이어들
                    TileLayer(
                      wmsOptions: WMSTileLayerOptions(
                        baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                        layers: const ['vms_space:enc_map'],
                        format: 'image/png',
                        transparent: true,
                        version: '1.1.1',
                      ),
                    ),
                    TileLayer(
                      wmsOptions: WMSTileLayerOptions(
                        baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                        layers: const ['vms_space:t_enc_sou_sp01'],
                        format: 'image/png',
                        transparent: true,
                        version: '1.1.1',
                      ),
                    ),
                    TileLayer(
                      wmsOptions: WMSTileLayerOptions(
                        baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                        layers: const ['vms_space:t_gis_tur_sp01'],
                        format: 'image/png',
                        transparent: true,
                        version: '1.1.1',
                      ),
                    ),
                    // 과거항적 선 레이어
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: pastRouteLine,
                          strokeWidth: 1.0,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    // 과거항적 포인트 레이어
                    MarkerLayer(
                      markers: pastRouteLine.asMap().entries.map((entry) {
                        int index = entry.key;
                        LatLng point = entry.value;

                        if (index == 0) {
                          return Marker(
                            point: point,
                            width: 10,
                            height: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                                border:
                                Border.all(color: Colors.white, width: 1),
                              ),
                            ),
                          );
                        } else {
                          return Marker(
                            point: point,
                            width: 4,
                            height: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                                border:
                                Border.all(color: Colors.white, width: 0.5),
                              ),
                            ),
                          );
                        }
                      }).toList(),
                    ),
                    // 예측항로 선 레이어
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: predRouteLine,
                          strokeWidth: 1.0,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    // 예측항로 포인트 레이어
                    MarkerLayer(
                      markers: predRouteLine.map((point) {
                        return Marker(
                          point: point,
                          width: 4,
                          height: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: Colors.white, width: 0.5),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // 퇴각항로 레이어
                    PolylineLayer(
                      polylineCulling: false,
                      polylines: vessels
                          .where((v) => v.escapeRouteGeojson != null)
                          .map((v) {
                        final pts = GeoUtils.parseGeoJsonLineString(
                            v.escapeRouteGeojson ?? '');
                        return Polyline(
                          points: pts,
                          strokeWidth: 2.0,
                          color: Colors.black,
                          isDotted: true,
                        );
                      }).toList(),
                    ),
                    // 퇴각항로 끝점 삼각형
                    PolygonLayer(
                      polygons: vessels
                          .where((v) => v.escapeRouteGeojson != null)
                          .map((v) {
                        final pts = GeoUtils.parseGeoJsonLineString(
                            v.escapeRouteGeojson ?? '');
                        if (pts.length < 2) return null;
                        final end = pts.last;
                        final prev = pts[pts.length - 2];

                        final dx = end.longitude - prev.longitude;
                        final dy = end.latitude - prev.latitude;
                        final dist = sqrt(dx * dx + dy * dy);
                        if (dist == 0) return null;
                        final ux = dx / dist;
                        final uy = dy / dist;

                        final vx = -uy;
                        final vy = ux;

                        double size = 0.0005;

                        final apex = LatLng(
                          end.latitude + uy * size,
                          end.longitude + ux * size,
                        );

                        final baseCenter = LatLng(
                          end.latitude - uy * (size * 0.5),
                          end.longitude - ux * (size * 0.5),
                        );

                        final halfWidth = size / sqrt(3);

                        final b1 = LatLng(
                          baseCenter.latitude + vy * halfWidth,
                          baseCenter.longitude + vx * halfWidth,
                        );
                        final b2 = LatLng(
                          baseCenter.latitude - vy * halfWidth,
                          baseCenter.longitude - vx * halfWidth,
                        );

                        return Polygon(
                          points: [apex, b1, b2],
                          color: Colors.black,
                          borderColor: Colors.black,
                          borderStrokeWidth: 1,
                          isFilled: true,
                        );
                      })
                          .where((poly) => poly != null)
                          .cast<Polygon>()
                          .toList(),
                    ),
                    // 현재 선박 레이어
                    MarkerLayer(
                      markers: vessels
                          .where((vessel) => (vessel.mmsi ?? 0) == mmsi)
                          .map((vessel) {
                        return Marker(
                          point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
                          width: 25,
                          height: 25,
                          child: Transform.rotate(
                            angle: (vessel.cog ?? 0) * (pi / 180),
                            child: SvgPicture.asset(
                              'assets/kdn/home/img/myVessel.svg',
                              width: 40,
                              height: 40,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // 다른 선박 레이어
                    Opacity(
                      opacity: isOtherVesselsVisible ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !isOtherVesselsVisible,
                        child: MarkerLayer(
                          markers: vessels
                              .where((vessel) => (vessel.mmsi ?? 0) != mmsi)
                              .map((vessel) {
                            return Marker(
                              point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
                              width: 25,
                              height: 25,
                              child: GestureDetector(
                                onTap: () {
                                  routePop(context, vessel);
                                },
                                child: Transform.rotate(
                                  angle: (vessel.cog ?? 0) * (pi / 180),
                                  child: SvgPicture.asset(
                                    'assets/kdn/home/img/otherVessel.svg',
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // 2. 상단 파고/시정 버튼 (위젯 사용)
            const WeatherControlButtons(),

            // 3. 우측 하단 지도 컨트롤 버튼 (위젯 사용)
            MapControlButtons(
              isOtherVesselsVisible: isOtherVesselsVisible,
              onOtherVesselsToggle: () {
                setState(() {
                  isOtherVesselsVisible = !isOtherVesselsVisible;
                });
              },
              mapController: _mapControllerProvider.mapController,
              onHomeButtonTap: (context) {
                _mapControllerProvider.mapController.moveAndRotate(
                    const LatLng(35.374509, 126.132268),
                    12.0,
                    0.0
                );
              },
            ),

            // 4. Refresh 버튼 (독립적으로 유지)
            Positioned(
              right: getSize20().toDouble(),
              top: MediaQuery.of(context).size.height / 2 - 100,
              child: Consumer<RouteSearchProvider>(
                builder: (context, routeViewModel, _) {
                  if ((routeViewModel.pastRoutes.isNotEmpty == true ||
                      (routeViewModel.predRoutes.isNotEmpty == true)) &&
                      routeViewModel.isNavigationHistoryMode != true &&
                      _isTrackingEnabled) {
                    return CircularButton(
                      svgPath: 'assets/kdn/home/img/refresh.svg',
                      colorOn: getColorgray_Type8(),
                      colorOff: getColorgray_Type8(),
                      widthSize: getSize56(),
                      heightSize: getSize56(),
                      onTap: () {
                        _stopRouteUpdates();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('항적 데이터가 초기화되었습니다.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
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
                    height: 52,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignConstants.spacing12),
                    decoration: BoxDecoration(
                      color: getColorred_type1(),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/kdn/ros/img/circle-exclamation_white.svg',
                          width: 24,
                          height: 24,
                        ),
                        SizedBox(width: getSize8().toDouble()),
                        Expanded(
                          child: Marquee(
                            text: viewModel.combinedNavigationWarnings,
                            style: TextStyle(
                              color: getColorwhite_type1(),
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
              isFlashing: _isFlashing,
            ),
          ],
        ),
        bottomNavigationBar: MainBottomNavigation(
          selectedIndex: selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}