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
        } catch (e) {}
      }

      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('닫기 버튼 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<EmergencyProvider, UserState, VesselProvider>(
      builder: (context, emergencyProvider, userState, vesselProvider, child) {
        // 선박명 가져오기
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

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Container(
              color: Colors.transparent,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(emergencyProvider),
                    Flexible(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.whiteType1,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(AppSizes.s20),
                            bottomRight: Radius.circular(AppSizes.s20),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.s16),
                            child: Column(
                              children: [
                                // 메인 컨텐츠 영역 - 좌우 배치
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 왼쪽: 긴급신고 버튼 (40%)
                                    Expanded(
                                      flex: 4,
                                      child: _buildEmergencyButton(
                                        emergencyProvider,
                                        userState.mmsi,
                                        shipNm,
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.s12),
                                    // 오른쪽: 선박 및 위치정보 (60%)
                                    Expanded(
                                      flex: 6,
                                      child: _buildInfoSection(
                                        emergencyProvider,
                                        userState,
                                        shipNm,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.s16),
                                // 아래: 경고 문구
                                _buildWarningSection(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(EmergencyProvider emergencyProvider) {
    return Container(
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s14),
      decoration: const BoxDecoration(
        color: AppColors.emergencyRed600,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.s20),
          topRight: Radius.circular(AppSizes.s20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emergency,
            color: AppColors.whiteType1,
            size: 22,
          ),
          const SizedBox(width: AppSizes.s6),
          TextWidgetString(
            '긴급신고',
            TextAligns.left,
            AppSizes.i18,
            FontWeights.w700,
            AppColors.whiteType1,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              emergencyProvider.toggleLocationTracking();
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: const EdgeInsets.all(AppSizes.s8),
              color: Colors.transparent,
              child: Icon(
                emergencyProvider.isLocationTracking
                    ? Icons.location_on
                    : Icons.location_off,
                color: emergencyProvider.isLocationTracking
                    ? AppColors.whiteType1
                    : AppColors.whiteType1.withOpacity(0.5),
                size: 22,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _handleClose(context),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.s8),
              color: Colors.transparent,
              child: const Icon(
                Icons.close,
                color: AppColors.whiteType1,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(
      EmergencyProvider provider,
      int? mmsi,
      String? shipNm,
      ) {
    if (provider.status == EmergencyStatus.preparing) {
      return _buildCountdownOverlay(provider);
    }

    return GestureDetector(
      onLongPressStart: (_) {
        if (!_isEmergencyPressed) {
          setState(() => _isEmergencyPressed = true);
          HapticFeedback.heavyImpact();
          _animationController.forward();
          provider.startEmergency(
            mmsi: mmsi,
            ship_nm: shipNm,
            countdownSeconds: 5,
          );
        }
      },
      onLongPressEnd: (_) {
        if (_isEmergencyPressed) {
          setState(() => _isEmergencyPressed = false);
          HapticFeedback.lightImpact();
          _animationController.reverse();
        }
      },
      onLongPressCancel: () {
        if (_isEmergencyPressed) {
          setState(() => _isEmergencyPressed = false);
          HapticFeedback.lightImpact();
          _animationController.reverse();
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.emergencyRed600,
                AppColors.emergencyRed,
              ],
            ),
            borderRadius: BorderRadius.circular(AppSizes.s12),
            boxShadow: [
              BoxShadow(
                color: AppColors.emergencyRed.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone,
                  color: AppColors.whiteType1,
                  size: 64,
                ),
                const SizedBox(height: AppSizes.s12),
                const Text(
                  '긴급신고',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.s16,
                    fontWeight: FontWeights.w700,
                    color: AppColors.whiteType1,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  '3초간 길게 누르세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.s12,
                    fontWeight: FontWeights.w400,
                    color: AppColors.whiteType1.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay(EmergencyProvider provider) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emergencyRed600,
            AppColors.emergencyRed,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.s12),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.whiteType1.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                '${provider.countdownSeconds}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppSizes.s32,
                  fontWeight: FontWeights.w700,
                  color: AppColors.whiteType1,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          const Text(
            '초 후 자동 연결됩니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.s14,
              fontWeight: FontWeights.w600,
              color: AppColors.whiteType1,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          TextButton(
            onPressed: () {
              provider.cancelEmergency();
              HapticFeedback.lightImpact();
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.whiteType1.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s20,
                vertical: AppSizes.s10,
              ),
            ),
            child: const Text(
              '취소',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.s14,
                fontWeight: FontWeights.w600,
                color: AppColors.whiteType1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(EmergencyProvider provider, UserState userState, String? shipNm) {
    final position = provider.currentPosition;
    final latitude = position?.latitude.toStringAsFixed(6) ?? '정보 없음';
    final longitude = position?.longitude.toStringAsFixed(6) ?? '정보 없음';

    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: AppColors.grayType15,
        borderRadius: BorderRadius.circular(AppSizes.s12),
        border: Border.all(
          color: AppColors.grayType2,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '선박 및 위치정보',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.s16,
              fontWeight: FontWeights.w700,
              color: AppColors.blackType1,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('선박명', shipNm ?? '정보 없음'),
              const SizedBox(height: AppSizes.s10),
              _buildInfoRow('MMSI', userState.mmsi?.toString() ?? '정보 없음'),
              const SizedBox(height: AppSizes.s10),
              _buildInfoRow('위도', latitude),
              const SizedBox(height: AppSizes.s10),
              _buildInfoRow('경도', longitude),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSizes.s60,
          child: Text(
            label,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: AppSizes.s14,
              fontWeight: FontWeights.w500,
              color: AppColors.grayType3,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: AppSizes.s14,
              fontWeight: FontWeights.w600,
              color: AppColors.blackType2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: AppColors.yellowType1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.s8),
        border: Border.all(
          color: AppColors.yellowType1,
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.yellowType2,
            size: 24,
          ),
          SizedBox(width: AppSizes.s12),
          Expanded(
            child: Text(
              '긴급 상황 시 122 버튼을 3초간 길게 누르면 해양경찰과 연결됩니다.\n거짓 신고 시 법적 처벌을 받을 수 있습니다.',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: AppSizes.s13,
                fontWeight: FontWeights.w400,
                color: AppColors.yellowType2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}