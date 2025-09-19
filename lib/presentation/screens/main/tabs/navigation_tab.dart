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
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';
import 'package:vms_app/core/utils/app_logger.dart';
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

  const MainViewNavigationSheet({
    super.key,
    this.onClose,
    this.resetDate = true,
    this.resetSearch = true,
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

  @override
  void initState() {
    super.initState();

    mmsiController = TextEditingController();
    shipNameController = TextEditingController();

    NavigationDebugHelper.debugPrint('NavigationSheet initState', location: 'nav_tab');

    if (widget.resetSearch) {
      mmsiController.clear();
      shipNameController.clear();
    }

    if (widget.resetDate) {
      final today = DateTime.now();
      selectedStartDate =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      selectedEndDate =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    }

    navigationViewModel = NavigationProvider();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationDebugHelper.checkProviderAccess(context, 'nav_tab.postFrame');
    });
  }

  void refreshDates() {
    if (mounted) {
      setState(() {});
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
                              getSize20(), getText700(), getColorBlackType2()),
                          const Spacer(),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.close, color: Colors.black),
                              onPressed: () {
                                if (widget.onClose != null) {
                                  widget.onClose!();
                                }

                                final mainScreenState = context.findAncestorStateOfType<State<MainScreen>>();
                                if (mainScreenState != null) {
                                  try {
                                    (mainScreenState as dynamic).selectedIndex = 0;
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
                      SizedBox(height: getSize20().toDouble()),
                      // 날짜 선택 영역
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: getSize40().toDouble(),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await showModalBottomSheet<String>(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (context) => MainViewNavigationDate(
                                      title: '시작일자 선택',
                                      onClose: (startDate, endDate) {
                                        setState(() {
                                          selectedStartDate = startDate;
                                        });
                                      },
                                    ),
                                  );
                                  refreshDates();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(getSize4().toDouble()),
                                    side: BorderSide(color: getColorGrayType7(), width: 1),
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    selectedStartDate,
                                    style: TextStyle(
                                      fontSize: getSize14().toDouble(),
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xff5D647A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: getSize16().toDouble()),
                          Expanded(
                            child: SizedBox(
                              height: getSize40().toDouble(),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await showModalBottomSheet<String>(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (context) => MainViewNavigationDate(
                                      title: '종료일자 선택',
                                      onClose: (startDate, endDate) {
                                        setState(() {
                                          selectedEndDate = endDate;
                                        });
                                      },
                                    ),
                                  );
                                  refreshDates();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(getSize4().toDouble()),
                                    side: BorderSide(color: getColorGrayType7(), width: 1),
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    selectedEndDate,
                                    style: TextStyle(
                                      fontSize: getSize14().toDouble(),
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xff5D647A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: getSize16().toDouble()),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: getSize40().toDouble(),
                              child: TextFormField(
                                controller: mmsiController,
                                onTap: () {},
                                onChanged: (value) {
                                  mmsiController.text = value;
                                },
                                decoration: InputDecoration(
                                  hintText: 'MMSI 입력',
                                  hintStyle: TextStyle(
                                      color: getColorGrayType8(),
                                      fontSize: getSize14().toDouble(),
                                      fontWeight: FontWeight.w400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(getSize4().toDouble()),
                                    borderSide: BorderSide(color: getColorGrayType7(), width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(getSize4().toDouble()),
                                    borderSide: BorderSide(color: getColorGrayType7(), width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(getSize4().toDouble()),
                                    borderSide: BorderSide(color: getColorGrayType7(), width: 1),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: getSize12().toDouble(),
                                      vertical: getSize12().toDouble()),
                                  isDense: true,
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                          SizedBox(width: getSize12().toDouble()),
                          Expanded(
                            child: SizedBox(
                              height: getSize40().toDouble(),
                              child: TextFormField(
                                controller: shipNameController,
                                onTap: () {},
                                onChanged: (value) {
                                  shipNameController.text = value;
                                },
                                decoration: InputDecoration(
                                  hintText: '선박명 입력',
                                  hintStyle: TextStyle(
                                      color: getColorGrayType8(),
                                      fontSize: getSize14().toDouble(),
                                      fontWeight: FontWeight.w400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(getSize4().toDouble()),
                                    borderSide: BorderSide(color: getColorGrayType7(), width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(getSize4().toDouble()),
                                    borderSide: BorderSide(color: getColorGrayType7(), width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(getSize4().toDouble()),
                                    borderSide: BorderSide(color: getColorGrayType7(), width: 1),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: getSize12().toDouble(),
                                      vertical: getSize12().toDouble()),
                                  isDense: true,
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: getSize12().toDouble()),
                          SizedBox(
                            height: getSize40().toDouble(),
                            child: ElevatedButton(
                              onPressed: () {
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
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(getSize4().toDouble()),
                                ),
                                fixedSize: Size(getSize65().toDouble(), getSize40().toDouble()),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                '조회',
                                style: TextStyle(
                                  fontSize: getSize14().toDouble(),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: getSize20().toDouble()),
                      Expanded(
                        child: Consumer<NavigationProvider>(
                          builder: (context, provider, child) {
                            List<dynamic> rosList = provider.rosList;

                            if (rosList.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(getSize20().toDouble()),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(getSize8().toDouble()),
                                  border: Border.all(color: getColorGrayType6(), width: 1),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline, size: 48, color: getColorGrayType8()),
                                    SizedBox(height: getSize16().toDouble()),
                                    TextWidgetString(
                                      '검색 결과가 없습니다.',
                                      getTextcenter(),
                                      getSize16(),
                                      getText600(),
                                      getColorGrayType2(),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return SingleChildScrollView(
                              child: Column(
                                children: [
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
            margin: EdgeInsets.only(bottom: getSize12().toDouble()),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(getSize4().toDouble()),
              border: Border.all(color: getColorGrayType4(), width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: getSize16().toDouble(),
                  horizontal: getSize12().toDouble()),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidgetString(shipNm, getTextleft(), getSize16(),
                            getText700(), getColorBlackType2()),
                        SizedBox(height: getSize4().toDouble()),
                        Row(
                          children: [
                            TextWidgetString(
                                'MMSI ',
                                getTextleft(),
                                getSize12(),
                                getText400(),
                                getColorGrayType3()),
                            TextWidgetString(mmsi, getTextleft(), getSize12(),
                                getText600(), getColorGrayType3()),
                            SizedBox(width: getSize12().toDouble()),
                            TextWidgetString(
                                'DATE ',
                                getTextleft(),
                                getSize12(),
                                getText400(),
                                getColorGrayType3()),
                            TextWidgetString(
                                formattedTime,
                                getTextleft(),
                                getSize12(),
                                getText600(),
                                getColorGrayType3()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: getColorGrayType8(), size: 20),
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
  String startTime = formattedTime;
  String endTime = formattedTime;
  String timeRange =
      '${startTime.split('.').last}:00:00 ~ ${endTime.split('.').last}:23:59:59';

  return Container(
    height: 120,
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(DesignConstants.radiusXL),
        topRight: Radius.circular(DesignConstants.radiusXL),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacing16,
        vertical: DesignConstants.spacing12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 영역: 선박 정보와 버튼들
          Row(
            children: [
              // 선박 정보 (왼쪽)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString(
                      '$mmsi / $shipNm',
                      getTextleft(),
                      getSize18(),
                      getText600(),
                      getColorBlackType2(),
                    ),
                    SizedBox(height: getSize4().toDouble()),
                    TextWidgetString(formattedTime, getTextleft(), getSize14(),
                        getText400(), getColorGrayType3()),
                  ],
                ),
              ),
              // 버튼들 (오른쪽)
              Row(
                children: [
                  // 항행이력 다시 열기 버튼 (아래 방향 화살표)
                  IconButton(
                    icon: SvgPicture.asset('assets/kdn/usm/img/down_select_img.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                            Colors.black, BlendMode.srcIn)),
                    onPressed: () {
                      // 현재 바텀시트 닫기
                      Navigator.of(context).pop();
                      // 항행이력 바텀시트 다시 열기
                      Scaffold.of(context).showBottomSheet(
                            (context) => MainViewNavigationSheet(
                          onClose: () {},
                          resetDate: false,   // 날짜 유지
                          resetSearch: false, // 검색 조건 유지
                        ),
                        backgroundColor: Colors.transparent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(DesignConstants.radiusXL)),
                        ),
                      );
                    },
                  ),
                  // 닫기 버튼
                  IconButton(
                    icon: SvgPicture.asset('assets/kdn/usm/img/close.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                            Colors.black, BlendMode.srcIn)),
                    onPressed: () {
                      // MainScreen의 selectedIndex를 0으로 초기화
                      final MainScreenState =
                      context.findAncestorStateOfType<State<MainScreen>>();
                      if (MainScreenState != null) {
                        try {
                          (MainScreenState as dynamic).selectedIndex = 0;
                        } catch (e) {}
                      }

                      // 항행 히스토리 모드 해제
                      viewModel.setNavigationHistoryMode(false);
                      // 바텀시트 닫기
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: getSize8().toDouble()),
          // 시간 범위 정보
          TextWidgetString(timeRange, getTextleft(), getSize14(),
              getText400(), getColorGrayType3()),
        ],
      ),
    ),
  );
}