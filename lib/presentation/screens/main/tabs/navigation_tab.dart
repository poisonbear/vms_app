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
  final bool initialSearch; // 초기 검색 실행 여부 추가

  const MainViewNavigationSheet({
    super.key,
    this.onClose,
    this.resetDate = true,
    this.resetSearch = true,
    this.initialSearch = true, // 기본값은 true로 설정
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

  // NavigationProvider를 정적으로 관리 (이전 검색 결과 유지)
  static NavigationProvider? _sharedNavigationProvider;
  static String? _savedMmsi;
  static String? _savedShipName;

  // Pull-to-refresh를 위한 RefreshController
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    mmsiController = TextEditingController();
    shipNameController = TextEditingController();

    NavigationDebugHelper.debugPrint('NavigationSheet initState', location: 'nav_tab');

    if (widget.resetSearch) {
      // 검색 조건 초기화
      mmsiController.clear();
      shipNameController.clear();
      _savedMmsi = null;
      _savedShipName = null;
    } else {
      // 이전 검색 조건 복원
      if (_savedMmsi != null) {
        mmsiController.text = _savedMmsi!;
      }
      if (_savedShipName != null) {
        shipNameController.text = _savedShipName!;
      }
    }

    // 검색 조건 변경 시 저장
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

    // NavigationProvider 재사용 또는 새로 생성
    if (widget.resetSearch || widget.resetDate) {
      // 초기화가 필요한 경우 새로 생성
      navigationViewModel = NavigationProvider();
      _sharedNavigationProvider = navigationViewModel;
    } else {
      // 이전 Provider 재사용 (검색 결과 유지)
      navigationViewModel = _sharedNavigationProvider ?? NavigationProvider();
      _sharedNavigationProvider ??= navigationViewModel;
    }

    // initialSearch가 true일 때만 자동 검색 실행
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

  // 날짜 빠른 선택 함수
  void _quickSelectDate(int days) {
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: days));

    setState(() {
      selectedStartDate = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      selectedEndDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    });

    // 자동으로 검색 실행
    _performSearch();
  }

  // 검색 실행 함수
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

  // Pull-to-refresh 함수
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

          final mainScreenStat = context.findAncestorStateOfType<State<MainScreen>>();
          if (mainScreenStat != null) {
            try {
              (mainScreenStat as dynamic).selectedIndex = -1;
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
                      // 헤더 영역 - 제목과 닫기 버튼
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
                              onPressed: () {
                                if (widget.onClose != null) {
                                  widget.onClose!();
                                }

                                final mainScreenStat = context.findAncestorStateOfType<State<MainScreen>>();
                                if (mainScreenStat != null) {
                                  try {
                                    (mainScreenStat as dynamic).selectedIndex = -1;
                                  } catch (e) {}
                                }

                                routeSearchViewModel.clearRoutes();
                                routeSearchViewModel.setNavigationHistoryMode(false);

                                setState(() {
                                  _isClosing = true;
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
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
                            // 새로고침 버튼 - 조회 버튼과 동일한 스타일
                            ElevatedButton(
                              onPressed: () {
                                // 모든 조건 초기화
                                setState(() {
                                  // 날짜 초기화
                                  final today = DateTime.now();
                                  selectedStartDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
                                  selectedEndDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

                                  // 검색 조건 초기화
                                  mmsiController.clear();
                                  shipNameController.clear();
                                  _savedMmsi = null;
                                  _savedShipName = null;

                                  // NavigationProvider 새로 생성 (검색 결과 초기화)
                                  navigationViewModel = NavigationProvider();
                                  _sharedNavigationProvider = navigationViewModel;
                                });

                                // 초기화 후 자동 검색 실행
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
                          // 모달 바텀시트로 날짜 선택 화면 열기
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55, // 화면 높이의 55%로 더 축소
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
                          // MMSI 입력 필드 (초기화 버튼 포함)
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

                          // 선박명 입력 필드 (초기화 버튼 포함)
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

                          // 조회 버튼
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

                      // 리스트 영역 (Pull-to-refresh 추가)
                      Expanded(
                        child: Consumer<NavigationProvider>(
                          builder: (context, provider, child) {
                            List<dynamic> rosList = provider.RosList;

                            // 로딩 스켈레톤 표시
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

                            // 데이터가 있을 때
                            return RefreshIndicator(
                              key: _refreshIndicatorKey,
                              onRefresh: _onRefresh,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  children: [
                                    // 검색 결과 개수 표시
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
                                    // 리스트 아이템들 - 현재 NavigationModel 구조에 맞춤
                                    for (int i = 0; i < rosList.length; i++) ...[
                                      _buildNavigationItem(
                                          context,
                                          '${rosList[i].mmsi ?? ''}',
                                          '${rosList[i].shipName ?? ''}',
                                          '${rosList[i].odb_reg_date ?? rosList[i].reg_dt ?? ''}', // snake_case 사용
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
            ),
          ),
        ));
  }

  // 날짜 빠른 선택 버튼 위젯
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

  // 로딩 스켈레톤 위젯
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(5, (index) => _buildSkeletonItem()),
      ),
    );
  }

  // 스켈레톤 아이템 위젯
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
                  // 선박명 스켈레톤
                  Container(
                    height: getSize16(),
                    width: getSize100(),
                    decoration: BoxDecoration(
                      color: getColorGrayType7(),
                      borderRadius: BorderRadius.circular(getSize4()),
                    ),
                  ),
                  SizedBox(height: getSize8()),
                  // MMSI/DATE 스켈레톤
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
            // 스켈레톤 애니메이션 효과를 위한 컨테이너
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

  // 항행 이력 아이템 위젯 메서드 - 클래스 내부에 정의
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
          ));
    });
  }
}

