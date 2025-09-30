import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/emergency_model.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/emergency_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

// 메인 함수 - 다른 탭들과 동일한 구조
Widget MainViewEmergencySheet(BuildContext context, {Function? onClose}) {
  return _EmergencyBottomSheet(onClose: onClose);
}

class _EmergencyBottomSheet extends StatefulWidget {
  final Function? onClose;

  const _EmergencyBottomSheet({this.onClose});

  @override
  State<_EmergencyBottomSheet> createState() => _EmergencyBottomSheetState();
}

class _EmergencyBottomSheetState extends State<_EmergencyBottomSheet>
    with SingleTickerProviderStateMixin {
  bool _isEmergencyPressed = false;
  bool _isClosing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    final provider = context.read<EmergencyProvider>();
    await provider.updateCurrentLocation();

    if (provider.errorMessage != null && provider.errorMessage!.isNotEmpty && mounted) {
      showTopSnackBar(context, provider.errorMessage!);
    }
  }

  void _handleClose(BuildContext context) {
    try {
      if (widget.onClose != null) {
        widget.onClose!();
      }

      final mainScreenState = context.findAncestorStateOfType<State<MainScreen>>();
      if (mainScreenState != null) {
        try {
          (mainScreenState as dynamic).selectedIndex = -1;
        } catch (e) {
          // 에러 무시
        }
      }

      if (mounted) {
        setState(() {
          _isClosing = true;
        });
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 전체 에러 처리
    }
  }

  void _showEmergencyDialog() {
    final userState = context.read<UserState>();
    final vesselProvider = context.read<VesselProvider>();
    final emergencyProvider = context.read<EmergencyProvider>();

    if (emergencyProvider.isEmergencyActive) {
      showTopSnackBar(context, '긴급신고가 이미 진행 중입니다');
      return;
    }

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

    HapticFeedback.heavyImpact();

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
            if (provider.status == EmergencyStatus.active ||
                provider.status == EmergencyStatus.completed) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              return const SizedBox.shrink();
            }

            return WillPopScope(
              onWillPop: () async {
                provider.cancelEmergency();
                return true;
              },
              child: AlertDialog(
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
                    if (provider.countdownSeconds > 0) ...[
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: getColorEmergencyRed(),
                            width: 3,
                          ),
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
                      SizedBox(height: getSize12()),
                      TextWidgetString(
                        '${provider.countdownSeconds}초 후 자동 연결됩니다',
                        getTextcenter(),
                        getSizeInt14(),
                        getText400(),
                        getColorGrayType3(),
                      ),
                    ],
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            provider.cancelEmergency();
                            Navigator.of(dialogContext).pop();
                          },
                          child: TextWidgetString(
                            '취소',
                            getTextcenter(),
                            getSizeInt16(),
                            getText500(),
                            getColorGrayType2(),
                          ),
                        ),
                      ),
                      SizedBox(width: getSize8()),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await provider.activateEmergency();
                            Navigator.of(dialogContext).pop();
                            _makeEmergencyCall();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: getColorEmergencyRed(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(getSize8()),
                            ),
                          ),
                          child: TextWidgetString(
                            '신고',
                            getTextcenter(),
                            getSizeInt16(),
                            getText600(),
                            getColorWhiteType1(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _makeEmergencyCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '122');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          showTopSnackBar(context, '전화 앱을 실행할 수 없습니다');
        }
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, '긴급 전화 연결에 실패했습니다');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isClosing,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop || _isClosing) return;

        _handleClose(context);
      },
      child: Consumer<EmergencyProvider>(
        builder: (context, emergencyProvider, child) {
          return Consumer<UserState>(
            builder: (context, userState, child) {
              String? shipNm;
              if (userState.mmsi != null) {
                try {
                  final vesselProvider = context.read<VesselProvider>();
                  final userVessel = vesselProvider.vessels.firstWhere(
                        (vessel) => vessel.mmsi == userState.mmsi,
                  );
                  shipNm = userVessel.ship_nm ?? '';
                } catch (e) {
                  shipNm = '';
                }
              } else {
                shipNm = '';
              }

              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: getSize400(),
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                      _buildHeader(emergencyProvider),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.all(getSize20()),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(getSize16()),
                                  decoration: BoxDecoration(
                                    color: getColorEmergencyRed50(),
                                    borderRadius: BorderRadius.circular(getSize12()),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _buildEmergencyButton(),
                                              SizedBox(height: getSize10()),
                                              TextWidgetString(
                                                '긴급 상황 시\n3초간 길게 누르세요',
                                                getTextcenter(),
                                                getSizeInt12(),
                                                getText500(),
                                                getColorEmergencyRed600(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        color: getColorGrayType5(),
                                        margin: EdgeInsets.symmetric(vertical: getSize10()),
                                      ),
                                      Expanded(
                                        flex: 6,
                                        child: Container(
                                          padding: EdgeInsets.all(getSize8()),
                                          child: _buildInfoSection(emergencyProvider, userState, shipNm),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(getSize8()),
                                  child: _buildWarningSection(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(EmergencyProvider emergencyProvider) {
    return Container(
      height: 43,
      padding: EdgeInsets.symmetric(horizontal: getSize14()),
      decoration: BoxDecoration(
        color: getColorEmergencyRed600(),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(getSize20()),
          topRight: Radius.circular(getSize20()),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emergency,
            color: getColorWhiteType1(),
            size: 22,
          ),
          SizedBox(width: getSize6()),
          TextWidgetString(
            '긴급신고',
            getTextleft(),
            getSizeInt18(),
            getText700(),
            getColorWhiteType1(),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              emergencyProvider.toggleLocationTracking();
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: EdgeInsets.all(getSize8()),
              color: Colors.transparent,
              child: Icon(
                emergencyProvider.isLocationTracking
                    ? Icons.location_on
                    : Icons.location_off,
                color: emergencyProvider.isLocationTracking
                    ? getColorEmergencyGreenAccent()
                    : getColorEmergencyWhite70(),
                size: 22,
              ),
            ),
          ),
          SizedBox(
            width: getSize24(),
            height: getSize24(),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.close,
                color: getColorWhiteType1(),
                size: 22,
              ),
              onPressed: () => _handleClose(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isEmergencyPressed = true;
        });
        _animationController.forward();
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        setState(() {
          _isEmergencyPressed = false;
        });
        _animationController.reverse();
        HapticFeedback.lightImpact();
      },
      onTapCancel: () {
        setState(() {
          _isEmergencyPressed = false;
        });
        _animationController.reverse();
      },
      onTap: () {
        HapticFeedback.lightImpact();
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _showEmergencyDialog();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isEmergencyPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              width: 102,
              height: 102,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _isEmergencyPressed
                      ? [
                    getColorEmergencyRed600(),
                    getColorEmergencyRed700(),
                  ]
                      : [
                    getColorEmergencyRed(),
                    getColorEmergencyRed600(),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: getColorEmergencyRedOpacity40(),
                    blurRadius: 12,
                    spreadRadius: _isEmergencyPressed ? 4 : 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.emergency,
                  color: getColorWhiteType1(),
                  size: 48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(EmergencyProvider provider, UserState userState, String? shipNm) {
    final position = provider.currentPosition;
    final latitude = position?.latitude.toStringAsFixed(6) ?? '정보 없음';
    final longitude = position?.longitude.toStringAsFixed(6) ?? '정보 없음';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('선박명', shipNm ?? '정보 없음'),
        SizedBox(height: getSize8()),
        _buildInfoRow('MMSI', userState.mmsi?.toString() ?? '정보 없음'),
        SizedBox(height: getSize8()),
        _buildInfoRow('위도', latitude),
        SizedBox(height: getSize8()),
        _buildInfoRow('경도', longitude),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: getSize60(),
          child: TextWidgetString(
            label,
            getTextleft(),
            getSizeInt12(),
            getText400(),
            getColorGrayType3(),
          ),
        ),
        Expanded(
          child: TextWidgetString(
            value,
            getTextleft(),
            getSizeInt12(),
            getText600(),
            getColorBlackType2(),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningSection() {
    return Container(
      padding: EdgeInsets.all(getSize12()),
      decoration: BoxDecoration(
        color: getColorYellowType1().withOpacity(0.1),
        borderRadius: BorderRadius.circular(getSize8()),
        border: Border.all(
          color: getColorYellowType1(),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: getColorYellowType2(),
            size: 20,
          ),
          SizedBox(width: getSize8()),
          Expanded(
            child: TextWidgetString(
              '긴급신고 시 해양경찰 122로 자동 연결됩니다',
              getTextleft(),
              getSizeInt12(),
              getText400(),
              getColorYellowType2(),
            ),
          ),
        ],
      ),
    );
  }
}