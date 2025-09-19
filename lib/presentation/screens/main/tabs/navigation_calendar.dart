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
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

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
    // 초기값 설정
    if (widget.title == '시작일자 선택') {
      final parts = selectedStartDate.split('-');
      if (parts.length == 3) {
        _selectedDay = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } else if (widget.title == '종료일자 선택') {
      final parts = selectedEndDate.split('-');
      if (parts.length == 3) {
        _selectedDay = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    }
    _focusedDay = _selectedDay;
  }

  void _selectDate(DateTime selectedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = selectedDay;
    });

    String formattedDate =
        "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";

    // 날짜 선택시 global 변수 업데이트
    if (widget.title == '시작일자 선택') {
      selectedStartDate = formattedDate;
      // 콜백 호출
      if (widget.onClose != null) {
        widget.onClose!(formattedDate, selectedEndDate);
      }
    } else if (widget.title == '종료일자 선택') {
      selectedEndDate = formattedDate;
      // 콜백 호출
      if (widget.onClose != null) {
        widget.onClose!(selectedStartDate, formattedDate);
      }
    }

    // 달력 닫기
    Navigator.pop(context, formattedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 550,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: DesignConstants.spacing20,
            horizontal: DesignConstants.spacing16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(DesignConstants.radiusXL),
              topRight: Radius.circular(DesignConstants.radiusXL)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              children: [
                TextWidgetString(
                  widget.title,
                  getTextleft(),
                  getSize20(),
                  getText700(),
                  getColorBlackType2(),
                ),
                const Spacer(),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: getSize20().toDouble()),

            // 달력
            Expanded(
              child: SingleChildScrollView(
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    _selectDate(selectedDay);
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
                    todayDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: getColorSkyType2().withOpacity(0.5),
                    ),
                    todayTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    weekendTextStyle: const TextStyle(color: Colors.red),
                    holidayTextStyle: const TextStyle(color: Colors.red),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    holidayBuilder: (context, date, _) {
                      final normalizedDate = DateTime(date.year, date.month, date.day);
                      final holidayName = getHolidayName(normalizedDate);
                      final isHoliday = holidays.contains(normalizedDate);
                      final isSelected = isSameDay(_selectedDay, date);

                      if (isHoliday) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? getColorGreenType1() : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.red,
                                  ),
                                ),
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
                        );
                      }
                      return null;
                    },
                  ),
                  holidayPredicate: (day) {
                    return holidays.contains(DateTime(day.year, day.month, day.day));
                  },
                ),
              ),
            ),

            // 확인 버튼
            SizedBox(height: getSize16().toDouble()),
            SizedBox(
              width: double.infinity,
              height: getSize45().toDouble(),
              child: ElevatedButton(
                onPressed: () {
                  _selectDate(_selectedDay);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: getColorSkyType2(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(getSize8().toDouble()),
                  ),
                ),
                child: TextWidgetString(
                  '선택',
                  getTextcenter(),
                  getSize16(),
                  getText700(),
                  getColorWhiteType1(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}