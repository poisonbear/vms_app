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
import '../controllers/main_screen_controller.dart';
import '../utils/navigation_debug.dart';

final TextEditingController globalMmsiController = TextEditingController();
final TextEditingController globalShipNameController = TextEditingController();
String selectedStartDate =
    "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
String selectedEndDate =
    "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

class MainViewNavigationSheet extends StatefulWidget {
  final Function? onClose;
  final bool resetDate; // 날짜 초기화 여부를 결정하는 플래그 추가
  final bool resetSearch; // MMSI, 선박명 초기화 여부를 결정하는 플래그

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
  late NavigationProvider navigationViewModel;
  PersistentBottomSheetController? _bottomSheetController;

  @override
  void initState() {
    super.initState();

    NavigationDebugHelper.debugPrint('NavigationSheet initState', location: 'nav_tab');

    // MMSI 및 선박명은 resetSearch 플래그가 true일 때만 초기화
    if (widget.resetSearch) {
      globalMmsiController.clear();
      globalShipNameController.clear();
    }

    // 날짜는 resetDate 플래그가 true일 때만 초기화
    if (widget.resetDate) {
      final today = DateTime.now();
      selectedStartDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      selectedEndDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    }

    // ViewModel 생성
    navigationViewModel = NavigationProvider();

    final mmsi = context.read<UserState>().mmsi; //로그인한 계정의 mmsi
    final role = context.read<UserState>().role; //로그인한 계정의 권한

    // 탭 열릴 때마다 한 번만 자동 조회
    navigationViewModel.getRosList(
        startDate: selectedStartDate,
        endDate: selectedEndDate,
        mmsi: role == 'ROLE_USER'
            ? mmsi
            : (globalMmsiController.text.isEmpty
                ? null
                : int.tryParse(globalMmsiController.text)),
        shipName: globalShipNameController.text.isEmpty
            ? null
            : globalShipNameController.text.toUpperCase() // 대문자로 변환
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationDebugHelper.checkProviderAccess(context, 'nav_tab.postFrame');
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 디버깅 추가
    NavigationDebugHelper.debugPrint('NavigationSheet build', location: 'nav_tab.build');
    NavigationDebugHelper.checkProviderAccess(context, 'nav_tab.build');

    final routeSearchViewModel = Provider.of<RouteSearchProvider>(context,
        listen: false); // RouteSearchProvider 가져오기
    return WillPopScope(
        // 추가: WillPopScope로 감싸서 뒤로가기 처리
        onWillPop: () async {
          // 👉 MainScreen의 selectedIndex를 0으로 초기화 추가
          final MainScreenState =
              context.findAncestorStateOfType<State<MainScreen>>();
          MainScreenState?.setState(() {
            (MainScreenState as dynamic).selectedIndex = 0;
          });

          routeSearchViewModel.clearRoutes(); // 중요: 뒤로가기 시 클리어 처리
          routeSearchViewModel
              .setNavigationHistoryMode(false); //항행이력에서 벗어났다는 플래그값
          return true; // 뒤로가기 허용
        },
        child: ChangeNotifierProvider.value(
          value: navigationViewModel, // 여기서 미리 생성한 ViewModel 인스턴스를 사용
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
                      // 닫기 버튼 영역
                      Row(
                        children: [
                          TextWidgetString('항행 이력 내역 조회', getTextleft(),
                              getSize20(), getText700(), getColorblack_type2()),
                          const Spacer(),
                          Container(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.close,
                                    color: Colors.black),
                                onPressed: () {
                                  if (widget.onClose != null) {
                                    widget.onClose!();
                                  }

                                  // 👉 MainScreen의 selectedIndex를 0으로 초기화 추가
                                  final MainScreenState =
                                      context.findAncestorStateOfType<
                                          State<MainScreen>>();
                                  MainScreenState?.setState(() {
                                    (MainScreenState as dynamic).selectedIndex =
                                        0;
                                  });

                                  routeSearchViewModel.clearRoutes();
                                  routeSearchViewModel
                                      .setNavigationHistoryMode(false);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: getSize20().toDouble()),
                      // 일자 선택 영역
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: getSize40().toDouble(),
                              child: ElevatedButton(
                                onPressed: () async {
                                  _bottomSheetController =
                                      Scaffold.of(context).showBottomSheet(
                                    (context) {
                                      return const MainViewNavigationDate(
                                          title: '시작일자 선택');
                                    },
                                    backgroundColor: getColorblack_type3(),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(0)),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  side: BorderSide(
                                      color: getColorgray_Type7(), width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        getSize4().toDouble()),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: getSize12().toDouble()),
                                  backgroundColor: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextWidgetString(
                                        selectedStartDate,
                                        getTextleft(),
                                        getSize14(),
                                        getText600(),
                                        getColorgray_Type8()),
                                    Icon(Icons.calendar_today,
                                        size: 20, color: getColorgray_Type8()),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: getSize12().toDouble()),
                          Expanded(
                            child: SizedBox(
                              height: getSize40().toDouble(),
                              child: ElevatedButton(
                                onPressed: () async {
                                  _bottomSheetController =
                                      Scaffold.of(context).showBottomSheet(
                                    (context) {
                                      return const MainViewNavigationDate(
                                          title: '종료일자 선택');
                                    },
                                    backgroundColor: getColorblack_type3(),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(0)),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  side: BorderSide(
                                      color: getColorgray_Type7(), width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        getSize4().toDouble()),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: getSize12().toDouble()),
                                  backgroundColor: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextWidgetString(
                                        selectedEndDate,
                                        getTextleft(),
                                        getSize14(),
                                        getText600(),
                                        getColorgray_Type8()),
                                    Icon(Icons.calendar_today,
                                        size: 20, color: getColorgray_Type8()),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: getSize12().toDouble()),
                      // MMSI 및 선박명 입력 영역
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: getSize40().toDouble(),
                              child: TextFormField(
                                controller: globalMmsiController,
                                onTap: () {
                                  // 텍스트 필드 클릭 시 데이터 로드를 방지하기 위한 빈 콜백
                                },
                                onChanged: (value) {
                                  //입력값이 변경될 때 전역 변수와 동기화
                                  globalMmsiController.text = value;
                                },
                                decoration: InputDecoration(
                                  hintText: 'MMSI 입력',
                                  hintStyle: TextStyle(
                                      color: getColorgray_Type8(),
                                      fontSize: getSize14().toDouble(),
                                      fontWeight: getText600()),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        getSize4().toDouble()),
                                    borderSide: BorderSide(
                                        color: getColorgray_Type7(), width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        getSize4().toDouble()),
                                    borderSide: BorderSide(
                                        color: getColorgray_Type7(), width: 1),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: getSize12().toDouble(),
                                      vertical: getSize12().toDouble()),
                                  isDense: true,
                                  fillColor: Colors.white,
                                  // 배경색을 하얀색으로 설정
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
                                controller: globalShipNameController,
                                onTap: () {
                                  // 텍스트 필드 클릭 시 데이터 로드를 방지하기 위한 빈 콜백
                                },
                                onChanged: (value) {
                                  //입력값이 변경될 때 전역 변수와 동기화
                                  globalShipNameController.text = value;
                                },
                                decoration: InputDecoration(
                                  hintText: '선박명 입력',
                                  hintStyle: TextStyle(
                                      color: getColorgray_Type8(),
                                      fontSize: getSize14().toDouble(),
                                      fontWeight: getText600()),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        getSize4().toDouble()),
                                    borderSide: BorderSide(
                                        color: getColorgray_Type7(), width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        getSize4().toDouble()),
                                    borderSide: BorderSide(
                                        color: getColorgray_Type7(), width: 1),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: getSize12().toDouble(),
                                      vertical: getSize12().toDouble()),
                                  isDense: true,
                                  fillColor: Colors.white,
                                  // 배경색을 하얀색으로 설정
                                  filled: true,
                                ),
                                keyboardType: TextInputType.text,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: getSize12().toDouble()),

                      // 검색 버튼
                      SizedBox(
                        width: double.infinity,
                        height: getSize45().toDouble(),
                        child: Consumer<NavigationProvider>(
                          builder: (context, provider, child) {
                            return ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null // 로딩 중에는 버튼 비활성화
                                  : () {
                                      // 검색 실행
                                      provider.getRosList(
                                          startDate: selectedStartDate, // 시작일자
                                          endDate: selectedEndDate, // 종료일자
                                          mmsi: globalMmsiController
                                                  .text.isEmpty
                                              ? null
                                              : int.tryParse(
                                                  globalMmsiController.text),
                                          shipName: globalShipNameController
                                                  .text.isEmpty
                                              ? null
                                              : globalShipNameController.text
                                                  .toUpperCase() // 대문자로 변환
                                          );
                                    },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      getSize4().toDouble()),
                                ),
                                elevation: 0,
                                backgroundColor: getColorsky_Type2(),
                                side: BorderSide(
                                    color: getColorgray_Type7(), width: 1),
                              ),
                              child: provider.isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                getColorgray_Type8()),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search,
                                            color: getColorsky_Type1(),
                                            size: 20),
                                        SizedBox(width: getSize8().toDouble()),
                                        TextWidgetString(
                                            '항행 이력 내역 조회하기',
                                            getTextcenter(),
                                            getSize14(),
                                            getText600(),
                                            getColorsky_Type1()),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: getSize16().toDouble()),

                      // 항행 이력 리스트
                      Expanded(
                        child: Consumer<NavigationProvider>(
                          builder: (context, provider, child) {
                            var rosList = provider.rosList;

                            if (provider.isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (provider.errorMessage.isNotEmpty) {
                              return Center(child: Text(provider.errorMessage));
                            }

                            // 데이터 로드 전 상태 또는 빈 데이터 상태
                            if (rosList.isEmpty) {
                              return Expanded(
                                // ✅ 키보드 대응을 위해 Expanded로 감쌈
                                child: SingleChildScrollView(
                                  // ✅ 스크롤 가능하게
                                  child: Center(
                                    child: Container(
                                      width: double.infinity,
                                      margin: EdgeInsets.only(
                                          top: getSize60().toDouble()),
                                      // ✅ SizedBox 대신 여백
                                      padding: EdgeInsets.all(
                                          getSize16().toDouble()),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: getColorgray_Type7(),
                                            width: 1.0),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        // ✅ 내용 크기만큼만 차지
                                        children: [
                                          SvgPicture.asset(
                                            'assets/kdn/ros/img/circle-exclamation.svg',
                                            width: 100,
                                            height: 100,
                                          ),
                                          SizedBox(
                                              height: getSize20().toDouble()),
                                          TextWidgetString(
                                            '해당 기간에 항행 이력이 없습니다.',
                                            getTextcenter(),
                                            getSize16(),
                                            getText600(),
                                            getColorgray_Type2(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                                        '${rosList[i].odb_reg_date}',
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
    navigationViewModel.dispose();
    super.dispose();
  }

// 항행 이력 아이템 위젯
  Widget _buildNavigationItem(BuildContext context, String mmsi, String shipNm,
      String startTime, RouteSearchProvider viewModel) {
    String formattedTime;
    DateTime? dateTime;
    if (startTime.isNotEmpty && int.tryParse(startTime) != null) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(startTime));
      formattedTime =
          "${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}";
    } else {
      // 변환할 수 없는 경우 원본 문자열 사용
      formattedTime = startTime;
    }
    //항행 이력 아이템 클릭시, 이력 조회 서비스 시작(GIS)
    return Builder(builder: (innerContext) {
      return InkWell(
          onTap: () async {
            // 현재 컨텍스트를 미리 저장
            final scaffoldContext = Scaffold.of(context);
            final navigationContext = Navigator.of(context);

            // 로딩 다이얼로그 표시 (현재 컨텍스트 사용)
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

            // 로딩 다이얼로그 표시 전에 추가
            NavigationDebugHelper.debugPrint('항행이력 조회 시작 - mmsi: $mmsi', location: 'nav_tab.onTap');

            try {
              viewModel.setNavigationHistoryMode(true); // 항행 이력 조회 모드 설정

              // 🔍 디버깅: API 호출 전
              NavigationDebugHelper.debugPrint('API 호출 전', location: 'nav_tab.beforeAPI');

              // 항행 이력 데이터 로드
              await viewModel.getVesselRoute(
                  regDt: dateTime != null
                      ? "${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}"
                      : null,
                  mmsi: int.tryParse(mmsi));

              // 🔍 디버깅: API 호출 후
              NavigationDebugHelper.debugPrint(
                  'API 호출 후 - past: ${viewModel.pastRoutes.length}, pred: ${viewModel.predRoutes.length}',
                  location: 'nav_tab.afterAPI'
              );

              // 첫 번째 과거 항적 포인트로 지도 이동
              if (viewModel.pastRoutes.isNotEmpty) {
                LatLng firstPoint = LatLng(
                    viewModel.pastRoutes.last.lttd ?? 35.3790988,
                    viewModel.pastRoutes.last.lntd ?? 126.167763);

                // 상위 위젯의 MapController에 접근해서 지도 중심 이동

                // Provider를 사용하여 MapController 접근 (수정됨)
                try {
                  final mainController = Provider.of<MainScreenController>(context, listen: false);
                  mainController.mapController.move(firstPoint, 12.0);
                                } catch (e) {
                  NavigationDebugHelper.debugPrint("지도 이동 실패: \$e", location: "nav_tab.mapError");
                }
              }

              navigationContext.pop(); // LoadingDialog 닫기

              Scaffold.of(context).showBottomSheet(
                (context) => GestureDetector(
                  onVerticalDragEnd: (details) {
                    // 아래로 드래그한 경우 (속도가 양수)
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 0) {
                      // 항적 지우기
                      viewModel.clearRoutes();
                      viewModel.setNavigationHistoryMode(false);

                      // MainScreen의 selectedIndex를 0으로 초기화
                      final MainScreenState =
                          context.findAncestorStateOfType<State<MainScreen>>();
                      if (MainScreenState != null) {
                        (MainScreenState as dynamic).selectedIndex = 0;
                      }

                      // 바텀시트 닫기
                      Navigator.pop(context);
                    }
                  },
                  child: WillPopScope(
                    onWillPop: () async {
                      // 뒤로가기 누를 때도 MainScreen의 selectedIndex를 0으로 초기화 추가
                      final MainScreenState =
                          context.findAncestorStateOfType<State<MainScreen>>();
                      if (MainScreenState != null) {
                        (MainScreenState as dynamic).selectedIndex = 0;
                      }

                      viewModel.clearRoutes();
                      viewModel.setNavigationHistoryMode(false);
                      return true; // 뒤로가기 허용
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
              // 🔍 디버깅: 에러
              NavigationDebugHelper.debugPrint('에러 발생: $e', location: 'nav_tab.error');

              // 에러 처리
              Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다.')),
              );
            }
          },
          //UI 꾸미기
          child: Container(
            margin: EdgeInsets.only(bottom: getSize12().toDouble()),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(getSize4().toDouble()),
              border: Border.all(color: getColorgray_Type4(), width: 1),
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
                        // 선박명 (큰 글씨)
                        TextWidgetString(shipNm, getTextleft(), getSize16(),
                            getText700(), getColorblack_type2()),
                        SizedBox(height: getSize4().toDouble()),
                        // MMSI와 날짜 정보
                        Row(
                          children: [
                            // MMSI 라벨과 값
                            TextWidgetString(
                                'MMSI ',
                                getTextleft(),
                                getSize12(),
                                getText400(),
                                getColorgray_Type3()),
                            TextWidgetString(mmsi, getTextleft(), getSize12(),
                                getText600(), getColorgray_Type3()),
                            SizedBox(width: getSize12().toDouble()),
                            // DATE 라벨과 값
                            TextWidgetString(
                                'DATE ',
                                getTextleft(),
                                getSize12(),
                                getText400(),
                                getColorgray_Type3()),
                            TextWidgetString(
                                formattedTime,
                                getTextleft(),
                                getSize12(),
                                getText600(),
                                getColorgray_Type3()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: getColorgray_Type8(), size: 20),
                ],
              ),
            ),
          ));
    });
  }

  Widget _buildCollapsedBottomSheet(BuildContext context, String shipName,
      String mmsi, String formattedTime, RouteSearchProvider viewModel) {
// viewModel에서 첫 번째와 마지막 항적의 시간을 가져옵니다
    String timeRange = '00:00:00~00:00:00'; // 기본값

    if (viewModel.pastRoutes.isNotEmpty) {
      // 첫 번째 항적의 시간
      var firstRoute = viewModel.pastRoutes.first;
      DateTime? firstTime;
      if (firstRoute.regDt != null) {
        firstTime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(firstRoute.regDt.toString()));
      }

      // 마지막 항적의 시간
      var lastRoute = viewModel.pastRoutes.last;
      DateTime? lastTime;
      if (lastRoute.regDt != null) {
        lastTime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(lastRoute.regDt.toString()));
      }

      // 시간 포맷팅
      if (firstTime != null && lastTime != null) {
        String startTime =
            "${firstTime.hour.toString().padLeft(2, '0')}:${firstTime.minute.toString().padLeft(2, '0')}:${firstTime.second.toString().padLeft(2, '0')}";
        String endTime =
            "${lastTime.hour.toString().padLeft(2, '0')}:${lastTime.minute.toString().padLeft(2, '0')}:${lastTime.second.toString().padLeft(2, '0')}";
        timeRange = '$startTime~$endTime';
      }
    }

    return Container(
      height: 80,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: DesignConstants.spacing12,
          horizontal: DesignConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignConstants.radiusXL),
          topRight: Radius.circular(DesignConstants.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 0,
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
              children: [
                Text(
                  '$shipName (MMSI: $mmsi)',
                  style: TextStyle(
                    fontSize: DesignConstants.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: getColorblack_type2(),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'DATE: $formattedTime ($timeRange)',
                  style: TextStyle(
                    fontSize: DesignConstants.fontSizeS,
                    color: getColorgray_Type8(),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.expand_more, color: getColorgray_Type8()),
            onPressed: () {
              // 바텀 시트 확장
              Navigator.pop(context);
              Scaffold.of(context).showBottomSheet(
                (context) => MainViewNavigationSheet(
                  onClose: () {},
                  resetDate: false, // 여기서는 날짜를 초기화하지 않음
                  resetSearch: false, // MMSI, 선박명 초기화하지 않음
                ),
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(DesignConstants.radiusXL)),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.close, color: getColorgray_Type8()),
            onPressed: () {
              // 👉 MainScreen의 selectedIndex를 0으로 초기화 추가
              final MainScreenState =
                  context.findAncestorStateOfType<State<MainScreen>>();
              if (MainScreenState != null) {
                (MainScreenState as dynamic).selectedIndex = 0;
              }

              viewModel.clearRoutes();
              viewModel.setNavigationHistoryMode(false);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
