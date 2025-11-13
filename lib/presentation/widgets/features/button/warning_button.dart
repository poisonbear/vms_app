// lib/presentation/widgets/features/button/warning_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/widgets/common/dialogs/dialog_utils.dart';

/// 통합된 경고 팝업 버튼 위젯
class WarningPopButton extends StatelessWidget {
  // 버튼 UI 속성
  final String svgPath;
  final Color color;
  final double widthSize;
  final double heightSize;
  final double widthSizeLine;

  // 라벨
  final String labelText;

  // 팝업 내용 속성
  final String title;
  final Color titleColor;
  final String detail;
  final Color detailColor;
  final String alarmIcon;
  final Color shadowColor;

  // 상세 버전 여부
  final bool isDetailVersion;

  const WarningPopButton({
    super.key,
    required this.svgPath,
    required this.color,
    required this.widthSize, //this.widthSize로 직접 초기화
    required this.heightSize, //this.heightSize로 직접 초기화
    required this.labelText,
    required this.widthSizeLine, //this.widthSizeLine로 직접 초기화
    required this.title,
    required this.titleColor,
    required this.detail,
    required this.detailColor,
    required this.alarmIcon,
    required this.shadowColor,
    this.isDetailVersion = false,
  });

  // int 타입 지원을 위한 팩토리 생성자 (하위 호환성)
  factory WarningPopButton.fromInt({
    Key? key,
    required String svgPath,
    required Color color,
    required int widthSize,
    required int heightSize,
    required String labelText,
    required int widthSizeLine,
    required String title,
    required Color titleColor,
    required String detail,
    required Color detailColor,
    required String alarmIcon,
    required Color shadowColor,
    bool isDetailVersion = false,
  }) {
    return WarningPopButton(
      key: key,
      svgPath: svgPath,
      color: color,
      widthSize: widthSize.toDouble(),
      heightSize: heightSize.toDouble(),
      labelText: labelText,
      widthSizeLine: widthSizeLine.toDouble(),
      title: title,
      titleColor: titleColor,
      detail: detail,
      detailColor: detailColor,
      alarmIcon: alarmIcon,
      shadowColor: shadowColor,
      isDetailVersion: isDetailVersion,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s12),
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: _buildButton(),
      ),
    );
  }

  /// 버튼 UI 구성
  Widget _buildButton() {
    return SizedBox(
      width: widthSizeLine,
      height: heightSize,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: widthSize,
          height: heightSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            svgPath,
            width: AppSizes.s24,
            height: AppSizes.s24,
          ),
        ),
      ),
    );
  }

  /// 탭 핸들러
  void _handleTap(BuildContext context) {
    if (isDetailVersion) {
      // warningPopdetail은 명명된 매개변수를 사용
      warningPopdetail(
        context,
        title: title,
        message: detail, // detail을 message로 전달
      );
    } else {
      // warningPop은 위치 매개변수를 사용
      warningPop(
        context,
        '$title\n\n$detail', // title과 detail을 하나의 메시지로 결합
      );
    }
  }
}

/// 상세 경고 팝업 버튼 위젯 (하위 호환성을 위한 별칭)
class WarningPopDetailButton extends StatelessWidget {
  final String svgPath;
  final Color color;
  final int widthSize;
  final int heightSize;
  final String labelText;
  final int widthSizeLine;
  final String title;
  final Color titleColor;
  final String detail;
  final Color detailColor;
  final String alarmIcon;
  final Color shadowColor;

  const WarningPopDetailButton({
    super.key,
    required this.svgPath,
    required this.color,
    required this.widthSize,
    required this.heightSize,
    required this.labelText,
    required this.widthSizeLine,
    required this.title,
    required this.titleColor,
    required this.detail,
    required this.detailColor,
    required this.alarmIcon,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return WarningPopButton.fromInt(
      svgPath: svgPath,
      color: color,
      widthSize: widthSize,
      heightSize: heightSize,
      labelText: labelText,
      widthSizeLine: widthSizeLine,
      title: title,
      titleColor: titleColor,
      detail: detail,
      detailColor: detailColor,
      alarmIcon: alarmIcon,
      shadowColor: shadowColor,
      isDetailVersion: true, // 상세 버전으로 설정
    );
  }
}

/// 기본값을 가진 편의 팩토리 메서드 추가
extension WarningPopButtonFactory on WarningPopButton {
  /// 터빈 경고 버튼 생성
  static WarningPopButton turbineWarning({
    required String title,
    required String detail,
    VoidCallback? onClose,
  }) {
    return WarningPopButton(
      svgPath: 'assets/kdn/home/img/turbine_warning.svg',
      color: const Color(0xFFDF2B2E),
      widthSize: AppSizes.s56,
      heightSize: AppSizes.s56,
      labelText: '터빈 경고',
      widthSizeLine: AppSizes.s160,
      title: title,
      titleColor: const Color(0xFFDF2B2E),
      detail: detail,
      detailColor: const Color(0xFF999999),
      alarmIcon: 'assets/kdn/home/img/red_triangle-exclamation.svg',
      shadowColor: Colors.black,
    );
  }

  /// 날씨 경고 버튼 생성
  static WarningPopButton weatherWarning({
    required String title,
    required String detail,
    VoidCallback? onClose,
  }) {
    return WarningPopButton(
      svgPath: 'assets/kdn/home/img/weather_warning.svg',
      color: Colors.orange,
      widthSize: AppSizes.s56,
      heightSize: AppSizes.s56,
      labelText: '날씨 경고',
      widthSizeLine: AppSizes.s160,
      title: title,
      titleColor: Colors.orange,
      detail: detail,
      detailColor: const Color(0xFF999999),
      alarmIcon: 'assets/kdn/home/img/weather_alert.svg',
      shadowColor: Colors.black,
    );
  }

  /// 해저케이블 경고 버튼 생성
  static WarningPopButton submarineWarning({
    required String title,
    required String detail,
    VoidCallback? onClose,
  }) {
    return WarningPopButton(
      svgPath: 'assets/kdn/home/img/cable_warning.svg',
      color: Colors.red,
      widthSize: AppSizes.s56,
      heightSize: AppSizes.s56,
      labelText: '케이블 경고',
      widthSizeLine: AppSizes.s160,
      title: title,
      titleColor: Colors.red,
      detail: detail,
      detailColor: const Color(0xFF999999),
      alarmIcon: 'assets/kdn/home/img/cable_alert.svg',
      shadowColor: Colors.black,
      isDetailVersion: true,
    );
  }
}
