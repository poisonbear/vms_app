import 'package:collection/collection.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
  PersistentBottomSheetController? _bottomSheetController;
  
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

  void safelyNavigateBack() {
    if (mounted) {
      if (widget.title == '시작일자 선택') {
        selectedStartDate = _selectedDay;
      } else if (widget.title == '종료일자 선택') {
        selectedEndDate = _selectedDay;
      }

      if (mounted) Navigator.pop(context);

      Future.delayed(AnimationConstants.durationInstant, () {
        if (mounted) {
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
        }
      });
    }
  }

  @override  
  void dispose() {
    _bottomSheetController?.close();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidgetString(
                    widget.title,
                    getTextleft(),
                    getSize20(),
                    getText700(),
                    getColorBlackType2(),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: SvgPicture.asset('assets/kdn/usm/img/close.svg',
                          width: 24, height: 24),
                      onPressed: () {
                        safelyNavigateBack();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignConstants.spacing20),
              Expanded(
                child: TableCalendar(
                  locale: 'ko_KR',
                  focusedDay: _parseDate(_selectedDay),
                  firstDay: DateTime(1900, 1, 1),
                  lastDay: DateTime(2999, 12, 31),
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) {
                    return isSameDay(_parseDate(_selectedDay), day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (mounted) {
                      setState(() {
                        _selectedDay =
                            "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                      });
                    }

                    if (widget.title == '시작일자 선택') {
                      selectedStartDate =
                          "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                    } else if (widget.title == '종료일자 선택') {
                      selectedEndDate =
                          "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                    }

                    Future.delayed(AnimationConstants.durationInstant, () {
                      safelyNavigateBack();
                    });
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
                              getText700(), getColorGrayType3()),
                        ],
                      );
                    },
                    dowBuilder: (context, day) {
                      switch (day.weekday) {
                        case 1:
                          return const Center(
                              child: Text('월',
                                  style: TextStyle(color: Colors.black)));
                        case 2:
                          return const Center(
                              child: Text('화',
                                  style: TextStyle(color: Colors.black)));
                        case 3:
                          return const Center(
                              child: Text('수',
                                  style: TextStyle(color: Colors.black)));
                        case 4:
                          return const Center(
                              child: Text('목',
                                  style: TextStyle(color: Colors.black)));
                        case 5:
                          return const Center(
                              child: Text('금',
                                  style: TextStyle(color: Colors.black)));
                        case 6:
                          return const Center(
                              child: Text('토',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold)));
                        case 7:
                          return const Center(
                              child: Text('일',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)));
                        default:
                          return const Center(child: Text(''));
                      }
                    },
                    defaultBuilder: (context, day, focusedDay) {
                      bool isSelected =
                          isSameDay(_parseDate(_selectedDay), day);
                      DateTime? holiday = holidays.firstWhereOrNull((holiday) =>
                          holiday.year == day.year &&
                          holiday.month == day.month &&
                          holiday.day == day.day);

                      return Container(
                        decoration: isSelected
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.blue, width: 2),
                              )
                            : null,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: holiday != null || day.weekday == 7
                                    ? Colors.red
                                    : Colors.black,
                                fontWeight: holiday != null || day.weekday == 7
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (holiday != null)
                              Text(
                                getHolidayName(holiday),
                                style: const TextStyle(
                                  fontSize: DesignConstants.fontSizeXXS,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatDate(DateTime date) {
  return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
}

DateTime _parseDate(String dateString) {
  List<String> parts = dateString.split('-');
  if (parts.length == 3) {
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
  return DateTime.now();
}
