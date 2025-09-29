import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/emergency_model.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/emergency_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';

// 메인 함수 - 다른 탭들과 동일한 구조
Widget MainViewEmergencySheet(BuildContext context, {Function? onClose}) {
  return _EmergencyBottomSheet(onClose: onClose);
}

// 바텀시트 위젯
class _EmergencyBottomSheet extends StatefulWidget {
  final Function? onClose;

  const _EmergencyBottomSheet({this.onClose});

  @override
  State<_EmergencyBottomSheet> createState() => _EmergencyBottomSheetState();
}

class _EmergencyBottomSheetState extends State<_EmergencyBottomSheet> {
  bool _isEmergencyPressed = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    // Provider를 통해 현재 위치 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyProvider>().updateCurrentLocation();
    });
  }

  // 긴급신고 다이얼로그 표시
  void _showEmergencyDialog() {
    final userState = context.read<UserState>();
    final vesselProvider = context.read<VesselProvider>();
    final emergencyProvider = context.read<EmergencyProvider>();

    // 선박명 찾기 - 프로젝트 표준 파라미터명 사용
    String? shipNm;
    if (userState.mmsi != null) {
      try {
        final userVessel = vesselProvider.vessels.firstWhere(
              (vessel) => vessel.mmsi == userState.mmsi,
        );
        shipNm = userVessel.ship_nm;
      } catch (e) {
        shipNm = null;
      }
    }

    // 긴급신고 시작 (카운트다운) - int mmsi 전달
    emergencyProvider.startEmergency(
      mmsi: userState.mmsi,
      ship_nm: shipNm,
      countdownSeconds: 5,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Consumer<EmergencyProvider>(
          builder: (context, provider, child) {
            // 카운트다운이 끝나면 자동으로 다이얼로그 닫기
            if (provider.status == EmergencyStatus.active ||
                provider.status == EmergencyStatus.completed) {
              Navigator.of(dialogContext).pop();
              return const SizedBox.shrink();
            }

            return AlertDialog(
              backgroundColor: getColorWhiteType1(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(getSize12()),
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: getColorEmergencyRed(),
                    size: 48,
                  ),
                  SizedBox(height: getSize8()),
                  TextWidgetString(
                    '긴급신고',
                    getTextcenter(),
                    getSizeInt20(),
                    getText700(),
                    getColorEmergencyRed(),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextWidgetString(
                    '해양경찰 122로\n긴급신고를 진행하시겠습니까?',
                    getTextcenter(),
                    getSizeInt16(),
                    getText500(),
                    getColorBlackType2(),
                  ),
                  SizedBox(height: getSize20()),
                  // 카운트다운 표시
                  if (provider.countdownSeconds > 0)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: getColorEmergencyRed(), width: 3),
                      ),
                      child: Center(
                        child: TextWidgetString(
                          '${provider.countdownSeconds}',
                          getTextcenter(),
                          getSizeInt32(),
                          getText700(),
                          getColorEmergencyRed(),
                        ),
                      ),
                    ),
                  if (provider.countdownSeconds > 0) ...[
                    SizedBox(height: getSize12()),
                    TextWidgetString(
                      '${provider.countdownSeconds}초 후 자동 연결됩니다',
                      getTextcenter(),
                      getSizeInt12(),
                      getText400(),
                      getColorGrayType3(),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    provider.cancelEmergency();
                    Navigator.of(dialogContext).pop();
                  },
                  child: TextWidgetString(
                    '취소',
                    getTextcenter(),
                    getSizeInt14(),
                    getText600(),
                    getColorGrayType2(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await provider.activateEmergency();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColorEmergencyRed(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(getSize6()),
                    ),
                  ),
                  child: TextWidgetString(
                    '지금 신고',
                    getTextcenter(),
                    getSizeInt14(),
                    getText600(),
                    getColorWhiteType1(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 전화 걸기 (Provider 사용)
  Future<void> _makePhoneCall(String phoneNumber) async {
    final emergencyProvider = context.read<EmergencyProvider>();
    await emergencyProvider.activateEmergency();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmergencyProvider>(
      builder: (context, emergencyProvider, child) {
        final userState = context.watch<UserState>();
        final vesselProvider = context.watch<VesselProvider>();

        // 현재 사용자의 선박 찾기 - 프로젝트 표준 파라미터명 사용
        String shipNm = 'Unknown';
        if (userState.mmsi != null) {
          try {
            final userVessel = vesselProvider.vessels.firstWhere(
                  (vessel) => vessel.mmsi == userState.mmsi,
            );
            shipNm = userVessel.ship_nm ?? 'Unknown';
          } catch (e) {
            shipNm = 'Unknown';
          }
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            // ✅ 상단 붉은색 그라데이션 배경 - 색상 상수화
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                getColorEmergencyRed50(),    // 상단 연한 붉은색
                getColorWhiteType1(),         // 하단 흰색
              ],
              stops: const [0.0, 0.4], // 상단 40%만 색상
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(getSize20()),
              topRight: Radius.circular(getSize20()),
            ),
          ),
          child: Column(
            children: [
              // 헤더 - 진한 붉은색 배경
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getSize16(),
                  vertical: getSize12(),
                ),
                decoration: BoxDecoration(
                  // ✅ 헤더는 진한 붉은색 - 색상 상수화
                  gradient: LinearGradient(
                    colors: [
                      getColorEmergencyRed700(),
                      getColorEmergencyRed600(),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(getSize20()),
                    topRight: Radius.circular(getSize20()),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: getColorEmergencyRedOpacity30(),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emergency,
                      color: getColorWhiteType1(),  // ✅ 아이콘 색상 상수화
                      size: 24,
                    ),
                    SizedBox(width: getSize8()),
                    TextWidgetString(
                      '긴급신고',
                      getTextleft(),
                      getSizeInt20(),
                      getText700(),
                      getColorWhiteType1(),  // ✅ 텍스트 색상 상수화
                    ),
                    const Spacer(),
                    // 위치 추적 토글
                    IconButton(
                      icon: Icon(
                        emergencyProvider.isLocationTracking
                            ? Icons.location_on
                            : Icons.location_off,
                        color: emergencyProvider.isLocationTracking
                            ? getColorEmergencyGreenAccent()  // ✅ 색상 상수화
                            : getColorEmergencyWhite70(),
                        size: 20,
                      ),
                      onPressed: () {
                        emergencyProvider.toggleLocationTracking();
                      },
                      tooltip: emergencyProvider.isLocationTracking
                          ? '위치 추적 중'
                          : '위치 추적 시작',
                    ),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.close, color: getColorWhiteType1()), // ✅ 색상 상수화
                        onPressed: () {
                          if (widget.onClose != null) {
                            widget.onClose!();
                          }

                          // ✅ 수정: selectedIndex = 0 → selectedIndex = -1
                          final mainScreenState =
                          context.findAncestorStateOfType<State<MainScreen>>();
                          if (mainScreenState != null) {
                            try {
                              (mainScreenState as dynamic).selectedIndex = -1;
                            } catch (e) {}
                          }

                          setState(() {
                            _isClosing = true;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 콘텐츠 영역
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(getSize16()),
                  child: Column(
                    children: [
                      // 오류 메시지 표시
                      if (emergencyProvider.errorMessage != null)
                        Container(
                          padding: EdgeInsets.all(getSize12()),
                          margin: EdgeInsets.only(bottom: getSize16()),
                          decoration: BoxDecoration(
                            color: getColorEmergencyRed50(),
                            borderRadius: BorderRadius.circular(getSize8()),
                            border: Border.all(color: getColorEmergencyRed200()),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: getColorEmergencyRed(), size: 20),
                              SizedBox(width: getSize8()),
                              Expanded(
                                child: TextWidgetString(
                                  emergencyProvider.errorMessage!,
                                  getTextleft(),
                                  getSizeInt14(),
                                  getText400(),
                                  getColorEmergencyRed700(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  emergencyProvider.clearError();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                      // 상단: 긴급신고 섹션
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              getColorEmergencyRed600(),
                              getColorEmergencyRed500(),  // ✅ 색상 상수화
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(getSize12()),
                          boxShadow: [
                            BoxShadow(
                              color: getColorEmergencyRedOpacity40(),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(getSize20()),
                          child: Column(
                            children: [
                              TextWidgetString(
                                '🚨 긴급 상황 시',
                                getTextcenter(),
                                getSizeInt16(),
                                getText600(),
                                getColorWhiteType1(),
                              ),
                              SizedBox(height: getSize12()),

                              // 122 긴급신고 버튼
                              GestureDetector(
                                onLongPressStart: (_) {
                                  setState(() {
                                    _isEmergencyPressed = true;
                                  });
                                  HapticFeedback.mediumImpact();
                                },
                                onLongPressEnd: (_) {
                                  setState(() {
                                    _isEmergencyPressed = false;
                                  });
                                  _showEmergencyDialog();
                                },
                                onLongPressCancel: () {
                                  setState(() {
                                    _isEmergencyPressed = false;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: getSize40(),
                                    vertical: getSize20(),
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isEmergencyPressed
                                        ? getColorWhiteType1()
                                        : getColorEmergencyRed700(),
                                    borderRadius:
                                    BorderRadius.circular(getSize16()),
                                    boxShadow: _isEmergencyPressed
                                        ? []
                                        : [
                                      BoxShadow(
                                        color: getColorEmergencyBlackOpacity30(),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        color: _isEmergencyPressed
                                            ? getColorEmergencyRed()
                                            : getColorWhiteType1(),
                                        size: 40,
                                      ),
                                      SizedBox(height: getSize8()),
                                      TextWidgetString(
                                        '122',
                                        getTextcenter(),
                                        getSizeInt32(),
                                        getText700(),
                                        _isEmergencyPressed
                                            ? getColorEmergencyRed()
                                            : getColorWhiteType1(),
                                      ),
                                      TextWidgetString(
                                        '해양경찰 긴급신고',
                                        getTextcenter(),
                                        getSizeInt12(),
                                        getText400(),
                                        _isEmergencyPressed
                                            ? getColorEmergencyRed()
                                            : getColorWhiteType1(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: getSize12()),
                              TextWidgetString(
                                '3초간 길게 눌러 긴급신고',
                                getTextcenter(),
                                getSizeInt12(),
                                getText400(),
                                getColorEmergencyWhite80(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: getSize16()),

                      // 현재 위치 정보 표시
                      Container(
                        padding: EdgeInsets.all(getSize16()),
                        decoration: BoxDecoration(
                          color: getColorWhiteType1(),
                          borderRadius: BorderRadius.circular(getSize8()),
                          border: Border.all(color: getColorGrayType12()),
                          boxShadow: [
                            BoxShadow(
                              color: getColorEmergencyBlackOpacity05(),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWidgetString(
                                  '현재 위치 정보',
                                  getTextleft(),
                                  getSizeInt16(),
                                  getText600(),
                                  getColorBlackType2(),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: () {
                                    emergencyProvider.updateCurrentLocation();
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: getSize8().toDouble()),
                            if (emergencyProvider.currentPosition != null) ...[
                              _buildInfoRow(
                                '위도',
                                '${emergencyProvider.currentPosition!.latitude.toStringAsFixed(6)}°',
                              ),
                              _buildInfoRow(
                                '경도',
                                '${emergencyProvider.currentPosition!.longitude.toStringAsFixed(6)}°',
                              ),
                              if (emergencyProvider.currentPosition!.speed > 0)
                                _buildInfoRow(
                                  '속도',
                                  '${emergencyProvider.currentPosition!.speed.toStringAsFixed(1)} m/s',
                                ),
                              if (emergencyProvider.currentPosition!.heading >= 0)
                                _buildInfoRow(
                                  '방향',
                                  '${emergencyProvider.currentPosition!.heading.toStringAsFixed(0)}°',
                                ),
                            ] else
                              TextWidgetString(
                                '위치 정보를 가져오는 중...',
                                getTextcenter(),
                                getSizeInt14(),
                                getText400(),
                                getColorGrayType3(),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: getSize16()),

                      // 선박 정보
                      Container(
                        padding: EdgeInsets.all(getSize16()),
                        decoration: BoxDecoration(
                          color: getColorWhiteType1(),
                          borderRadius: BorderRadius.circular(getSize8()),
                          border: Border.all(color: getColorGrayType12()),
                          boxShadow: [
                            BoxShadow(
                              color: getColorEmergencyBlackOpacity05(),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidgetString(
                              '선박 정보',
                              getTextleft(),
                              getSizeInt16(),
                              getText600(),
                              getColorBlackType2(),
                            ),
                            SizedBox(height: getSize8()),
                            _buildInfoRow('선박명', shipNm),
                            _buildInfoRow(
                                'MMSI', userState.mmsi?.toString() ?? 'Unknown'),
                          ],
                        ),
                      ),

                      SizedBox(height: getSize16()),

                      // 기타 긴급 연락처
                      Container(
                        padding: EdgeInsets.all(getSize16()),
                        decoration: BoxDecoration(
                          color: getColorEmergencyBlue50(),  // ✅ 색상 상수화
                          borderRadius: BorderRadius.circular(getSize8()),
                          border: Border.all(color: getColorEmergencyBlue200()),  // ✅ 색상 상수화
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidgetString(
                              '기타 긴급 연락처',
                              getTextleft(),
                              getSizeInt16(),
                              getText600(),
                              getColorBlackType2(),
                            ),
                            SizedBox(height: getSize12()),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.local_hospital),
                                    label: TextWidgetString(
                                      '119 구급',
                                      getTextcenter(),
                                      getSizeInt14(),
                                      getText500(),
                                      getColorSkyType2(),
                                    ),
                                    onPressed: () => _makePhoneCall('119'),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          vertical: getSize10()),
                                      side: BorderSide(color: getColorSkyType2()),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            getSize8()),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: getSize8()),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.local_police),
                                    label: TextWidgetString(
                                      '112 경찰',
                                      getTextcenter(),
                                      getSizeInt14(),
                                      getText500(),
                                      getColorSkyType2(),
                                    ),
                                    onPressed: () => _makePhoneCall('112'),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          vertical: getSize10()),
                                      side: BorderSide(color: getColorSkyType2()),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            getSize8()),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: getSize20()),

                      // 긴급신고 히스토리 (있을 경우)
                      if (emergencyProvider.emergencyHistory.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(getSize16()),
                          decoration: BoxDecoration(
                            color: getColorWhiteType1(),
                            borderRadius: BorderRadius.circular(getSize8()),
                            border: Border.all(color: getColorGrayType12()),
                            boxShadow: [
                              BoxShadow(
                                color: getColorEmergencyBlackOpacity05(),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextWidgetString(
                                    '최근 긴급신고 기록',
                                    getTextleft(),
                                    getSizeInt16(),
                                    getText600(),
                                    getColorBlackType2(),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      emergencyProvider.clearHistory();
                                    },
                                    child: TextWidgetString(
                                      '전체 삭제',
                                      getTextcenter(),
                                      getSizeInt12(),
                                      getText400(),
                                      getColorEmergencyRed(),  // ✅ 색상 상수화
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: getSize8().toDouble()),
                              ...emergencyProvider.emergencyHistory
                                  .take(3)
                                  .map((emergency) {
                                return Container(
                                  margin: EdgeInsets.only(
                                      bottom: getSize8()),
                                  padding: EdgeInsets.all(getSize8()),
                                  decoration: BoxDecoration(
                                    color: getColorGrayType14(),
                                    borderRadius: BorderRadius.circular(
                                        getSize6()),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        emergency.emergency_status ==
                                            EmergencyStatus.completed.name
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: emergency.emergency_status ==
                                            EmergencyStatus.completed.name
                                            ? getColorEmergencyGreen()  // ✅ 색상 상수화
                                            : getColorEmergencyOrange(),  // ✅ 색상 상수화
                                        size: getSize16(),
                                      ),
                                      SizedBox(width: getSize8()),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            TextWidgetString(
                                              _formatDateTime(
                                                  emergency.reg_dt),
                                              getTextleft(),
                                              getSizeInt12(),
                                              getText400(),
                                              getColorBlackType2(),
                                            ),
                                            if (emergency.lttd != null &&
                                                emergency.lntd != null)
                                              TextWidgetString(
                                                '위치: ${emergency.lttd!.toStringAsFixed(4)}°, ${emergency.lntd!.toStringAsFixed(4)}°',
                                                getTextleft(),
                                                getSizeInt10(),
                                                getText400(),
                                                getColorGrayType3(),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: getSize20()),

                      // 안내 문구
                      Container(
                        padding: EdgeInsets.all(getSize12()),
                        decoration: BoxDecoration(
                          color: getColorEmergencyRed50(),  // ✅ 색상 상수화
                          borderRadius: BorderRadius.circular(getSize8()),
                          border: Border.all(color: getColorEmergencyRed100()),  // ✅ 색상 상수화
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info,
                              size: getSize16(),
                              color: getColorEmergencyRed400(),  // ✅ 색상 상수화
                            ),
                            SizedBox(width: getSize8()),
                            Expanded(
                              child: TextWidgetString(
                                '긴급 상황 시 122 버튼을 3초간 길게 누르면 해양경찰과 연결됩니다.\n'
                                    '거짓 신고 시 법적 처벌을 받을 수 있습니다.',
                                getTextleft(),
                                getSizeInt12(),
                                getText400(),
                                getColorEmergencyRed700(),  // ✅ 색상 상수화
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 정보 행 위젯
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getSize4()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextWidgetString(
            label,
            getTextleft(),
            getSizeInt14(),
            getText400(),
            getColorGrayType3(),
          ),
          TextWidgetString(
            value,
            getTextright(),
            getSizeInt14(),
            getText500(),
            getColorBlackType2(),
          ),
        ],
      ),
    );
  }

  // 날짜/시간 포맷
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}