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

// ============================================
// 선박 정보 데이터 클래스
// ============================================ch
class _VesselInfo {
  final String? shipName;
  final double? latitude;
  final double? longitude;

  const _VesselInfo({
    this.shipName,
    this.latitude,
    this.longitude,
  });

  String get formattedLatitude =>
      latitude?.toStringAsFixed(6) ?? InfoMessages.noLocationInfo;

  String get formattedLongitude =>
      longitude?.toStringAsFixed(6) ?? InfoMessages.noLocationInfo;
}

// ============================================
// 메인 함수
// ============================================
Widget mainViewEmergencySheet(BuildContext context, {Function? onClose}) {
  return _EmergencyBottomSheet(onClose: onClose);
}

// ============================================
// 메인 위젯
// ============================================
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
    _initializeAnimation();
  }

  void _initializeAnimation() {
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    widget.onClose?.call();

    final mainScreenState =
        context.findAncestorStateOfType<State<MainScreen>>();
    if (mainScreenState != null) {
      try {
        (mainScreenState as dynamic).selectedIndex = -1;
      } catch (_) {}
    }

    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  }

  _VesselInfo _getVesselInfo(VesselProvider vesselProvider, int? mmsi) {
    if (mmsi == null) return const _VesselInfo();

    try {
      final vessel = vesselProvider.vessels.firstWhere(
        (v) => v.mmsi == mmsi,
      );
      return _VesselInfo(
        shipName: vessel.ship_nm,
        latitude: vessel.lttd,
        longitude: vessel.lntd,
      );
    } catch (_) {
      return const _VesselInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<EmergencyProvider, UserState, VesselProvider>(
      builder: (context, emergencyProvider, userState, vesselProvider, _) {
        final vesselInfo = _getVesselInfo(vesselProvider, userState.mmsi);

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Container(
              color: Colors.transparent,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _EmergencyHeader(onClose: _handleClose),
                    Flexible(
                      child: _EmergencyContent(
                        emergencyProvider: emergencyProvider,
                        userState: userState,
                        vesselInfo: vesselInfo,
                        isEmergencyPressed: _isEmergencyPressed,
                        scaleAnimation: _scaleAnimation,
                        onLongPressStart: _handleLongPressStart,
                        onLongPressEnd: _handleLongPressEnd,
                        onLongPressCancel: _handleLongPressCancel,
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

  void _handleLongPressStart(
      EmergencyProvider provider, int? mmsi, String? shipName) {
    if (_isEmergencyPressed) return;

    setState(() => _isEmergencyPressed = true);
    HapticFeedback.heavyImpact();
    _animationController.forward();
    provider.startEmergency(
      mmsi: mmsi,
      ship_nm: shipName,
      countdownSeconds: 5,
    );
  }

  void _handleLongPressEnd() {
    if (!_isEmergencyPressed) return;

    setState(() => _isEmergencyPressed = false);
    HapticFeedback.lightImpact();
    _animationController.reverse();
  }

  void _handleLongPressCancel() {
    _handleLongPressEnd();
  }
}

// ============================================
// 헤더 위젯
// ============================================
class _EmergencyHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _EmergencyHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s14),
      decoration: const BoxDecoration(
        color: AppColors.emergencyRed900,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.s20),
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
          Expanded(
            child: TextWidgetString(
              '긴급신고',
              TextAligns.left,
              AppSizes.i18,
              FontWeights.w700,
              AppColors.whiteType1,
            ),
          ),
          _HeaderCloseButton(onClose: onClose),
        ],
      ),
    );
  }
}

class _HeaderCloseButton extends StatelessWidget {
  final VoidCallback onClose;

  const _HeaderCloseButton({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.s8),
        color: Colors.transparent,
        child: const Icon(
          Icons.close,
          color: AppColors.whiteType1,
          size: 22,
        ),
      ),
    );
  }
}

// ============================================
// 콘텐츠 위젯
// ============================================
class _EmergencyContent extends StatelessWidget {
  final EmergencyProvider emergencyProvider;
  final UserState userState;
  final _VesselInfo vesselInfo;
  final bool isEmergencyPressed;
  final Animation<double> scaleAnimation;
  final Function(EmergencyProvider, int?, String?) onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onLongPressCancel;

