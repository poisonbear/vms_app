import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';
import 'package:vms_app/presentation/screens/main/tabs/navigation_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/providers/route_search_provider.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import '../controllers/main_screen_controller.dart';
import '../utils/navigation_debug.dart';

String selectedStartDate =
    "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
String selectedEndDate =
    "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

class MainViewNavigationSheet extends StatefulWidget {
  final Function? onClose;
  final bool resetDate;
  final bool resetSearch;
  final bool initialSearch;

  const MainViewNavigationSheet({
    super.key,
    this.onClose,
    this.resetDate = true,
    this.resetSearch = true,
    this.initialSearch = true,
  });

  @override
  _MainViewNavigationSheetState createState() =>
      _MainViewNavigationSheetState();
}

class _MainViewNavigationSheetState extends State<MainViewNavigationSheet> {
  late TextEditingController mmsiController;
  late TextEditingController shipNameController;
  late NavigationProvider navigationViewModel;
  PersistentBottomSheetController? _bottomSheetController;
  bool _isClosing = false;

  static NavigationProvider? _sharedNavigationProvider;
  static String? _savedMmsi;
  static String? _savedShipName;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    mmsiController = TextEditingController();
    shipNameController = TextEditingController();

    NavigationDebugHelper.debugPrint('NavigationSheet initState', location: 'nav_tab');

    if (widget.resetSearch) {
      mmsiController.clear();
      shipNameController.clear();
      _savedMmsi = null;
      _savedShipName = null;
    } else {
      if (_savedMmsi != null) {
        mmsiController.text = _savedMmsi!;
      }
      if (_savedShipName != null) {
        shipNameController.text = _savedShipName!;
      }
    }

    mmsiController.addListener(() {
      _savedMmsi = mmsiController.text;
    });
    shipNameController.addListener(() {
      _savedShipName = shipNameController.text;
    });

    if (widget.resetDate) {
      final today = DateTime.now();
      selectedStartDate =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      selectedEndDate =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    }

    if (widget.resetSearch || widget.resetDate) {
      navigationViewModel = NavigationProvider();
      _sharedNavigationProvider = navigationViewModel;
    } else {
      navigationViewModel = _sharedNavigationProvider ?? NavigationProvider();
      _sharedNavigationProvider ??= navigationViewModel;
    }

