import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';
import 'package:geolocator/geolocator.dart';

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
  int _countdownSeconds = 0;
  Position? _currentPosition;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('위치 정보 오류: $e');
    }
  }

  // 전화 걸기
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전화를 걸 수 없습니다: $phoneNumber')),
        );
      }
    }
  }

  // 긴급신고 다이얼로그
  void _showEmergencyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 카운트다운 시작
            if (_countdownSeconds == 0) {
              _countdownSeconds = 5;
              Future.delayed(Duration.zero, () => _startCountdown(setState));
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(getSize12().toDouble()),
              ),
              title: Column(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  SizedBox(height: getSize8().toDouble()),
                  TextWidgetString(
                    '긴급신고',
                    getTextcenter(),
                    getSize20(),
                    getText700(),
                    Colors.red,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextWidgetString(
                    '해양경찰 122로\n긴급신고를 진행하시겠습니까?',
                    getTextcenter(),
                    getSize16(),
                    getText500(),
                    getColorBlackType2(),
                  ),
                  SizedBox(height: getSize20().toDouble()),
                  // 카운트다운 표시
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 3),
                    ),
                    child: Center(
                      child: TextWidgetString(
                        '$_countdownSeconds',
                        getTextcenter(),
                        getSize32(),
                        getText700(),
                        Colors.red,
                      ),
                    ),
                  ),
                  SizedBox(height: getSize12().toDouble()),
                  TextWidgetString(
                    '$_countdownSeconds초 후 자동 연결됩니다',
                    getTextcenter(),
                    getSize12(),
                    getText400(),
                    getColorGrayType3(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _countdownSeconds = 0;
                    });
                    Navigator.of(context).pop();
                  },
                  child: TextWidgetString(
                    '취소',
                    getTextcenter(),
                    getSize14(),
                    getText600(),
                    getColorGrayType2(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _makeEmergencyCall();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(getSize6().toDouble()),
                    ),
                  ),
                  child: TextWidgetString(
                    '지금 신고',
                    getTextcenter(),
                    getSize14(),
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

  // 카운트다운
  void _startCountdown(StateSetter setState) {
    if (_countdownSeconds > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_countdownSeconds > 0) {
          setState(() {
            _countdownSeconds--;
          });
          if (_countdownSeconds == 0) {
            Navigator.of(context).pop();
            _makeEmergencyCall();
          } else {
            _startCountdown(setState);
          }
        }
      });
    }
  }

  // 긴급신고 전화 걸기
  void _makeEmergencyCall() {
    // 진동 피드백
    HapticFeedback.heavyImpact();

    // 전화 걸기
    _makePhoneCall('122');

    // 신고 정보 준비 (실제로는 SMS나 데이터 전송)
    final userState = context.read<UserState>();
    final vesselProvider = context.read<VesselProvider>();

    // 선박명 찾기
    String shipName = 'Unknown';
    if (userState.mmsi != null) {
      try {
        final userVessel = vesselProvider.vessels.firstWhere(
              (vessel) => vessel.mmsi == userState.mmsi,
        );
        shipName = userVessel.ship_nm ?? 'Unknown';
      } catch (e) {
        shipName = 'Unknown';
      }
    }

    final emergencyInfo = '''
긴급신고 정보:
선박명: $shipName
MMSI: ${userState.mmsi ?? 'Unknown'}
위치: ${_currentPosition != null ? '북위 ${_currentPosition!.latitude.toStringAsFixed(4)}° 동경 ${_currentPosition!.longitude.toStringAsFixed(4)}°' : '위치 정보 없음'}
시간: ${DateTime.now()}
    ''';
    print(emergencyInfo); // 실제로는 서버로 전송
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final vesselProvider = context.watch<VesselProvider>();

    // 현재 사용자의 선박 찾기
    String shipName = 'Unknown';
    if (userState.mmsi != null) {
      try {
        final userVessel = vesselProvider.vessels.firstWhere(
              (vessel) => vessel.mmsi == userState.mmsi,
        );
        shipName = userVessel.ship_nm ?? 'Unknown';
      } catch (e) {
        // 선박을 찾지 못한 경우
        shipName = 'Unknown';
      }
    }

    return PopScope(
      canPop: _isClosing,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop || _isClosing) return;

        // MainScreen의 selectedIndex를 0으로 초기화
        final mainScreenState = context.findAncestorStateOfType<State<MainScreen>>();
        if (mainScreenState != null) {
          try {
            (mainScreenState as dynamic).selectedIndex = 0;
          } catch (e) {}
        }

        Navigator.of(context).pop();
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(DesignConstants.radiusXL),
                  topRight: Radius.circular(DesignConstants.radiusXL),
                ),
              ),
              child: Column(
                children: [
                  // 헤더 영역 - 제목과 닫기 버튼
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: getSize16().toDouble(),
                      vertical: getSize16().toDouble(),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(DesignConstants.radiusXL),
                        topRight: Radius.circular(DesignConstants.radiusXL),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emergency,
                          color: Colors.red,
                          size: 24,
                        ),
                        SizedBox(width: getSize8().toDouble()),
                        TextWidgetString(
                          '긴급신고',
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
                              if (widget.onClose != null) {
                                widget.onClose!();
                              }

                              final mainScreenState = context.findAncestorStateOfType<State<MainScreen>>();
                              if (mainScreenState != null) {
                                try {
                                  (mainScreenState as dynamic).selectedIndex = 0;
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
                      padding: EdgeInsets.all(getSize16().toDouble()),
                      child: Column(
                        children: [
                          // 상단: 긴급신고 섹션
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade600,
                                  Colors.red.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(getSize12().toDouble()),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(getSize20().toDouble()),
                              child: Column(
                                children: [
                                  TextWidgetString(
                                    '🚨 긴급 상황 시',
                                    getTextcenter(),
                                    getSize16(),
                                    getText600(),
                                    getColorWhiteType1(),
                                  ),
                                  SizedBox(height: getSize12().toDouble()),

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
                                        horizontal: getSize40().toDouble(),
                                        vertical: getSize20().toDouble(),
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isEmergencyPressed
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(getSize12().toDouble()),
                                        border: Border.all(
                                          color: _isEmergencyPressed
                                              ? Colors.yellow
                                              : Colors.white,
                                          width: _isEmergencyPressed ? 3 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          TextWidgetString(
                                            '122',
                                            getTextcenter(),
                                            getSize40(),
                                            getText700(),
                                            Colors.red,
                                          ),
                                          TextWidgetString(
                                            '해양긴급신고',
                                            getTextcenter(),
                                            getSize16(),
                                            getText600(),
                                            Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: getSize8().toDouble()),
                                  TextWidgetString(
                                    '3초간 길게 누르세요',
                                    getTextcenter(),
                                    getSize12(),
                                    getText400(),
                                    getColorWhiteType1(),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: getSize20().toDouble()),

                          // 중단: 빠른 연락처
                          Container(
                            padding: EdgeInsets.all(getSize16().toDouble()),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(getSize12().toDouble()),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidgetString(
                                  '빠른 연락처',
                                  getTextleft(),
                                  getSize16(),
                                  getText600(),
                                  getColorBlackType2(),
                                ),
                                SizedBox(height: getSize12().toDouble()),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 3,
                                  crossAxisSpacing: getSize12().toDouble(),
                                  mainAxisSpacing: getSize12().toDouble(),
                                  childAspectRatio: 1.2,
                                  children: [
                                    _buildContactButton('해양경찰서', '122', Icons.shield),
                                    _buildContactButton('기상청', '131', Icons.cloud),
                                    _buildContactButton('VTS센터', '1588-9117', Icons.radar),
                                    _buildContactButton('의료지원', '119', Icons.medical_services),
                                    _buildContactButton('구조대', '119', Icons.support),
                                    _buildContactButton('항만청', '1599-5961', Icons.anchor),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: getSize20().toDouble()),

                          // 하단: 내 정보 & 현재 위치
                          Container(
                            padding: EdgeInsets.all(getSize16().toDouble()),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(getSize12().toDouble()),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: getColorSkyType2(),
                                    ),
                                    SizedBox(width: getSize8().toDouble()),
                                    TextWidgetString(
                                      '내 정보',
                                      getTextleft(),
                                      getSize16(),
                                      getText600(),
                                      getColorBlackType2(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: getSize12().toDouble()),

                                // 선박 정보
                                _buildInfoRow('선박명', shipName),
                                _buildInfoRow('MMSI', userState.mmsi?.toString() ?? 'Unknown'),
                                _buildInfoRow('역할', userState.role == 'ROLE_USER' ? '사용자' : '관리자'),

                                Divider(height: getSize20().toDouble()),

                                // 현재 위치
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: getSize8().toDouble()),
                                    TextWidgetString(
                                      '현재 위치',
                                      getTextleft(),
                                      getSize16(),
                                      getText600(),
                                      getColorBlackType2(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: getSize8().toDouble()),

                                if (_currentPosition != null) ...[
                                  _buildInfoRow('북위', '${_currentPosition!.latitude.toStringAsFixed(4)}°'),
                                  _buildInfoRow('동경', '${_currentPosition!.longitude.toStringAsFixed(4)}°'),
                                  _buildInfoRow('정확도', '${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
                                ] else ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: getSize12().toDouble()),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const CircularProgressIndicator(strokeWidth: 2),
                                        SizedBox(width: getSize12().toDouble()),
                                        TextWidgetString(
                                          '위치 정보 가져오는 중...',
                                          getTextcenter(),
                                          getSize14(),
                                          getText400(),
                                          getColorGrayType3(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                SizedBox(height: getSize12().toDouble()),

                                // 위치 새로고침 버튼
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _getCurrentLocation,
                                    icon: Icon(
                                      Icons.refresh,
                                      size: 18,
                                      color: getColorSkyType2(),
                                    ),
                                    label: TextWidgetString(
                                      '위치 새로고침',
                                      getTextcenter(),
                                      getSize14(),
                                      getText500(),
                                      getColorSkyType2(),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: getSize10().toDouble()),
                                      side: BorderSide(color: getColorSkyType2()),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(getSize8().toDouble()),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: getSize20().toDouble()),

                          // 안내 문구
                          Container(
                            padding: EdgeInsets.all(getSize12().toDouble()),
                            decoration: BoxDecoration(
                              color: getColorGrayType14(),
                              borderRadius: BorderRadius.circular(getSize8().toDouble()),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info,
                                  size: 16,
                                  color: getColorGrayType3(),
                                ),
                                SizedBox(width: getSize8().toDouble()),
                                Expanded(
                                  child: TextWidgetString(
                                    '긴급 상황 시 122 버튼을 3초간 길게 누르면 해양경찰과 연결됩니다.\n거짓 신고 시 법적 처벌을 받을 수 있습니다.',
                                    getTextleft(),
                                    getSize12(),
                                    getText400(),
                                    getColorGrayType3(),
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
            ),
          ),
        ),
      ),
    );
  }

  // 연락처 버튼 위젯
  Widget _buildContactButton(String name, String number, IconData icon) {
    return InkWell(
      onTap: () => _makePhoneCall(number),
      borderRadius: BorderRadius.circular(getSize8().toDouble()),
      child: Container(
        decoration: BoxDecoration(
          color: getColorGrayType14(),
          borderRadius: BorderRadius.circular(getSize8().toDouble()),
          border: Border.all(color: getColorGrayType7()),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: getColorSkyType2(),
            ),
            SizedBox(height: getSize4().toDouble()),
            TextWidgetString(
              name,
              getTextcenter(),
              getSize12(),
              getText500(),
              getColorBlackType2(),
            ),
            TextWidgetString(
              number,
              getTextcenter(),
              getSize10(),
              getText400(),
              getColorGrayType3(),
            ),
          ],
        ),
      ),
    );
  }

  // 정보 행 위젯
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getSize4().toDouble()),
      child: Row(
        children: [
          SizedBox(
            width: getSize80().toDouble(),
            child: TextWidgetString(
              label,
              getTextleft(),
              getSize14(),
              getText400(),
              getColorGrayType3(),
            ),
          ),
          TextWidgetString(
            ': ',
            getTextleft(),
            getSize14(),
            getText400(),
            getColorGrayType3(),
          ),
          Expanded(
            child: TextWidgetString(
              value,
              getTextleft(),
              getSize14(),
              getText600(),
              getColorBlackType2(),
            ),
          ),
        ],
      ),
    );
  }
}