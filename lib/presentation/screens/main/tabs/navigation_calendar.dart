import 'package:vms_app/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vms_app/presentation/screens/main/tabs/navigation_tab.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';

class MainViewNavigationDate extends StatefulWidget {
  final String title;
  final Function(String, String)? onClose;

  const MainViewNavigationDate({super.key, required this.title, this.onClose});

  @override
  _MainViewNavigationDateState createState() => _MainViewNavigationDateState();
}

class _MainViewNavigationDateState extends State<MainViewNavigationDate> {
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

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
    // 기존 선택된 날짜로 초기화
    try {
      _selectedStartDate = DateTime.parse(selectedStartDate);
      _selectedEndDate = DateTime.parse(selectedEndDate);
      _focusedDay = _selectedStartDate;
    } catch (e) {
      _selectedStartDate = DateTime.now();
      _selectedEndDate = DateTime.now();
      _focusedDay = DateTime.now();
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedStartDate = start ?? _selectedStartDate;
      _selectedEndDate = end ?? start ?? _selectedEndDate;
      _focusedDay = focusedDay;
    });
  }

  void _confirmSelection() {
    // 선택된 날짜를 문자열로 변환
    String startDate =
        "${_selectedStartDate.year}-${_selectedStartDate.month.toString().padLeft(2, '0')}-${_selectedStartDate.day.toString().padLeft(2, '0')}";
    String endDate =
        "${_selectedEndDate.year}-${_selectedEndDate.month.toString().padLeft(2, '0')}-${_selectedEndDate.day.toString().padLeft(2, '0')}";

    // 콜백 호출하여 날짜 전달
    if (widget.onClose != null) {
      widget.onClose!(startDate, endDate);
    }

    // 화면 닫기
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignConstants.radiusXL),
          topRight: Radius.circular(DesignConstants.radiusXL),
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // 스크롤 비활성화 (높이가 충분하도록)
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 영역 (패딩 축소)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.s16.toDouble(),
                vertical: AppSizes.s12.toDouble(),
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grayType7, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidgetString(
                    widget.title,
                    TextAligns.left,
                    AppSizes.i18,
                    FontWeights.w600,
                    AppColors.blackType2,
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),

            // 조회기간 표시 (패딩 축소 및 포맷 변경)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.s16.toDouble(),
                vertical: AppSizes.s10.toDouble(),
              ),
              color: AppColors.grayType14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWidgetString(
                    '조회기간 : ',
                    TextAligns.center,
                    AppSizes.i14,
                    FontWeights.w500,
                    AppColors.grayType3,
                  ),
                  TextWidgetString(
                    "${_selectedStartDate.year}.${_selectedStartDate.month.toString().padLeft(2, '0')}.${_selectedStartDate.day.toString().padLeft(2, '0')}",
                    TextAligns.center,
                    AppSizes.i14,
                    FontWeights.w600,
                    AppColors.skyType2,
                  ),
                  TextWidgetString(
                    ' ~ ',
                    TextAligns.center,
                    AppSizes.i14,
                    FontWeights.w500,
                    AppColors.grayType3,
                  ),
                  TextWidgetString(
                    "${_selectedEndDate.year}.${_selectedEndDate.month.toString().padLeft(2, '0')}.${_selectedEndDate.day.toString().padLeft(2, '0')}",
                    TextAligns.center,
                    AppSizes.i14,
                    FontWeights.w600,
                    AppColors.skyType2,
                  ),
                ],
              ),
            ),

            // 달력 (패딩 제거 및 높이 최적화)
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.s8.toDouble()),
              child: TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                rangeSelectionMode: _rangeSelectionMode,
                rangeStartDay: _selectedStartDate,
                rangeEndDay: _selectedEndDate,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedStartDate, day) ||
                      isSameDay(_selectedEndDate, day);
                },
                onRangeSelected: _onRangeSelected,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                rowHeight: 38.0, // 더 줄이기 (42 → 38)
                daysOfWeekHeight: 30.0, // 더 줄이기 (35 → 30)
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  cellMargin: const EdgeInsets.all(1), // 더 줄이기 (2 → 1)
                  cellPadding: EdgeInsets.zero, // 완전 제거
                  weekendTextStyle: TextStyle(
                      color: Colors.red,
                      fontSize: AppSizes.s12.toDouble() // 더 작게
                      ),
                  holidayTextStyle: TextStyle(
                      color: Colors.red, fontSize: AppSizes.s12.toDouble()),
                  defaultTextStyle:
                      TextStyle(fontSize: AppSizes.s12.toDouble()),
                  rangeHighlightColor:
                      AppColors.skyType2.withValues(alpha: 0.2),
                  rangeStartDecoration: const BoxDecoration(
                    color: AppColors.skyType2,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: AppColors.skyType2,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.skyType2,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.grayType3.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.s12.toDouble(), // 더 작게
                    fontWeight: FontWeights.w600,
                  ),
                  todayTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.s12.toDouble(), // 더 작게
                    fontWeight: FontWeights.w500,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  headerPadding: EdgeInsets.symmetric(
                      vertical: AppSizes.s8.toDouble()), // 헤더 패딩 줄이기
                  titleTextStyle: TextStyle(
                    fontSize: AppSizes.s16.toDouble(),
                    fontWeight: FontWeights.w600,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    size: AppSizes.s20.toDouble(),
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    size: AppSizes.s20.toDouble(),
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    final text =
                        ['월', '화', '수', '목', '금', '토', '일'][day.weekday - 1];
                    final isWeekend = day.weekday == DateTime.saturday ||
                        day.weekday == DateTime.sunday;
                    return Center(
                      child: Text(
                        text,
                        style: TextStyle(
                          color: isWeekend ? Colors.red : AppColors.grayType3,
                          fontSize: AppSizes.s12.toDouble(),
                          fontWeight: FontWeights.w500,
                        ),
                      ),
                    );
                  },
                  holidayBuilder: (context, day, focusedDay) {
                    final holidayName = getHolidayName(day);
                    final isInRange = day.isAfter(_selectedStartDate
                            .subtract(const Duration(days: 1))) &&
                        day.isBefore(
                            _selectedEndDate.add(const Duration(days: 1)));

                    return Container(
                      margin: const EdgeInsets.all(1), // 더 줄이기
                      decoration: BoxDecoration(
                        color: isInRange
                            ? AppColors.skyType2.withValues(alpha: 0.2)
                            : null,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: AppSizes.s12.toDouble(), // 더 작게
                                fontWeight: FontWeights.w500,
                              ),
                            ),
                            if (holidayName.isNotEmpty)
                              Text(
                                holidayName,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: AppSizes.s6.toDouble(), // 더 작게
                                  fontWeight: FontWeights.w400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 버튼 영역 (패딩 축소)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.s16.toDouble(),
                vertical: AppSizes.s12.toDouble(),
              ),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.grayType7, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // 빠른 선택 버튼들
                  OutlinedButton(
                    onPressed: () {
                      // 오늘 날짜로 설정
                      setState(() {
                        _selectedStartDate = DateTime.now();
                        _selectedEndDate = DateTime.now();
                        _focusedDay = DateTime.now();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.s12.toDouble(),
                        vertical: AppSizes.s10.toDouble(),
                      ),
                      side: const BorderSide(color: AppColors.grayType7),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.s6.toDouble()),
                      ),
                    ),
                    child: TextWidgetString(
                      '오늘',
                      TextAligns.center,
                      AppSizes.i13,
                      FontWeights.w500,
                      AppColors.grayType3,
                    ),
                  ),
                  SizedBox(width: AppSizes.s8.toDouble()),
                  OutlinedButton(
                    onPressed: () {
                      // 최근 7일
                      final today = DateTime.now();
                      setState(() {
                        _selectedStartDate =
                            today.subtract(const Duration(days: 6));
                        _selectedEndDate = today;
                        _focusedDay = today;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.s12.toDouble(),
                        vertical: AppSizes.s10.toDouble(),
                      ),
                      side: const BorderSide(color: AppColors.grayType7),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.s6.toDouble()),
                      ),
                    ),
                    child: TextWidgetString(
                      '7일',
                      TextAligns.center,
                      AppSizes.i13,
                      FontWeights.w500,
                      AppColors.grayType3,
                    ),
                  ),
                  SizedBox(width: AppSizes.s8.toDouble()),
                  OutlinedButton(
                    onPressed: () {
                      // 최근 30일
                      final today = DateTime.now();
                      setState(() {
                        _selectedStartDate =
                            today.subtract(const Duration(days: 29));
                        _selectedEndDate = today;
                        _focusedDay = today;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.s12.toDouble(),
                        vertical: AppSizes.s10.toDouble(),
                      ),
                      side: const BorderSide(color: AppColors.grayType7),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.s6.toDouble()),
                      ),
                    ),
                    child: TextWidgetString(
                      '30일',
                      TextAligns.center,
                      AppSizes.i13,
                      FontWeights.w500,
                      AppColors.grayType3,
                    ),
                  ),
                  const Spacer(),
                  // 선택 완료 버튼
                  ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.skyType2,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.s20.toDouble(),
                        vertical: AppSizes.s10.toDouble(),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.s6.toDouble()),
                      ),
                    ),
                    child: TextWidgetString(
                      '선택 완료',
                      TextAligns.center,
                      AppSizes.i14,
                      FontWeights.w600,
                      AppColors.whiteType1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
