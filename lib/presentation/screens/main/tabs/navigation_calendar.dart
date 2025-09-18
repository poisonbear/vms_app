import 'package:vms_app/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vms_app/presentation/screens/main/tabs/navigation_tab.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';

class MainViewNavigationDate extends StatefulWidget {
  final String title;
  final Function(String, String)? onClose;

  const MainViewNavigationDate({super.key, required this.title, this.onClose});

  @override
  _MainViewNavigationDateState createState() => _MainViewNavigationDateState();
}

class _MainViewNavigationDateState extends State<MainViewNavigationDate> {
  String _selectedDay =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
  PersistentBottomSheetController? _bottomSheetController; // ⚡ 변수 선언 유지 (호환성)

  final Set<DateTime> holidays = {
    DateTime(2025, 1, 1),
    DateTime(2025, 1, 28),
    DateTime(2025, 1, 29),
    DateTime(2025, 1, 30),
    DateTime(2025, 3, 1),
    DateTime(2025, 5, 5),
    DateTime(2025, 6, 6),
    DateTime(2025, 8, 15),
    DateTime(2025, 10, 3),
    DateTime(2025, 10, 9),
    DateTime(2025, 12, 25),
  };

  String getHolidayName(DateTime date) {
    Map<DateTime, String> holidayNames = {
      DateTime(2025, 1, 1): '신정',
      DateTime(2025, 1, 28): '',
      DateTime(2025, 1, 29): '설날',
      DateTime(2025, 1, 30): '',
      DateTime(2025, 3, 1): '삼일절',
      DateTime(2025, 5, 5): '어린이날',
      DateTime(2025, 6, 6): '현충일',
      DateTime(2025, 8, 15): '광복절',
      DateTime(2025, 10, 3): '개천절',
      DateTime(2025, 10, 9): '한글날',
      DateTime(2025, 12, 25): '성탄절',
    };
    return holidayNames[date] ?? '';
  }

  @override
  void initState() {
    super.initState();
    if (widget.title == '시작일자 선택') {
      _selectedDay = selectedStartDate;
    } else if (widget.title == '종료일자 선택') {
      _selectedDay = selectedEndDate;
    }
  }

  // ⚡ Navigator 잠금 문제 해결을 위한 안전한 네비게이션
  void safelyNavigateBack() {
    if (mounted) {
      if (widget.title == '시작일자 선택') {
        selectedStartDate = _selectedDay;
      } else if (widget.title == '종료일자 선택') {
        selectedEndDate = _selectedDay;
      }

      // ⚡ Navigator 잠금 상태를 확인하고 안전하게 처리
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);

          // ⚡ 충분한 지연 시간 확보 (300ms)
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              try {
                _bottomSheetController = Scaffold.of(context).showBottomSheet(
                      (context) {
                    return MainViewNavigationSheet(
                      onClose: () {},
                      resetDate: false,
                      resetSearch: false,
                    );
                  },
                  backgroundColor: getColorBlackType3(),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
                  ),
                );
              } catch (e) {
                debugPrint('BottomSheet 열기 실패: $e');
              }
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        // 뒤로가기 버튼이 눌리면 BottomSheet를 다시 연다
        safelyNavigateBack();
        // void 함수이므로 return 값 없음
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 550,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: DesignConstants.spacing20,
              horizontal: DesignConstants.spacing12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(DesignConstants.radiusXL),
              topRight: Radius.circular(DesignConstants.radiusXL),
            ),
          ),
          child: Column(
            children: [
              // 제목 영역 - 원본 그대로
              Row(
                children: [
                  TextWidgetString(widget.title, getTextleft(), getSize20(),
                      getText700(), getColorBlackType2()),
                  const Spacer(),
                  Container(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.close, color: getColorBlackType2()),
                        onPressed: () {
                          safelyNavigateBack();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignConstants.spacing20),
              // 캘린더 - 원본 그대로
              Expanded(
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: DateTime.parse(_selectedDay),
                  selectedDayPredicate: (day) =>
                      isSameDay(DateTime.parse(_selectedDay), day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay =
                      "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                    });

                    // 날짜 선택시 저장 (시작일자 또는 종료일자)
                    if (widget.title == '시작일자 선택') {
                      selectedStartDate =
                      "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                    } else if (widget.title == '종료일자 선택') {
                      selectedEndDate =
                      "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                    }

                    // ⚡ 날짜 선택시 충분한 지연 처리 (100ms)
                    safelyNavigateBack();
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                        fontSize: DesignConstants.fontSizeXL,
                        fontWeight: FontWeight.bold),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: getColorGreenType1(),
                    ),
                    todayDecoration: const BoxDecoration(),
                    todayTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    todayBuilder: (context, date, _) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: DesignConstants.fontSizeM,
                            ),
                          ),
                          TextWidgetString('오늘', getTextleft(), getSize14(),
                              getText700(), getColorGreenType1()),
                        ],
                      );
                    },
                    holidayBuilder: (context, date, _) {
                      String holidayName = getHolidayName(date);
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: DesignConstants.fontSizeM,
                                ),
                              ),
                              if (holidayName.isNotEmpty)
                                Text(
                                  holidayName,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  holidayPredicate: (day) => holidays.contains(day),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}