    if (widget.initialSearch) {
      final mmsi = context.read<UserState>().mmsi;
      final role = context.read<UserState>().role;

      navigationViewModel.getRosList(
          startDate: selectedStartDate,
          endDate: selectedEndDate,
          mmsi: role == 'ROLE_USER'
              ? mmsi
              : (mmsiController.text.isEmpty
              ? null
              : int.tryParse(mmsiController.text)),
          shipName: shipNameController.text.isEmpty
              ? null
              : shipNameController.text.toUpperCase()
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationDebugHelper.checkProviderAccess(context, 'nav_tab.postFrame');
    });
  }

  @override
  void dispose() {
    mmsiController.dispose();
    shipNameController.dispose();
    _bottomSheetController?.close();
    super.dispose();
  }

  void refreshDates() {
    if (mounted) {
      setState(() {});
    }
  }

  void _quickSelectDate(int days) {
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: days));

    setState(() {
      selectedStartDate = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      selectedEndDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    });

    _performSearch();
  }

  void _performSearch() {
    final mmsi = context.read<UserState>().mmsi;
    final role = context.read<UserState>().role;

    navigationViewModel.getRosList(
      startDate: selectedStartDate,
      endDate: selectedEndDate,
      mmsi: role == 'ROLE_USER'
          ? mmsi
          : (mmsiController.text.isEmpty
          ? null
          : int.tryParse(mmsiController.text)),
      shipName: shipNameController.text.isEmpty
          ? null
          : shipNameController.text.toUpperCase(),
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _performSearch();
  }

  void _handleClose(BuildContext context) {
    try {
      if (widget.onClose != null) {
        widget.onClose!();
      }

      final mainScreenState = context.findAncestorStateOfType<State<MainScreen>>();
      if (mainScreenState != null) {
        try {
          (mainScreenState as dynamic).selectedIndex = -1;
        } catch (e) {
          // 에러 무시
        }
      }

      if (mounted) {
        try {
          final routeSearchViewModel = Provider.of<RouteSearchProvider>(context, listen: false);
          routeSearchViewModel.clearRoutes();
          routeSearchViewModel.setNavigationHistoryMode(false);
        } catch (e) {
          // Provider 접근 실패 시 에러 무시
        }
      }

      if (mounted) {
        setState(() {
          _isClosing = true;
        });
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      NavigationDebugHelper.debugPrint('닫기 버튼 오류: $e', location: 'nav_tab.close_error');
    }
  }

  @override
  Widget build(BuildContext context) {
    NavigationDebugHelper.debugPrint('NavigationSheet build', location: 'nav_tab.build');
    NavigationDebugHelper.checkProviderAccess(context, 'nav_tab.build');

    final routeSearchViewModel = Provider.of<RouteSearchProvider>(context, listen: false);

    return PopScope(
      canPop: _isClosing,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop || _isClosing) return;

        _handleClose(context);
      },
      child: ChangeNotifierProvider.value(
        value: navigationViewModel,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.81,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: DesignConstants.spacing20,
                    horizontal: DesignConstants.spacing16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(DesignConstants.radiusXL),
                    topRight: Radius.circular(DesignConstants.radiusXL),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        TextWidgetString('항행 이력 내역 조회', getTextleft(),
                            getSizeInt20(), getText700(), getColorBlackType2()),
                        const Spacer(),
                        SizedBox(
                          width: getSize24(),
                          height: getSize24(),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () => _handleClose(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: getSize10()),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickDateButton('오늘', () => _quickSelectDate(0)),
                          SizedBox(width: getSize8()),
                          _buildQuickDateButton('어제', () => _quickSelectDate(1)),
                          SizedBox(width: getSize8()),
                          _buildQuickDateButton('최근 7일', () => _quickSelectDate(7)),
                          SizedBox(width: getSize8()),
                          _buildQuickDateButton('최근 30일', () => _quickSelectDate(30)),
                          SizedBox(width: getSize8()),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                final today = DateTime.now();
                                selectedStartDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
                                selectedEndDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

                                mmsiController.clear();
                                shipNameController.clear();
                                _savedMmsi = null;
                                _savedShipName = null;

                                navigationViewModel = NavigationProvider();
                                _sharedNavigationProvider = navigationViewModel;
                              });

                              _performSearch();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: getColorSkyType2(),
                              padding: EdgeInsets.symmetric(
                                horizontal: getSize12(),
                                vertical: getSize8(),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(getSize4()),
                              ),
                            ),
                            child: Icon(Icons.refresh, size: getSize20(), color: getColorWhiteType1()),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: getSize10()),

                    Container(
                      padding: EdgeInsets.all(getSize12()),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(getSize8()),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MainViewNavigationDate(
                                          title: '항행이력',
                                          onClose: (startDate, endDate) {
                                            setState(() {
                                              selectedStartDate = startDate;
                                              selectedEndDate = endDate;
                                            });
                                            _performSearch();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: getSize12(),
                                        vertical: getSize10()),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: getColorGrayType5(),
                                          width: getSize1()),
                                      borderRadius:
                                      BorderRadius.circular(getSize4()),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextWidgetString(
                                          selectedStartDate,
                                          getTextleft(),
                                          getSizeInt14(),
                                          getText400(),
                                          getColorBlackType2(),
                                        ),
                                        Icon(Icons.calendar_today,
                                            size: getSize16(),
                                            color: getColorGrayType3()),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: getSize8()),
                                child: TextWidgetString('~', getTextcenter(),
                                    getSizeInt16(), getText400(), getColorBlackType2()),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MainViewNavigationDate(
                                          title: '항행이력',
                                          onClose: (startDate, endDate) {
                                            setState(() {
                                              selectedStartDate = startDate;
                                              selectedEndDate = endDate;
                                            });
                                            _performSearch();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: getSize12(),
                                        vertical: getSize10()),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: getColorGrayType5(),
                                          width: getSize1()),
                                      borderRadius:
                                      BorderRadius.circular(getSize4()),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextWidgetString(
                                          selectedEndDate,
                                          getTextleft(),
                                          getSizeInt14(),
                                          getText400(),
                                          getColorBlackType2(),
                                        ),
                                        Icon(Icons.calendar_today,
                                            size: getSize16(),
                                            color: getColorGrayType3()),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Consumer<UserState>(
                            builder: (context, userState, child) {
                              if (userState.role != 'ROLE_USER') {
                                return Column(
                                  children: [
                                    SizedBox(height: getSize10()),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: mmsiController,
                                            decoration: InputDecoration(
                                              hintText: 'MMSI',
                                              hintStyle: TextStyle(
                                                  fontSize: getSize14(),
                                                  color: getColorGrayType3()),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    getSize4()),
                                                borderSide: BorderSide(
                                                    color: getColorGrayType5(),
                                                    width: getSize1()),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    getSize4()),
                                                borderSide: BorderSide(
                                                    color: getColorGrayType5(),
                                                    width: getSize1()),
                                              ),
                                              contentPadding: EdgeInsets.symmetric(
                                                  horizontal: getSize12(),
                                                  vertical: getSize10()),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        SizedBox(width: getSize10()),
                                        Expanded(
                                          child: TextField(
                                            controller: shipNameController,
                                            decoration: InputDecoration(
                                              hintText: '선박명',
                                              hintStyle: TextStyle(
                                                  fontSize: getSize14(),
                                                  color: getColorGrayType3()),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    getSize4()),
                                                borderSide: BorderSide(
                                                    color: getColorGrayType5(),
                                                    width: getSize1()),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    getSize4()),
                                                borderSide: BorderSide(
                                                    color: getColorGrayType5(),
                                                    width: getSize1()),
                                              ),
                                              contentPadding: EdgeInsets.symmetric(
                                                  horizontal: getSize12(),
                                                  vertical: getSize10()),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          SizedBox(height: getSize10()),
                          ElevatedButton(
                            onPressed: () {
                              _performSearch();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: getColorSkyType2(),
                              minimumSize: Size(double.infinity, getSize44()),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(getSize4()),
                              ),
                            ),
                            child: TextWidgetString('조회', getTextcenter(),
                                getSizeInt16(), getText600(), getColorWhiteType1()),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: getSize10()),

                    Expanded(
                      child: RefreshIndicator(
                        key: _refreshIndicatorKey,
                        onRefresh: _onRefresh,
                        child: Consumer<NavigationProvider>(
                          builder: (context, provider, child) {
                            if (provider.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (provider.rosList.isEmpty) {
                              return Center(
                                child: TextWidgetString(
                                  '검색 결과가 없습니다',
                                  getTextcenter(),
                                  getSizeInt16(),
                                  getText400(),
                                  getColorGrayType3(),
                                ),
                              );
                            }

                            return _buildNavigationList(provider, routeSearchViewModel);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: getColorWhiteType1(),
        padding: EdgeInsets.symmetric(
          horizontal: getSize12(),
          vertical: getSize8(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(getSize4()),
          side: BorderSide(color: getColorGrayType5(), width: getSize1()),
        ),
      ),
      child: TextWidgetString(
        label,
        getTextcenter(),
        getSizeInt12(),
        getText400(),
        getColorBlackType2(),
      ),
    );
  }

  Widget _buildNavigationList(
      NavigationProvider provider, RouteSearchProvider routeSearchViewModel) {
    return ListView.builder(
      itemCount: provider.rosList.length,
      itemBuilder: (context, index) {
        final nav = provider.rosList[index];
        final shipNm = nav.shipName ?? '';
        final mmsi = nav.mmsi?.toString() ?? '';
        final regDt = nav.reg_dt ?? nav.odb_reg_date;
        final formattedTime = regDt != null && regDt.toString().length >= 12
            ? '${regDt.toString().substring(0, 4)}-${regDt.toString().substring(4, 6)}-${regDt.toString().substring(6, 8)} ${regDt.toString().substring(8, 10)}:${regDt.toString().substring(10, 12)}'
            : '';

        return GestureDetector(
          onTap: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext navigationContext) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            try {
              final viewModel = routeSearchViewModel;
              viewModel.clearRoutes();
              viewModel.setNavigationHistoryMode(false);

              await viewModel.getVesselRoute(
                  regDt: regDt != null && regDt.toString().length >= 8
                      ? "${regDt.toString().substring(0, 4)}-${regDt.toString().substring(4, 6)}-${regDt.toString().substring(6, 8)}"
                      : null,
                  mmsi: int.tryParse(mmsi));

              NavigationDebugHelper.debugPrint(
                  'API 호출 후 - past: ${viewModel.pastRoutes.length}, pred: ${viewModel.predRoutes.length}',
                  location: 'nav_tab.afterAPI'
              );

              if (viewModel.pastRoutes.isNotEmpty) {
                LatLng firstPoint = LatLng(
                    viewModel.pastRoutes.last.lttd ?? 35.3790988,
                    viewModel.pastRoutes.last.lntd ?? 126.167763);

                try {
                  final mainController = Provider.of<MainScreenController>(context, listen: false);
                  mainController.mapController.move(firstPoint, 12.0);
                } catch (e) {
                  NavigationDebugHelper.debugPrint("지도 이동 실패: $e", location: "nav_tab.mapError");
                }
              }

              Navigator.of(context).pop();

              Scaffold.of(context).showBottomSheet(
                    (context) => GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 0) {
                      viewModel.clearRoutes();
                      viewModel.setNavigationHistoryMode(false);

                      final mainScreenStat =
                      context.findAncestorStateOfType<State<MainScreen>>();
                      if (mainScreenStat != null) {
                        try {
                          (mainScreenStat as dynamic).selectedIndex = -1;
                        } catch (e) {}
                      }

                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (bool didPop, dynamic result) {
                      if (didPop) return;

                      final mainScreenStat =
                      context.findAncestorStateOfType<State<MainScreen>>();
                      if (mainScreenStat != null) {
                        try {
                          (mainScreenStat as dynamic).selectedIndex = -1;
                        } catch (e) {}
                      }

                      viewModel.clearRoutes();
                      viewModel.setNavigationHistoryMode(false);
                      Navigator.of(context).pop();
                    },
                    child: _buildCollapsedBottomSheet(
                        context, shipNm, mmsi, formattedTime, viewModel),
                  ),
                ),
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(DesignConstants.radiusXL)),
                ),
              );
            } catch (e) {
              NavigationDebugHelper.debugPrint('에러 발생: $e', location: 'nav_tab.error');

              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다.')),
                );
              }
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: getSize12()),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(getSize4()),
              border: Border.all(color: getColorGrayType4(), width: getSize1()),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: getSize16(),
                  horizontal: getSize12()),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidgetString(shipNm, getTextleft(), getSizeInt16(),
                            getText700(), getColorBlackType2()),
                        SizedBox(height: getSize4()),
                        Row(
                          children: [
                            TextWidgetString(
                                'MMSI ',
                                getTextleft(),
                                getSizeInt12(),
                                getText400(),
                                getColorGrayType3()),
                            TextWidgetString(mmsi, getTextleft(), getSizeInt12(),
                                getText600(), getColorGrayType3()),
                            SizedBox(width: getSize12()),
                            TextWidgetString(
                                'DATE ',
                                getTextleft(),
                                getSizeInt12(),
                                getText400(),
                                getColorGrayType3()),
                            TextWidgetString(
                                formattedTime,
                                getTextleft(),
                                getSizeInt12(),
                                getText600(),
                                getColorGrayType3()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: getColorGrayType8(), size: getSize20()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _buildCollapsedBottomSheet(
    BuildContext context,
    String shipNm,
    String mmsi,
    String formattedTime,
    RouteSearchProvider viewModel,
    ) {
  String timeRange = '';
  if (viewModel.pastRoutes.isNotEmpty) {
    try {
      final firstRoute = viewModel.pastRoutes.first;
      final lastRoute = viewModel.pastRoutes.last;

      if (firstRoute.regDt != null && lastRoute.regDt != null) {
        final startTime = firstRoute.regDt.toString();
        final endTime = lastRoute.regDt.toString();

        if (startTime.length >= 14 && endTime.length >= 14) {
          final startFormatted = '${startTime.substring(8, 10)}:${startTime.substring(10, 12)}';
          final endFormatted = '${endTime.substring(8, 10)}:${endTime.substring(10, 12)}';
          timeRange = '$startFormatted ~ $endFormatted';
        }
      }
    } catch (e) {
      NavigationDebugHelper.debugPrint('시간 범위 파싱 실패: $e', location: 'nav_tab');
    }
  }

  return Container(
    height: getSize80(),
    width: double.infinity,
    padding: EdgeInsets.symmetric(
        horizontal: getSize16(), vertical: getSize12()),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignConstants.radiusXL),
          topRight: Radius.circular(DesignConstants.radiusXL)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextWidgetString(
                shipNm,
                getTextleft(),
                getSizeInt16(),
                getText700(),
                getColorBlackType2(),
              ),
              const SizedBox(height: 4),
              TextWidgetString(
                'MMSI: $mmsi',
                getTextleft(),
                getSizeInt12(),
                getText400(),
                getColorGrayType3(),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: getColorGrayType14(),
                borderRadius: BorderRadius.circular(getSize8()),
              ),
              child: IconButton(
                icon: SvgPicture.asset('assets/kdn/home/img/down_select_img.svg',
                    width: getSize20(),
                    height: getSize20(),
                    colorFilter: ColorFilter.mode(
                        getColorGrayType3(), BlendMode.srcIn)),
                onPressed: () {
                  Navigator.of(context).pop();
                  Scaffold.of(context).showBottomSheet(
                        (context) => MainViewNavigationSheet(
                      onClose: () {},
                      resetDate: false,
                      resetSearch: false,
                      initialSearch: false,
                    ),
                    backgroundColor: Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(DesignConstants.radiusXL)),
                    ),
                  );
                },
                padding: EdgeInsets.all(getSize8()),
                constraints: const BoxConstraints(),
              ),
            ),
            SizedBox(width: getSize8()),
            Container(
              decoration: BoxDecoration(
                color: getColorGrayType14(),
                borderRadius: BorderRadius.circular(getSize8()),
              ),
              child: IconButton(
                icon: SvgPicture.asset('assets/kdn/home/img/cancel_select_img.svg',
                    width: getSize20(),
                    height: getSize20(),
                    colorFilter: ColorFilter.mode(
                        getColorGrayType3(), BlendMode.srcIn)),
                onPressed: () {
                  viewModel.clearRoutes();
                  viewModel.setNavigationHistoryMode(false);

                  final mainScreenState =
                  context.findAncestorStateOfType<State<MainScreen>>();
                  if (mainScreenState != null) {
                    try {
                      (mainScreenState as dynamic).selectedIndex = -1;
                    } catch (e) {}
                  }

                  Navigator.of(context).pop();
                },
                padding: EdgeInsets.all(getSize8()),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}