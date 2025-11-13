import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/widgets/base/text/custom_text.dart';

/// 슬라이드 온 버튼 빌더 함수 - 확장/축소 애니메이션 지원
Widget buildCircularButtonSlideOn(
  String svgPath,
  Color color,
  int widthsize,
  int heightsize,
  String labelText,
  int widthSizeline,
  String statusText, {
  VoidCallback? onTap,
  bool isSelected = true,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: AppSizes.s12.toDouble()),
    child: SizedBox(
      width: widthSizeline.toDouble(),
      height: heightsize.toDouble(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 확장/축소되는 배경
          Positioned(
            left: 0,
            top: 0,
            child: AnimatedContainer(
              duration: AppDurations.milliseconds200,
              width:
                  isSelected ? widthSizeline.toDouble() : widthsize.toDouble(),
              height: heightsize.toDouble(),
              decoration: BoxDecoration(
                color: AppColors.blackType1,
                borderRadius: BorderRadius.circular(AppSizes.s30.toDouble()),
              ),
            ),
          ),

          // 텍스트 영역 (확장 시에만 표시)
          if (isSelected)
            Positioned(
              left: widthsize.toDouble() + 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString(
                      labelText,
                      TextAligns.left,
                      AppSizes.i14,
                      FontWeights.w700,
                      AppColors.grayType2,
                    ),
                    TextWidgetString(
                      statusText,
                      TextAligns.left,
                      AppSizes.i14,
                      FontWeights.w700,
                      AppColors.whiteType1,
                    ),
                  ],
                ),
              ),
            ),

          // 원형 아이콘 (항상 왼쪽에 고정)
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: widthsize.toDouble(),
                height: heightsize.toDouble(),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  svgPath,
                  width: AppSizes.s24.toDouble(),
                  height: AppSizes.s24.toDouble(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 확장 가능한 버튼 클래스 - 더 많은 커스터마이징 옵션
class ExpandableButton extends StatefulWidget {
  final String svgPath;
  final Color buttonColor;
  final Color backgroundColor;
  final String labelText;
  final String statusText;
  final VoidCallback? onTap;
  final bool initiallyExpanded;
  final Duration animationDuration;

  const ExpandableButton({
    super.key,
    required this.svgPath,
    required this.buttonColor,
    this.backgroundColor = Colors.black87,
    required this.labelText,
    required this.statusText,
    this.onTap,
    this.initiallyExpanded = false,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  @override
  _ExpandableButtonState createState() => _ExpandableButtonState();
}

class _ExpandableButtonState extends State<ExpandableButton>
    with SingleTickerProviderStateMixin {
  late bool isExpanded;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _widthAnimation = Tween<double>(
      begin: AppSizes.s50,
      end: AppSizes.s180,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: AppSizes.s50,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.s25),
          ),
          child: InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(AppSizes.s25),
            child: Row(
              children: [
                Container(
                  width: AppSizes.s50,
                  height: AppSizes.s50,
                  decoration: BoxDecoration(
                    color: widget.buttonColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      widget.svgPath,
                      width: AppSizes.s24,
                      height: AppSizes.s24,
                    ),
                  ),
                ),
                if (_widthAnimation.value > 100)
                  Expanded(
                    child: FadeTransition(
                      opacity: _animationController,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.labelText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade300,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.statusText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
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
  }
}
