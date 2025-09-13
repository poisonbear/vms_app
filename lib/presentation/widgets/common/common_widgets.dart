import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:flutter_svg/svg.dart';

// svg 파일 불러오기
Widget svgload(svgrul, height, width) {
  return SvgPicture.asset(
    svgrul,
    height: height,
    width: width,
    fit: BoxFit.contain,
  );
}

// 택스트 위젯 - string
Widget TextWidgetString(
  title,
  TextAlign textarray,
  int size,
  FontWeight fontWeight,
  Color color,
) {
  return Text(
    title,
    textAlign: textarray,
    style: TextStyle(
      fontFamily: 'PretendardVariable',
      fontSize: size.toDouble(),
      fontWeight: fontWeight,
      color: color,
    ),
  );
}

// 택스트 위젯 라인 - string
Widget TextWidgetStringLine(
  title,
  TextAlign textarray,
  int size,
  FontWeight fontWeight,
  Color color,
) {
  return Text(
    title,
    textAlign: textarray,
    style: TextStyle(
      fontFamily: 'PretendardVariable',
      fontSize: size.toDouble(),
      fontWeight: fontWeight,
      color: color,
      decoration: TextDecoration.underline, // 밑줄 추가
    ),
  );
}

// 텍스트 입력값을 받을 때
Widget inputWidget(
  int widthsize,
  int heightsize,
  TextEditingController controller,
  String title,
  Color color, {
  bool obscureText = false,
}) {
  return SizedBox(
    width: widthsize.toDouble(),
    height: heightsize.toDouble(),
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: DesignConstants.fontSizeM, decorationThickness: 0),
      decoration: InputDecoration(
        hintText: title,
        hintStyle: TextStyle(color: color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
  );
}

// 비활성화된 텍스트 입력 위젯
Widget inputWidget_deactivate(
  int widthsize,
  int heightsize,
  TextEditingController controller,
  String title,
  Color color, {
  bool isEnabled = true,
  bool isReadOnly = false,
}) {
  return SizedBox(
    width: widthsize.toDouble(),
    height: heightsize.toDouble(),
    child: TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: DesignConstants.fontSizeM,
        decorationThickness: 0,
      ),
      enabled: isEnabled,
      readOnly: isReadOnly,
      decoration: InputDecoration(
        hintText: title,
        hintStyle: TextStyle(
          fontSize: DesignConstants.fontSizeM,
          color: color,
        ),
        labelStyle: const TextStyle(fontSize: DesignConstants.fontSizeM),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        filled: true,
        fillColor: isEnabled ? Colors.white : Colors.grey.shade100,
      ),
    ),
  );
}

// 상단 스낵바 표시 함수
void showTopSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // 3초 후 자동 제거
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

// 원형 버튼 위젯 - 상태 관리 포함
class CircularButton extends StatefulWidget {
  final String svgPath;
  final Color colorOn;
  final Color colorOff;
  final int widthSize;
  final int heightSize;
  final VoidCallback onTap;

  const CircularButton({
    super.key,
    required this.svgPath,
    required this.colorOn,
    required this.colorOff,
    required this.widthSize,
    required this.heightSize,
    required this.onTap,
  });

  @override
  _CircularButtonState createState() => _CircularButtonState();
}

class _CircularButtonState extends State<CircularButton> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isOn = !isOn;
        });
        widget.onTap();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.widthSize.toDouble(),
            height: widget.heightSize.toDouble(),
            decoration: BoxDecoration(
              color: isOn ? widget.colorOn : widget.colorOff,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              widget.svgPath,
              width: 24.0,
              height: 24.0,
            ),
          ),
        ],
      ),
    );
  }
}

// 슬라이드 온 버튼 빌더 함수 (전역 함수로 정의)
// buildCircularButtonSlideOn 함수 제거됨 - 원래 스타일로 대체

// 원래 스타일의 슬라이드 버튼 함수 복원
Widget buildCircularButtonSlideOn(
    String svgPath, Color color, int widthsize, int heightsize, String labelText, int widthSizeline, String statusText,
    {VoidCallback? onTap, bool isSelected = true}) {
  return Padding(
    padding: EdgeInsets.only(bottom: getSize12().toDouble()),
    child: SizedBox(
      width: widthSizeline.toDouble(), // 최대 너비로 고정
      height: heightsize.toDouble(),
      child: Stack(
        clipBehavior: Clip.none, // 자식이 영역을 넘어가도록 허용
        children: [
          // 확장/축소되는 배경 (애니메이션) - 원래 스타일
          Positioned(
            left: 0,
            top: 0,
            child: AnimatedContainer(
              duration: AnimationConstants.durationQuick,
              width: isSelected ? widthSizeline.toDouble() : widthsize.toDouble(),
              height: heightsize.toDouble(),
              decoration: BoxDecoration(
                color: getColorBlackType1(), // 원래 배경색
                borderRadius: BorderRadius.circular(getSize30().toDouble()), // 원래 둥근 모서리
              ),
            ),
          ),

          // 텍스트 영역 (확장 시에만 표시) - 원래 스타일
          if (isSelected)
            Positioned(
              left: widthsize.toDouble() + 8, // 아이콘 오른쪽 여백 추가
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString(labelText, getTextleft(), getSize14(), getText700(), getColorGrayType2()),
                    TextWidgetString(statusText, getTextleft(), getSize14(), getText700(), getColorWhiteType1()),
                  ],
                ),
              ),
            ),

          // 원형 아이콘 (항상 왼쪽에 고정) - 원래 스타일
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
                  width: getSize24().toDouble(),
                  height: getSize24().toDouble(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
