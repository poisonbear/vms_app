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

  @override
  Widget build(BuildContext context) {
    NavigationDebugHelper.debugPrint('NavigationSheet build', location: 'nav_tab.build');
    NavigationDebugHelper.checkProviderAccess(context, 'nav_tab.build');

    final routeSearchViewModel = Provider.of<RouteSearchProvider>(context, listen: false);

    return PopScope(
        canPop: _isClosing,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop || _isClosing) return;

          final mainScreenState = context.findAncestorStateOfType<State<MainScreen>>();
          if (mainScreenState != null) {
            try {
              (mainScreenState as dynamic).selectedIndex = 0;
            } catch (e) {}
          }

          routeSearchViewModel.clearRoutes();
          routeSearchViewModel.setNavigationHistoryMode(false);
          Navigator.of(context).pop();
        },
        child: ChangeNotifierProvider.value(
          value: navigationViewModel,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: getSize350(),
                    maxHeight: MediaQuery.of(context).size.height * 0.61,
                  ),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(DesignConstants.radiusXL),
                      topRight: Radius.circular(DesignConstants.radiusXL),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),

                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: DesignConstants.spacing16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: getSize10()),

                              // 날짜 빠른 선택 버튼들
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

                              // 선택된 날짜 표시 (클릭 가능)
                              InkWell(
                                onTap: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.55,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: MainViewNavigationDate(
                                          title: '날짜 선택',
                                          onClose: (startDate, endDate) {
                                            setState(() {
                                              selectedStartDate = startDate;
                                              selectedEndDate = endDate;
                                            });
                                            _performSearch();
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(getSize4()),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: getSize12(),
                                      vertical: getSize8()
                                  ),
                                  decoration: BoxDecoration(
                                    color: getColorWhiteType1(),
                                    borderRadius: BorderRadius.circular(getSize4()),
                                    border: Border.all(color: getColorGrayType7(), width: getSize1()),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_today, size: getSize16(), color: getColorGrayType3()),
                                      SizedBox(width: getSize8()),
                                      TextWidgetString(
                                          '$selectedStartDate ~ $selectedEndDate',
                                          getTextcenter(),
                                          getSizeInt14(),
                                          getText500(),
                                          getColorBlackType2()
                                      ),
                                      SizedBox(width: getSize8()),
                                      Icon(Icons.arrow_drop_down, size: getSize20(), color: getColorGrayType3()),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: getSize10()),

                              // 검색 입력 필드들
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: getSize40(),
                                      child: TextFormField(
                                        controller: mmsiController,
                                        style: TextStyle(
                                          fontSize: getSize12(),
                                          color: getColorBlackType2(),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'MMSI 입력',
                                          hintStyle: TextStyle(
                                              color: getColorGrayType8(),
                                              fontSize: getSize12(),
                                              fontWeight: FontWeight.w400),
                                          suffixIcon: mmsiController.text.isNotEmpty
                                              ? IconButton(
                                            icon: Icon(Icons.clear, size: getSize18(), color: getColorGrayType3()),
                                            onPressed: () {
                                              setState(() {
                                                mmsiController.clear();
                                              });
                                            },
                                          )
                                              : null,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(getSize4()),
                                            borderSide: BorderSide(color: getColorGrayType7(), width: getSize1()),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(getSize4()),
                                            borderSide: BorderSide(color: getColorGrayType7(), width: getSize1()),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(getSize4()),
                                            borderSide: BorderSide(color: getColorSkyType2(), width: getSize1()),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: getSize12(),
                                              vertical: getSize12()),
                                          isDense: true,
                                          fillColor: getColorWhiteType1(),
                                          filled: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: getSize12()),

                                  Expanded(
                                    child: SizedBox(
                                      height: getSize40(),
                                      child: TextFormField(
                                        controller: shipNameController,
                                        style: TextStyle(
                                          fontSize: getSize12(),
                                          color: getColorBlackType2(),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '선박명 입력',
                                          hintStyle: TextStyle(
                                              color: getColorGrayType8(),
                                              fontSize: getSize12(),
                                              fontWeight: FontWeight.w400),
                                          suffixIcon: shipNameController.text.isNotEmpty
                                              ? IconButton(
                                            icon: Icon(Icons.clear, size: getSize18(), color: getColorGrayType3()),
                                            onPressed: () {
                                              setState(() {
                                                shipNameController.clear();
                                              });
                                            },
                                          )
                                              : null,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(getSize4()),
                                            borderSide: BorderSide(color: getColorGrayType7(), width: getSize1()),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(getSize4()),
                                            borderSide: BorderSide(color: getColorGrayType7(), width: getSize1()),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(getSize4()),
                                            borderSide: BorderSide(color: getColorSkyType2(), width: getSize1()),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: getSize12(),
                                              vertical: getSize12()),
                                          isDense: true,
                                          fillColor: getColorWhiteType1(),
                                          filled: true,
                                        ),
                                        onChanged: (value) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: getSize12()),

                                  SizedBox(
                                    height: getSize40(),
                                    child: Consumer<NavigationProvider>(
                                      builder: (context, provider, child) {
                                        return ElevatedButton(
                                          onPressed: provider.isLoading ? null : _performSearch,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: getColorSkyType2(),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(getSize4()),
                                            ),
                                            fixedSize: Size(getSize65(), getSize40()),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: provider.isLoading
                                              ? SizedBox(
                                            width: getSize16(),
                                            height: getSize16(),
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(getColorWhiteType1()),
                                              strokeWidth: getSize2(),
                                            ),
                                          )
                                              : Text(
                                            '조회',
                                            style: TextStyle(
                                              fontSize: getSize14(),
                                              fontWeight: FontWeight.w600,
                                              color: getColorWhiteType1(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: getSize20()),

                              // 리스트 영역
                              Expanded(
                                child: Consumer<NavigationProvider>(
                                  builder: (context, provider, child) {
                                    List<dynamic> rosList = provider.rosList;

                                    if (provider.isLoading && rosList.isEmpty) {
                                      return _buildLoadingSkeleton();
                                    }

                                    if (rosList.isEmpty) {
                                      return RefreshIndicator(
                                        key: _refreshIndicatorKey,
                                        onRefresh: _onRefresh,
                                        child: SingleChildScrollView(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          child: Container(
                                            height: MediaQuery.of(context).size.height * 0.4,
                                            width: double.infinity,
                                            padding: EdgeInsets.all(getSize20()),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.info_outline, size: getSize48(), color: getColorGrayType8()),
                                                SizedBox(height: getSize16()),
                                                TextWidgetString(
                                                  '검색 결과가 없습니다.',
                                                  getTextcenter(),
                                                  getSizeInt16(),
                                                  getText600(),
                                                  getColorGrayType2(),
                                                ),
                                                SizedBox(height: getSize8()),
                                                TextWidgetString(
                                                  '아래로 당겨서 새로고침',
                                                  getTextcenter(),
                                                  getSizeInt12(),
                                                  getText400(),
                                                  getColorGrayType3(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return RefreshIndicator(
                                      key: _refreshIndicatorKey,
                                      onRefresh: _onRefresh,
                                      child: SingleChildScrollView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: getSize12(),
                                                vertical: getSize8(),
                                              ),
                                              child: Row(
                                                children: [
                                                  TextWidgetString(
                                                    '검색 결과: ${rosList.length}건',
                                                    getTextleft(),
                                                    getSizeInt12(),
                                                    getText500(),
                                                    getColorGrayType3(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            for (int i = 0; i < rosList.length; i++) ...[
                                              _buildNavigationItem(
                                                  context,
                                                  '${rosList[i].mmsi}',
                                                  '${rosList[i].shipName}',
                                                  '${rosList[i].odb_reg_date ?? rosList[i].reg_dt ?? ''}',
                                                  routeSearchViewModel),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildHeader() {
    return Container(
      height: 43,
      padding: EdgeInsets.symmetric(horizontal: getSize14()),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(getSize20()),
          topRight: Radius.circular(getSize20()),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.navigation,
            color: getColorWhiteType1(),
            size: 22,
          ),
          SizedBox(width: getSize6()),
          TextWidgetString(
            '항행 이력 내역 조회',
            getTextleft(),
            getSizeInt18(),
            getText700(),
            getColorWhiteType1(),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _handleClose(context),
            child: Container(
              padding: EdgeInsets.all(getSize8()),
              color: Colors.transparent,
              child: Icon(
                Icons.close,
                color: getColorWhiteType1(),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleClose(BuildContext context) {
    try {
      if (widget.onClose != null) {
        widget.onClose!();
      }

      final mainScreenState = context.findAncestorStateOfType<State<MainScreen>>();
      if (mainScreenState != null) {
        try {
          (mainScreenState as dynamic).selectedIndex = 0;
        } catch (e) {}
      }

      final routeSearchViewModel = Provider.of<RouteSearchProvider>(context, listen: false);
      routeSearchViewModel.clearRoutes();
      routeSearchViewModel.setNavigationHistoryMode(false);

      setState(() {
        _isClosing = true;
      });

      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    } catch (e) {}
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
            horizontal: getSize12(),
            vertical: getSize8()
        ),
        side: BorderSide(color: getColorGrayType7()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(getSize4()),
        ),
      ),
      child: TextWidgetString(
        label,
        getTextcenter(),
        getSizeInt12(),
        getText500(),
        getColorGrayType3(),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(5, (index) => _buildSkeletonItem()),
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: EdgeInsets.only(bottom: getSize12()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(getSize4()),
        border: Border.all(color: getColorGrayType7(), width: getSize1()),
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
                  Container(
                    height: getSize16(),
                    width: getSize100(),
                    decoration: BoxDecoration(
                      color: getColorGrayType7(),
                      borderRadius: BorderRadius.circular(getSize4()),
                    ),
                  ),
                  SizedBox(height: getSize8()),
                  Row(
                    children: [
                      Container(
                        height: getSize12(),
                        width: getSize60(),
                        decoration: BoxDecoration(
                          color: getColorGrayType7(),
                          borderRadius: BorderRadius.circular(getSize4()),
                        ),
                      ),
                      SizedBox(width: getSize12()),
                      Container(
                        height: getSize12(),
                        width: getSize80(),
                        decoration: BoxDecoration(
                          color: getColorGrayType7(),
                          borderRadius: BorderRadius.circular(getSize4()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: getSize20(),
              height: getSize20(),
              decoration: BoxDecoration(
                color: getColorGrayType7(),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    mmsiController.dispose();
    shipNameController.dispose();
    super.dispose();
  }

  Widget _buildNavigationItem(BuildContext context, String mmsi, String shipNm,
      String startTime, RouteSearchProvider viewModel) {
    String formattedTime;
    DateTime? dateTime;
    if (startTime.isNotEmpty && int.tryParse(startTime) != null) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(startTime));
      formattedTime =
      "${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}";
    } else {
      formattedTime = startTime;
    }

    return Builder(builder: (innerContext) {
      return InkWell(
          onTap: () async {
            final navigationContext = Navigator.of(context);

            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return const Dialog(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: DesignConstants.spacing16),
                          Text('항행 경로 데이터를 불러오는 중...'),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            NavigationDebugHelper.debugPrint('항행이력 조회 시작 - mmsi: $mmsi', location: 'nav_tab.onTap');

            try {
              viewModel.setNavigationHistoryMode(true);

              NavigationDebugHelper.debugPrint('API 호출 전', location: 'nav_tab.beforeAPI');

              await viewModel.getVesselRoute(
                  regDt: dateTime != null
                      ? "${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}"
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

              navigationContext.pop();

              Scaffold.of(context).showBottomSheet(
                    (context) => GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 0) {
                      viewModel.clearRoutes();
                      viewModel.setNavigationHistoryMode(false);

                      final MainScreenState =
                      context.findAncestorStateOfType<State<MainScreen>>();
                      if (MainScreenState != null) {
                        try {
                          (MainScreenState as dynamic).selectedIndex = 0;
                        } catch (e) {}
                      }

                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (bool didPop, dynamic result) {
                      if (didPop) return;

                      final MainScreenState =
                      context.findAncestorStateOfType<State<MainScreen>>();
                      if (MainScreenState != null) {
                        try {
                          (MainScreenState as dynamic).selectedIndex = 0;
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
          ));
    });
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
          final startFormatted = '${startTime.substring(8, 10)}:${startTime.substring(10, 12)}:${startTime.substring(12, 14)}';
          final endFormatted = '${endTime.substring(8, 10)}:${endTime.substring(10, 12)}:${endTime.substring(12, 14)}';
          timeRange = '$formattedTime $startFormatted ~ $endFormatted';
        } else {
          timeRange = '$formattedTime 00:00:00 ~ 23:59:59';
        }
      } else {
        timeRange = '$formattedTime 00:00:00 ~ 23:59:59';
      }
    } catch (e) {
      timeRange = '$formattedTime 00:00:00 ~ 23:59:59';
    }
  } else {
    timeRange = '$formattedTime 00:00:00 ~ 23:59:59';
  }

  return Container(
    height: 135,
    decoration: BoxDecoration(
      color: getColorWhiteType1(),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(DesignConstants.radiusXL),
        topRight: Radius.circular(DesignConstants.radiusXL),
      ),
      boxShadow: [
        BoxShadow(
          color: getColorBlackType1().withOpacity(0.15),
          blurRadius: getSize20(),
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          width: getSize40(),
          height: getSize4(),
          margin: EdgeInsets.only(top: getSize6()),
          decoration: BoxDecoration(
            color: getColorGrayType7(),
            borderRadius: BorderRadius.circular(getSize2()),
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getSize12(),
            vertical: getSize8(),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: getSize12(),
                        vertical: getSize10(),
                      ),
                      decoration: BoxDecoration(
                        color: getColorGrayType14(),
                        borderRadius: BorderRadius.circular(getSize8()),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.only(right: getSize12()),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: getColorGrayType7(),
                                  width: getSize1(),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                TextWidgetString(
                                  'MMSI : ',
                                  getTextleft(),
                                  getSizeInt14(),
                                  getText400(),
                                  getColorGrayType3(),
                                ),
                                TextWidgetString(
                                  mmsi,
                                  getTextleft(),
                                  getSizeInt14(),
                                  getText600(),
                                  getColorBlackType2(),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: getSize12()),
                          Expanded(
                            child: Row(
                              children: [
                                TextWidgetString(
                                  '선명 : ',
                                  getTextleft(),
                                  getSizeInt14(),
                                  getText400(),
                                  getColorGrayType3(),
                                ),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final textPainter = TextPainter(
                                        text: TextSpan(
                                          text: shipNm.isEmpty ? 'Unknown' : shipNm,
                                          style: TextStyle(
                                            fontSize: getSize14(),
                                            fontWeight: getText600(),
                                          ),
                                        ),
                                        maxLines: 1,
                                        textDirection: TextDirection.ltr,
                                      )..layout(maxWidth: constraints.maxWidth);

                                      final isOverflowing = textPainter.didExceedMaxLines ||
                                          textPainter.width > constraints.maxWidth;

                                      return GestureDetector(
                                        onTap: isOverflowing ? () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.directions_boat,
                                                      size: getSize20(),
                                                      color: getColorSkyType2(),
                                                    ),
                                                    SizedBox(width: getSize8()),
                                                    TextWidgetString(
                                                      '선박 정보',
                                                      getTextleft(),
                                                      getSizeInt16(),
                                                      getText600(),
                                                      getColorBlackType2(),
                                                    ),
                                                  ],
                                                ),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        TextWidgetString(
                                                          'MMSI : ',
                                                          getTextleft(),
                                                          getSizeInt14(),
                                                          getText400(),
                                                          getColorGrayType3(),
                                                        ),
                                                        TextWidgetString(
                                                          mmsi,
                                                          getTextleft(),
                                                          getSizeInt14(),
                                                          getText600(),
                                                          getColorBlackType2(),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: getSize8()),
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        TextWidgetString(
                                                          '선명 : ',
                                                          getTextleft(),
                                                          getSizeInt14(),
                                                          getText400(),
                                                          getColorGrayType3(),
                                                        ),
                                                        Expanded(
                                                          child: TextWidgetString(
                                                            shipNm,
                                                            getTextleft(),
                                                            getSizeInt14(),
                                                            getText600(),
                                                            getColorSkyType2(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: TextWidgetString(
                                                      '확인',
                                                      getTextcenter(),
                                                      getSizeInt14(),
                                                      getText600(),
                                                      getColorSkyType2(),
                                                    ),
                                                  ),
                                                ],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(getSize12()),
                                                ),
                                              );
                                            },
                                          );
                                        } : null,
                                        child: Container(
                                          color: Colors.transparent,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  shipNm.isEmpty ? 'Unknown' : shipNm,
                                                  style: TextStyle(
                                                    fontSize: getSize14(),
                                                    fontWeight: getText600(),
                                                    color: isOverflowing
                                                        ? getColorSkyType2()
                                                        : getColorBlackType2(),
                                                    decoration: isOverflowing
                                                        ? TextDecoration.underline
                                                        : TextDecoration.none,
                                                    decorationColor: getColorSkyType2(),
                                                    decorationStyle: TextDecorationStyle.dotted,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              if (isOverflowing) ...[
                                                SizedBox(width: getSize4()),
                                                Icon(
                                                  Icons.info_outlined,
                                                  size: getSize16(),
                                                  color: getColorSkyType2(),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: getSize8()),
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
                      SizedBox(width: getSize4()),
                      Container(
                        decoration: BoxDecoration(
                          color: getColorGrayType14(),
                          borderRadius: BorderRadius.circular(getSize8()),
                        ),
                        child: IconButton(
                          icon: SvgPicture.asset('assets/kdn/home/img/close.svg',
                              width: getSize20(),
                              height: getSize20(),
                              colorFilter: ColorFilter.mode(
                                  getColorGrayType3(), BlendMode.srcIn)),
                          onPressed: () {
                            final MainScreenState =
                            context.findAncestorStateOfType<State<MainScreen>>();
                            if (MainScreenState != null) {
                              try {
                                (MainScreenState as dynamic).selectedIndex = 0;
                              } catch (e) {}
                            }
                            viewModel.setNavigationHistoryMode(false);
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
              SizedBox(height: getSize6()),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getSize12(),
                  vertical: getSize10(),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      getColorSkyType2().withOpacity(0.1),
                      getColorSkyType2().withOpacity(0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(getSize8()),
                  border: Border.all(
                    color: getColorSkyType2().withOpacity(0.2),
                    width: getSize1(),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: getSize18(),
                      color: getColorSkyType2(),
                    ),
                    SizedBox(width: getSize8()),
                    TextWidgetString(
                      '항행시간 : ',
                      getTextleft(),
                      getSizeInt14(),
                      getText400(),
                      getColorGrayType3(),
                    ),
                    Expanded(
                      child: TextWidgetString(
                        timeRange,
                        getTextleft(),
                        getSizeInt14(),
                        getText600(),
                        getColorSkyType2(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}