  const _EmergencyContent({
    required this.emergencyProvider,
    required this.userState,
    required this.vesselInfo,
    required this.isEmergencyPressed,
    required this.scaleAnimation,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.whiteType1,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSizes.s20),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 긴급신고 버튼 (40%)
                Expanded(
                  flex: 4,
                  child: _EmergencyButton(
                    provider: emergencyProvider,
                    mmsi: userState.mmsi,
                    shipName: vesselInfo.shipName,
                    isPressed: isEmergencyPressed,
                    scaleAnimation: scaleAnimation,
                    onLongPressStart: () => onLongPressStart(
                      emergencyProvider,
                      userState.mmsi,
                      vesselInfo.shipName,
                    ),
                    onLongPressEnd: onLongPressEnd,
                    onLongPressCancel: onLongPressCancel,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                // 선박 및 위치정보 (60%)
                Expanded(
                  flex: 6,
                  child: _VesselInfoSection(
                    userState: userState,
                    vesselInfo: vesselInfo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s16),
            const _WarningSection(),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 긴급신고 버튼
// ============================================
class _EmergencyButton extends StatelessWidget {
  final EmergencyProvider provider;
  final int? mmsi;
  final String? shipName;
  final bool isPressed;
  final Animation<double> scaleAnimation;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onLongPressCancel;

  const _EmergencyButton({
    required this.provider,
    required this.mmsi,
    required this.shipName,
    required this.isPressed,
    required this.scaleAnimation,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.status == EmergencyStatus.preparing) {
      return _CountdownOverlay(countdownSeconds: provider.countdownSeconds);
    }

    return RepaintBoundary(
      child: GestureDetector(
        onLongPressStart: (_) => onLongPressStart(),
        onLongPressEnd: (_) => onLongPressEnd(),
        onLongPressCancel: onLongPressCancel,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: const _EmergencyButtonContent(),
        ),
      ),
    );
  }
}

class _EmergencyButtonContent extends StatelessWidget {
  const _EmergencyButtonContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emergencyRed800,
            AppColors.emergencyRed900,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.s12),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone,
              color: AppColors.whiteType1,
              size: 64,
            ),
            SizedBox(height: AppSizes.s12),
            Text(
              '긴급신고',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.s16,
                fontWeight: FontWeights.w700,
                color: AppColors.whiteType1,
              ),
            ),
            SizedBox(height: AppSizes.s4),
            Text(
              '3초간 길게 누르세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.s12,
                fontWeight: FontWeights.w400,
                color: AppColors.whiteType1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 카운트다운 오버레이
// ============================================
class _CountdownOverlay extends StatelessWidget {
  final int countdownSeconds;

  const _CountdownOverlay({required this.countdownSeconds});

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.emergencyRed.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CountdownCircle(countdownSeconds: countdownSeconds),
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
          const _CancelButton(),
        ],
      ),
    );
  }
}

class _CountdownCircle extends StatelessWidget {
  final int countdownSeconds;

  const _CountdownCircle({required this.countdownSeconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.whiteType1.withValues(alpha: 0.2),
      ),
      child: Center(
        child: Text(
          '$countdownSeconds',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppSizes.s32,
            fontWeight: FontWeights.w700,
            color: AppColors.whiteType1,
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EmergencyProvider>();

    return TextButton(
      onPressed: () {
        provider.cancelEmergency();
        HapticFeedback.lightImpact();
      },
      style: TextButton.styleFrom(
        backgroundColor: AppColors.whiteType1.withValues(alpha: 0.2),
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
    );
  }
}

// ============================================
// 선박 및 위치정보 섹션
// ============================================
class _VesselInfoSection extends StatelessWidget {
  final UserState userState;
  final _VesselInfo vesselInfo;

  const _VesselInfoSection({
    required this.userState,
    required this.vesselInfo,
  });

  @override
  Widget build(BuildContext context) {
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
          _VesselInfoList(
            userState: userState,
            vesselInfo: vesselInfo,
          ),
        ],
      ),
    );
  }
}

class _VesselInfoList extends StatelessWidget {
  final UserState userState;
  final _VesselInfo vesselInfo;

  const _VesselInfoList({
    required this.userState,
    required this.vesselInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          label: '선박명',
          value: vesselInfo.shipName ?? '정보 없음',
        ),
        const SizedBox(height: AppSizes.s10),
        _InfoRow(
          label: 'MMSI',
          value: userState.mmsi?.toString() ?? '정보 없음',
        ),
        const SizedBox(height: AppSizes.s10),
        _InfoRow(
          label: '위도',
          value: vesselInfo.formattedLatitude,
        ),
        const SizedBox(height: AppSizes.s10),
        _InfoRow(
          label: '경도',
          value: vesselInfo.formattedLongitude,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  //복사 기능 추가
  void _copyToClipboard(BuildContext context, String label, String value) {
    if (value == '정보 없음') return;

    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label이(가) 복사되었습니다'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        // 복사 버튼
        if (value != '정보 없음')
          InkWell(
            onTap: () => _copyToClipboard(context, label, value),
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
    );
  }
}

// ============================================
// 경고 섹션 (세련된 디자인)
// ============================================
class _WarningSection extends StatelessWidget {
  const _WarningSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppSizes.s12),
        border: Border.all(
          color: AppColors.warningBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warningBorder.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘 컨테이너
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.warningIconBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.priority_high,
                color: AppColors.whiteType1,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  const Text(
                    '긴급신고 주의사항',
                    style: TextStyle(
                      fontSize: AppSizes.s14,
                      fontWeight: FontWeights.w700,
                      color: AppColors.warningText,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  // 본문
                  Text(
                    '122 버튼을 3초간 길게 누르면 해양경찰과 연결됩니다.\n거짓 신고 시 법적 처벌을 받을 수 있습니다.',
                    style: TextStyle(
                      fontSize: AppSizes.s12,
                      fontWeight: FontWeights.w400,
                      color: AppColors.warningTextLight,
                      height: 1.5,
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
