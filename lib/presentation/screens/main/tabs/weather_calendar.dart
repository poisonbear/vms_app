import 'package:collection/collection.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vms_app/presentation/screens/main/tabs/weather_tab.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';

class MainViewWindyDate extends StatefulWidget {
  final Function? onClose;

  const MainViewWindyDate({super.key, this.onClose});

  @override
  _MainViewWindyDateState createState() => _MainViewWindyDateState();
}

class _MainViewWindyDateState extends State<MainViewWindyDate> {
  DateTime _selectedDay = DateTime.now();
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
  void dispose() {
    _bottomSheetController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // 뒤로가기 버튼이 눌리면 BottomSheet를 다시 연다
        _bottomSheetController = Scaffold.of(context).showBottomSheet(
          (context) {
            return MainScreenWindy(context, onClose: widget.onClose);
          },
          backgroundColor: AppColors.blackType3,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
        );
        Navigator.of(context).pop();
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: AppSizes.s550,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: AppSizes.spacing20, horizontal: AppSizes.spacingM),
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
                children: [
                  const Spacer(),
                  SizedBox(
                    width: AppSizes.s24,
                    height: AppSizes.s24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: SvgPicture.asset('assets/kdn/usm/img/close.svg',
                          width: AppSizes.s24, height: AppSizes.s24),
                      onPressed: () {
                        _bottomSheetController =
                            Scaffold.of(context).showBottomSheet(
                          (context) {
                            return MainScreenWindy(context,
                                onClose: widget.onClose);
                          },
                          backgroundColor: AppColors.blackType3,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(0)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacing10),
              Row(
                children: [
                  TextWidgetString(
                    '날짜 선택',
                    TextAligns.left,
                    AppSizes.i24,
                    FontWeights.w700,
                    AppColors.blackType2,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacing10),
              Expanded(
                child: TableCalendar(
                  locale: 'ko_KR',
                  focusedDay: _selectedDay,
                  firstDay: DateTime(1900, 1, 1),
                  lastDay: DateTime(2999, 12, 31),
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                    });
                    Navigator.of(context).pop();
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                        fontSize: DesignConstants.fontSizeXL,
                        fontWeight: FontWeight.bold),
                  ),
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.greenType1,
                    ),
                    todayDecoration: BoxDecoration(),
                    todayTextStyle: TextStyle(
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
                          TextWidgetString('오늘', TextAligns.left, AppSizes.i14,
                              FontWeights.w700, AppColors.grayType3),
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
                      bool isSelected = isSameDay(_selectedDay, day);
                      DateTime? holiday = holidays.firstWhereOrNull((holiday) =>
                          holiday.year == day.year &&
                          holiday.month == day.month &&
                          holiday.day == day.day);

                      return Container(
                        decoration: isSelected
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.blue, width: AppSizes.s2),
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
