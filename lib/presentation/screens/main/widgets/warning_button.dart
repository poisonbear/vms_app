import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/network/dio_client.dart';

/// 경고 팝업 버튼 위젯
class WarningPopButton extends StatelessWidget {
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

  const WarningPopButton({
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
    return Padding(
      padding: EdgeInsets.only(bottom: getSize12().toDouble()),
      child: GestureDetector(
        onTap: () {
          warningPop(
            context,
            title,
            titleColor,
            detail,
            detailColor,
            alarmIcon,
            shadowColor,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: widthSizeLine.toDouble(),
              height: heightSize.toDouble(),
            ),
            Positioned(
              left: getSize0().toDouble(),
              child: Container(
                width: widthSize.toDouble(),
                height: heightSize.toDouble(),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  svgPath,
                  width: getSize24().toDouble(),
                  height: getSize24().toDouble(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상세 경고 팝업 버튼 위젯
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
    return Padding(
      padding: EdgeInsets.only(bottom: getSize12().toDouble()),
      child: GestureDetector(
        onTap: () {
          warningPopdetail(
            context,
            title,
            titleColor,
            detail,
            detailColor,
            '',
            alarmIcon,
            shadowColor,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: widthSizeLine.toDouble(),
              height: heightSize.toDouble(),
            ),
            Positioned(
              left: getSize0().toDouble(),
              child: Container(
                width: widthSize.toDouble(),
                height: heightSize.toDouble(),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  svgPath,
                  width: getSize24().toDouble(),
                  height: getSize24().toDouble(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