// 항행 이력 상세보기 바텀시트 (클래스 외부 함수)
Widget _buildCollapsedBottomSheet(
    BuildContext context,
    String shipNm,
    String mmsi,
    String formattedTime,
    RouteSearchProvider viewModel,
    ) {
  // 실제 항행시간 계산
  String timeRange = '';
  if (viewModel.pastRoutes.isNotEmpty) {
    // 실제 항행 데이터가 있을 경우
    try {
      // 첫 번째 항행 기록 (가장 오래된)
      final firstRoute = viewModel.pastRoutes.first;
      final lastRoute = viewModel.pastRoutes.last;

      // regDt가 있는 경우 파싱 (yyyyMMddHHmmss 형식) - 🔧 여기도 수정!
      if (firstRoute.regDt != null && lastRoute.regDt != null) {
        // int를 String으로 변환
        final startTime = firstRoute.regDt.toString();
        final endTime = lastRoute.regDt.toString();

        // 시간 포맷팅
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
    // 항행 데이터가 없을 경우 기본값
    timeRange = '$formattedTime 00:00:00 ~ 23:59:59';
  }

  return Container(
    height: 135,  // 140 → 135로 조정
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
        // 드래그 핸들
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
              // 첫 번째 줄: MMSI와 선명 정보, 버튼들
              Row(
                children: [
                  // MMSI와 선명 정보 (왼쪽) - 카드 스타일
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
                          // MMSI 섹션
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
                                  getSizeInt14(),  // 12 → 14로 증가
                                  getText400(),
                                  getColorGrayType3(),
                                ),
                                TextWidgetString(
                                  mmsi,
                                  getTextleft(),
                                  getSizeInt14(),  // 12 → 14로 증가
                                  getText600(),
                                  getColorBlackType2(),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: getSize12()),
                          // 선명 섹션 (줄임표 처리 + 탭으로 전체 표시)
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
                                      // 텍스트가 실제로 잘리는지 확인
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
                                          // 탭하면 다이얼로그로 전체 선명 표시
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
                                                        ? getColorSkyType2()  // 잘렸을 때 파란색
                                                        : getColorBlackType2(), // 일반 검은색
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
                                              // 텍스트가 잘렸을 때만 정보 아이콘 표시
                                              if (isOverflowing) ...[
                                                SizedBox(width: getSize4()),
                                                Icon(
                                                  Icons.info_outlined,  // 동그라미 테두리 안에 i 아이콘
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
                  // 버튼들 (오른쪽)
                  Row(
                    children: [
                      // 항행이력 다시 열기 버튼
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
                      // 닫기 버튼
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
                            final mainScreenStat =
                            context.findAncestorStateOfType<State<MainScreen>>();
                            if (mainScreenStat != null) {
                              try {
                                (mainScreenStat as dynamic).selectedIndex = -1;
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
              // 두 번째 줄: 항행 시간 정보 (아이콘 추가)
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