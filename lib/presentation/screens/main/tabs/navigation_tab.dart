import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';
import 'package:vms_app/presentation/screens/main/tabs/navigation_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/providers/route_provider.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import '../controllers/main_screen_controller.dart';
import '../utils/navigation_debug.dart';
import 'package:flutter/services.dart';

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
  bool _isClosing = false;

  static NavigationProvider? _sharedNavigationProvider;
  static String? _savedMmsi;
  static String? _savedShipName;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    mmsiController = TextEditingController();
    shipNameController = TextEditingController();

    NavigationDebugHelper.debugPrint('NavigationSheet initState',
        location: 'nav_tab');

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
          // 일반 사용자(ROLE_USER)만 MMSI 필터링
          // 관리자(ROLE_ADMIN), 운영자(ROLE_OPERATOR)는 전체 조회
          mmsi: role == 'ROLE_USER'
              ? mmsi
              : (mmsiController.text.isEmpty
                  ? null
                  : int.tryParse(mmsiController.text)),
          shipName: shipNameController.text.isEmpty
              ? null
              : shipNameController.text.toUpperCase());
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
      selectedStartDate =
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      selectedEndDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    });

    _performSearch();
  }

  void _performSearch() {
    final mmsi = context.read<UserState>().mmsi;
    final role = context.read<UserState>().role;

    navigationViewModel.getRosList(
      startDate: selectedStartDate,
      endDate: selectedEndDate,
      // 일반 사용자(ROLE_USER)만 MMSI 필터링
      // 관리자(ROLE_ADMIN), 운영자(ROLE_OPERATOR)는 전체 조회
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
    NavigationDebugHelper.debugPrint('NavigationSheet build',
        location: 'nav_tab.build');
    NavigationDebugHelper.checkProviderAccess(context, 'nav_tab.build');

    final routeSearchViewModel =
        Provider.of<RouteProvider>(context, listen: false);

    return PopScope(
        canPop: _isClosing,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop || _isClosing) return;

          final mainScreenState =
              context.findAncestorStateOfType<State<MainScreen>>();
          if (mainScreenState != null) {
            try {
              (mainScreenState as dynamic).selectedIndex = -1;
            } catch (e) {
              AppLogger.e('Error: $e');
            }
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
                    minHeight: AppSizes.s350,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.spacingM),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: AppSizes.s10),

                              // 날짜 빠른 선택 버튼들
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildQuickDateButton(
                                        '오늘', () => _quickSelectDate(0)),
                                    const SizedBox(width: AppSizes.s8),
                                    _buildQuickDateButton(
                                        '어제', () => _quickSelectDate(1)),
                                    const SizedBox(width: AppSizes.s8),
                                    _buildQuickDateButton(
                                        '최근 7일', () => _quickSelectDate(7)),
                                    const SizedBox(width: AppSizes.s8),
                                    _buildQuickDateButton(
                                        '최근 30일', () => _quickSelectDate(30)),
                                    const SizedBox(width: AppSizes.s8),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          final today = DateTime.now();
                                          selectedStartDate =
                                              "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
                                          selectedEndDate =
                                              "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

                                          mmsiController.clear();
                                          shipNameController.clear();
                                          _savedMmsi = null;
                                          _savedShipName = null;

                                          navigationViewModel =
                                              NavigationProvider();
                                          _sharedNavigationProvider =
                                              navigationViewModel;
                                        });

                                        _performSearch();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.skyType2,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSizes.s12,
                                          vertical: AppSizes.s8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppSizes.s4),
                                        ),
                                      ),
                                      child: const Icon(Icons.refresh,
                                          size: AppSizes.s20,
                                          color: AppColors.whiteType1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSizes.s10),

                              // 선택된 날짜 표시 (클릭 가능)
                              InkWell(
                                onTap: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.55,
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
                                borderRadius:
                                    BorderRadius.circular(AppSizes.s4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.s12,
                                      vertical: AppSizes.s8),
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteType1,
                                    borderRadius:
                                        BorderRadius.circular(AppSizes.s4),
                                    border: Border.all(
                                        color: AppColors.grayType7,
                                        width: AppSizes.s1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: AppSizes.s16,
                                          color: AppColors.grayType3),
                                      const SizedBox(width: AppSizes.s8),
                                      TextWidgetString(
                                          '$selectedStartDate ~ $selectedEndDate',
                                          TextAligns.center,
                                          AppSizes.i14,
                                          FontWeights.w500,
                                          AppColors.blackType2),
                                      const SizedBox(width: AppSizes.s8),
                                      const Icon(Icons.arrow_drop_down,
                                          size: AppSizes.s20,
                                          color: AppColors.grayType3),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.s10),

                              // 검색 입력 필드들
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: AppSizes.s40,
                                      child: TextFormField(
                                        controller: mmsiController,
                                        style: const TextStyle(
                                          fontSize: AppSizes.s12,
                                          color: AppColors.blackType2,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'MMSI 입력',
                                          hintStyle: const TextStyle(
                                              color: AppColors.grayType8,
                                              fontSize: AppSizes.s12,
                                              fontWeight: FontWeight.w400),
                                          suffixIcon: mmsiController
                                                  .text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear,
                                                      size: AppSizes.s18,
                                                      color:
                                                          AppColors.grayType3),
                                                  onPressed: () {
                                                    setState(() {
                                                      mmsiController.clear();
                                                    });
                                                  },
                                                )
                                              : null,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppSizes.s4),
                                            borderSide: const BorderSide(
                                                color: AppColors.grayType7,
                                                width: AppSizes.s1),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppSizes.s4),
                                            borderSide: const BorderSide(
                                                color: AppColors.grayType7,
                                                width: AppSizes.s1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppSizes.s4),
                                            borderSide: const BorderSide(
                                                color: AppColors.skyType2,
                                                width: AppSizes.s1),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: AppSizes.s12,
                                                  vertical: AppSizes.s12),
                                          isDense: true,
                                          fillColor: AppColors.whiteType1,
                                          filled: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.s12),
                                  Expanded(
                                    child: SizedBox(
                                      height: AppSizes.s40,
                                      child: TextFormField(
                                        controller: shipNameController,
                                        style: const TextStyle(
                                          fontSize: AppSizes.s12,
                                          color: AppColors.blackType2,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '선박명 입력',
                                          hintStyle: const TextStyle(
                                              color: AppColors.grayType8,
                                              fontSize: AppSizes.s12,
                                              fontWeight: FontWeight.w400),
                                          suffixIcon: shipNameController
                                                  .text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear,
                                                      size: AppSizes.s18,
                                                      color:
                                                          AppColors.grayType3),
                                                  onPressed: () {
                                                    setState(() {
                                                      shipNameController
                                                          .clear();
                                                    });
                                                  },
                                                )
                                              : null,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppSizes.s4),
                                            borderSide: const BorderSide(
                                                color: AppColors.grayType7,
                                                width: AppSizes.s1),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppSizes.s4),
                                            borderSide: const BorderSide(
                                                color: AppColors.grayType7,
                                                width: AppSizes.s1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppSizes.s4),
                                            borderSide: const BorderSide(
                                                color: AppColors.skyType2,
                                                width: AppSizes.s1),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: AppSizes.s12,
                                                  vertical: AppSizes.s12),
                                          isDense: true,
                                          fillColor: AppColors.whiteType1,
                                          filled: true,
                                        ),
                                        onChanged: (value) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.s12),
                                  SizedBox(
                                    height: AppSizes.s40,
                                    child: Consumer<NavigationProvider>(
                                      builder: (context, provider, child) {
                                        return ElevatedButton(
                                          onPressed: provider.isLoading
                                              ? null
                                              : _performSearch,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.skyType2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppSizes.s4),
                                            ),
                                            fixedSize: const Size(
                                                AppSizes.s65, AppSizes.s40),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: provider.isLoading
                                              ? const SizedBox(
                                                  width: AppSizes.s16,
                                                  height: AppSizes.s16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            AppColors
                                                                .whiteType1),
                                                    strokeWidth: AppSizes.s2,
                                                  ),
                                                )
                                              : const Text(
                                                  '조회',
                                                  style: TextStyle(
                                                    fontSize: AppSizes.s14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.whiteType1,
                                                  ),
                                                ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.s20),

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
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          child: Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.4,
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(
                                                AppSizes.s20),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.info_outline,
                                                    size: AppSizes.s48,
                                                    color: AppColors.grayType8),
                                                const SizedBox(
                                                    height: AppSizes.s16),
                                                TextWidgetString(
                                                  '검색 결과가 없습니다.',
                                                  TextAligns.center,
                                                  AppSizes.i16,
                                                  FontWeights.w600,
                                                  AppColors.grayType2,
                                                ),
                                                const SizedBox(
                                                    height: AppSizes.s8),
                                                TextWidgetString(
                                                  '아래로 당겨서 새로고침',
                                                  TextAligns.center,
                                                  AppSizes.i12,
                                                  FontWeights.w400,
                                                  AppColors.grayType3,
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
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: AppSizes.s12,
                                                vertical: AppSizes.s8,
                                              ),
                                              child: Row(
                                                children: [
                                                  TextWidgetString(
                                                    '검색 결과: ${rosList.length}건',
                                                    TextAligns.left,
                                                    AppSizes.i12,
                                                    FontWeights.w500,
                                                    AppColors.grayType3,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            //최적화: ValueKey 추가
                                            for (int i = 0;
                                                i < rosList.length;
                                                i++)
                                              _buildNavigationItem(
                                                context,
                                                '${rosList[i].mmsi}',
                                                '${rosList[i].shipName}',
                                                '${rosList[i].odb_reg_date ?? rosList[i].reg_dt ?? ''}',
                                                routeSearchViewModel,
                                                key: ValueKey(
                                                    'nav_${rosList[i].mmsi}_${rosList[i].reg_dt}'),
                                              ),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A5F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.s20),
          topRight: Radius.circular(AppSizes.s20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.navigation,
            color: AppColors.whiteType1,
            size: 22,
          ),
          const SizedBox(width: AppSizes.s6),
          TextWidgetString(
            '항행 이력 내역 조회',
            TextAligns.left,
            AppSizes.i18,
            FontWeights.w700,
            AppColors.whiteType1,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _handleClose(context),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.s8),
              color: Colors.transparent,
              child: const Icon(
                Icons.close,
                color: AppColors.whiteType1,
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

      final mainScreenState =
          context.findAncestorStateOfType<State<MainScreen>>();
      if (mainScreenState != null) {
        try {
          (mainScreenState as dynamic).selectedIndex = -1;
        } catch (e) {
          AppLogger.e('Error: $e');
        }
      }

      final routeSearchViewModel =
          Provider.of<RouteProvider>(context, listen: false);
      routeSearchViewModel.clearRoutes();
      routeSearchViewModel.setNavigationHistoryMode(false);

      setState(() {
        _isClosing = true;
      });

      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.e('Error: $e');
    }
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s12, vertical: AppSizes.s8),
        side: const BorderSide(color: AppColors.grayType7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.s4),
        ),
      ),
      child: TextWidgetString(
        label,
        TextAligns.center,
        AppSizes.i12,
        FontWeights.w500,
        AppColors.grayType3,
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
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.s4),
        border: Border.all(color: AppColors.grayType7, width: AppSizes.s1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSizes.s16, horizontal: AppSizes.s12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: AppSizes.s16,
                    width: AppSizes.s100,
                    decoration: BoxDecoration(
                      color: AppColors.grayType7,
                      borderRadius: BorderRadius.circular(AppSizes.s4),
                    ),
                  ),
                  const SizedBox(height: AppSizes.s8),
                  Row(
                    children: [
                      Container(
                        height: AppSizes.s12,
                        width: AppSizes.s60,
                        decoration: BoxDecoration(
                          color: AppColors.grayType7,
                          borderRadius: BorderRadius.circular(AppSizes.s4),
                        ),
                      ),
                      const SizedBox(width: AppSizes.s12),
                      Container(
                        height: AppSizes.s12,
                        width: AppSizes.s80,
                        decoration: BoxDecoration(
                          color: AppColors.grayType7,
                          borderRadius: BorderRadius.circular(AppSizes.s4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: AppSizes.s20,
              height: AppSizes.s20,
              decoration: const BoxDecoration(
                color: AppColors.grayType7,
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

  //최적화: Key 파라미터 추가
  Widget _buildNavigationItem(
    BuildContext context,
    String mmsi,
    String shipNm,
    String startTime,
    RouteProvider viewModel, {
    Key? key, //Key 파라미터 추가
  }) {
    String formattedTime;
    DateTime? dateTime;
    if (startTime.isNotEmpty && int.tryParse(startTime) != null) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(startTime));
      formattedTime =
          "${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}";
    } else {
      formattedTime = startTime;
    }

    //Builder에 Key 적용
    return Builder(
      key: key,
      builder: (innerContext) {
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
                          SizedBox(height: AppSizes.spacingM),
                          Text('항행 경로 데이터를 불러오는 중...'),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            NavigationDebugHelper.debugPrint('항행이력 조회 시작 - mmsi: $mmsi',
                location: 'nav_tab.onTap');

            try {
              viewModel.setNavigationHistoryMode(true);
              NavigationDebugHelper.debugPrint('API 호출 전',
                  location: 'nav_tab.beforeAPI');

              await viewModel.getVesselRoute(
                regDt: dateTime != null
                    ? "${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}${dateTime.day.toString().padLeft(2, '0')}"
                    : startTime,
                mmsi: int.tryParse(mmsi),
              );

              NavigationDebugHelper.debugPrint(
                  'API 호출 후 - past: ${viewModel.pastRoutes.length}, pred: ${viewModel.predRoutes.length}',
                  location: 'nav_tab.afterAPI');

              if (!mounted) {
                AppLogger.w('Widget unmounted after API call');
                if (navigationContext.mounted) {
                  navigationContext.pop();
                }
                return;
              }
              if (!context.mounted) {
                AppLogger.w('Context not mounted after API call');
                if (navigationContext.mounted) {
                  navigationContext.pop();
                }
                return;
              }

              if (viewModel.pastRoutes.isNotEmpty) {
                LatLng firstPoint = LatLng(
                    viewModel.pastRoutes.last.lttd ?? 35.3790988,
                    viewModel.pastRoutes.last.lntd ?? 126.167763);
                try {
                  final mainController =
                      Provider.of<MainScreenController>(context, listen: false);
                  mainController.mapController.move(firstPoint, 12.0);
                } catch (e) {
                  NavigationDebugHelper.debugPrint("지도 이동 실패: $e",
                      location: "nav_tab.mapError");
                }
              }

              if (!mounted) {
                AppLogger.w('Widget unmounted before pop');
                return;
              }
              if (!context.mounted) {
                AppLogger.w('Context not mounted before pop');
                return;
              }

              navigationContext.pop();

              if (!mounted) {
                AppLogger.w('Widget unmounted before showBottomSheet');
                return;
              }
              if (!context.mounted) {
                AppLogger.w('Context not mounted before showBottomSheet');
                return;
              }

              // 항적조회 결과 바텀시트 표시
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
                          (MainScreenState as dynamic).selectedIndex = -1;
                        } catch (e) {
                          AppLogger.e('Error: $e');
                        }
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
                          (MainScreenState as dynamic).selectedIndex = -1;
                        } catch (e) {
                          AppLogger.e('Error: $e');
                        }
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
              NavigationDebugHelper.debugPrint('에러 발생: $e',
                  location: 'nav_tab.error');

              if (!mounted) {
                AppLogger.w('Widget unmounted in catch block');
                return;
              }
              if (!context.mounted) {
                AppLogger.w('Context not mounted in catch block');
                return;
              }

              Navigator.of(context).pop();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다.')),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16,
              vertical: AppSizes.s14,
            ),
            margin: const EdgeInsets.only(bottom: AppSizes.s8),
            decoration: BoxDecoration(
              color: AppColors.whiteType1,
              border: Border.all(color: AppColors.grayType16),
              borderRadius: BorderRadius.circular(AppSizes.s12),
            ),
            child: Row(
              children: [
                // 선박 아이콘
                Container(
                  padding: const EdgeInsets.all(AppSizes.s10),
                  decoration: BoxDecoration(
                    color: AppColors.blueNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.s8),
                  ),
                  child: const Icon(
                    Icons.directions_boat,
                    color: AppColors.blueNavy,
                    size: AppSizes.s20,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),

                // 선박 정보 (확장)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // MMSI + 복사 버튼
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'MMSI: $mmsi',
                              style: const TextStyle(
                                fontSize: AppSizes.s14,
                                fontWeight: FontWeights.w600,
                                color: AppColors.blackType2,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                _copyToClipboard(context, 'MMSI', mmsi),
                            borderRadius: BorderRadius.circular(AppSizes.s4),
                            child: const Padding(
                              padding: EdgeInsets.all(AppSizes.s4),
                              child: Icon(
                                Icons.content_copy,
                                size: AppSizes.s16,
                                color: AppColors.grayType6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s4),

                      // 선박명 + 복사 버튼
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shipNm,
                              style: const TextStyle(
                                fontSize: AppSizes.s13,
                                fontWeight: FontWeights.w500,
                                color: AppColors.grayType3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                _copyToClipboard(context, '선박명', shipNm),
                            borderRadius: BorderRadius.circular(AppSizes.s4),
                            child: const Padding(
                              padding: EdgeInsets.all(AppSizes.s4),
                              child: Icon(
                                Icons.content_copy,
                                size: AppSizes.s16,
                                color: AppColors.grayType6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s4),

                      // 날짜
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontSize: AppSizes.s12,
                          color: AppColors.grayType3,
                        ),
                      ),
                    ],
                  ),
                ),

                // 화살표 아이콘
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.grayType6,
                  size: AppSizes.s20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 나머지 함수들은 기존과 동일
Widget _buildCollapsedBottomSheet(
  BuildContext context,
  String shipNm,
  String mmsi,
  String formattedTime,
  RouteProvider viewModel,
) {
  // ... 기존 코드 그대로 유지 (변경 없음) ...
  String timeRange = '';
  if (viewModel.pastRoutes.isNotEmpty) {
    try {
      final firstRoute = viewModel.pastRoutes.first;
      final lastRoute = viewModel.pastRoutes.last;

      if (firstRoute.regDt != null && lastRoute.regDt != null) {
        final startTime = firstRoute.regDt.toString();
        final endTime = lastRoute.regDt.toString();

        if (startTime.length >= 14 && endTime.length >= 14) {
          final startFormatted =
              '${startTime.substring(8, 10)}:${startTime.substring(10, 12)}:${startTime.substring(12, 14)}';
          final endFormatted =
              '${endTime.substring(8, 10)}:${endTime.substring(10, 12)}:${endTime.substring(12, 14)}';
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
      color: AppColors.whiteType1,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(DesignConstants.radiusXL),
        topRight: Radius.circular(DesignConstants.radiusXL),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.blackType1.withValues(alpha: 0.15),
          blurRadius: AppSizes.s20,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          width: AppSizes.s40,
          height: AppSizes.s4,
          margin: const EdgeInsets.only(top: AppSizes.s6),
          decoration: BoxDecoration(
            color: AppColors.grayType7,
            borderRadius: BorderRadius.circular(AppSizes.s2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s12,
            vertical: AppSizes.s8,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s12,
                        vertical: AppSizes.s10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grayType14,
                        borderRadius: BorderRadius.circular(AppSizes.s8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(right: AppSizes.s12),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: AppColors.grayType7,
                                  width: AppSizes.s1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                TextWidgetString(
                                  'MMSI : ',
                                  TextAligns.left,
                                  AppSizes.i14,
                                  FontWeights.w400,
                                  AppColors.grayType3,
                                ),
                                TextWidgetString(
                                  mmsi,
                                  TextAligns.left,
                                  AppSizes.i14,
                                  FontWeights.w600,
                                  AppColors.blackType2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.s12),
                          Expanded(
                            child: Row(
                              children: [
                                TextWidgetString(
                                  '선명 : ',
                                  TextAligns.left,
                                  AppSizes.i14,
                                  FontWeights.w400,
                                  AppColors.grayType3,
                                ),
                                Expanded(
                                  child: Text(
                                    shipNm.isEmpty ? 'Unknown' : shipNm,
                                    style: const TextStyle(
                                      fontSize: AppSizes.s14,
                                      fontWeight: FontWeights.w600,
                                      color: AppColors.blackType2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.grayType14,
                          borderRadius: BorderRadius.circular(AppSizes.s8),
                        ),
                        child: IconButton(
                          icon: SvgPicture.asset(
                              'assets/kdn/home/img/down_select_img.svg',
                              width: AppSizes.s20,
                              height: AppSizes.s20,
                              colorFilter: const ColorFilter.mode(
                                  AppColors.grayType3, BlendMode.srcIn)),
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
                                    top: Radius.circular(
                                        DesignConstants.radiusXL)),
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(AppSizes.s8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: AppSizes.s4),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.grayType14,
                          borderRadius: BorderRadius.circular(AppSizes.s8),
                        ),
                        child: IconButton(
                          icon: SvgPicture.asset(
                              'assets/kdn/home/img/close.svg',
                              width: AppSizes.s20,
                              height: AppSizes.s20,
                              colorFilter: const ColorFilter.mode(
                                  AppColors.grayType3, BlendMode.srcIn)),
                          onPressed: () {
                            final MainScreenState = context
                                .findAncestorStateOfType<State<MainScreen>>();
                            if (MainScreenState != null) {
                              try {
                                (MainScreenState as dynamic).selectedIndex = -1;
                              } catch (e) {
                                AppLogger.e('Error: $e');
                              }
                            }
                            viewModel.setNavigationHistoryMode(false);
                            Navigator.of(context).pop();
                          },
                          padding: const EdgeInsets.all(AppSizes.s8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s12,
                  vertical: AppSizes.s10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.skyType2.withValues(alpha: 0.1),
                      AppColors.skyType2.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.s8),
                  border: Border.all(
                    color: AppColors.skyType2.withValues(alpha: 0.2),
                    width: AppSizes.s1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: AppSizes.s18,
                      color: AppColors.skyType2,
                    ),
                    const SizedBox(width: AppSizes.s8),
                    TextWidgetString(
                      '항행시간 : ',
                      TextAligns.left,
                      AppSizes.i14,
                      FontWeights.w400,
                      AppColors.grayType3,
                    ),
                    Expanded(
                      child: TextWidgetString(
                        timeRange,
                        TextAligns.left,
                        AppSizes.i14,
                        FontWeights.w600,
                        AppColors.skyType2,
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

void _copyToClipboard(BuildContext context, String label, String value) {
  Clipboard.setData(ClipboardData(text: value));
  HapticFeedback.lightImpact();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label이(가) 복사되었습니다'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
