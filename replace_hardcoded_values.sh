#!/bin/bash

echo "🔄 하드코딩된 값을 상수로 교체하는 예시..."
echo "================================"

# 1. 예시 파일 백업
echo "📁 [1/3] 예시 파일 백업..."
cp lib/presentation/widgets/common/common_widgets.dart lib/presentation/widgets/common/common_widgets.backup

# 2. common_widgets.dart 파일 수정 예시
echo "📝 [2/3] common_widgets.dart 파일 수정..."
cat > lib/presentation/widgets/common/common_widgets_refactored.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:vms_app/core/constants/constants.dart';  // ✅ 상수 import
import 'package:vms_app/core/utils/size_helper.dart';
import 'package:vms_app/core/utils/color_helper.dart';
import 'package:vms_app/core/utils/font_helper.dart';

// 텍스트 입력 위젯 - 리팩토링 버전
Widget inputWidget(
  int widthsize,
  int heightsize,
  TextEditingController controller,
  String title,
  Color color,
) {
  return SizedBox(
    width: widthsize.toDouble(),
    height: heightsize.toDouble(),
    child: TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: DesignConstants.fontSizeM,  // ✅ 16 → 상수
        decorationThickness: 0,
      ),
      decoration: InputDecoration(
        hintText: title,
        hintStyle: TextStyle(
          fontSize: DesignConstants.fontSizeM,  // ✅ 16 → 상수
          color: color,
        ),
        labelStyle: const TextStyle(
          fontSize: DesignConstants.fontSizeM,  // ✅ 16 → 상수
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
      ),
    ),
  );
}

// SVG 아이콘이 있는 텍스트 입력 위젯
Widget inputWidgetSvg(
  int widthsize,
  int heightsize,
  TextEditingController controller,
  String title,
  Color color,
  String svgPath,
) {
  return SizedBox(
    width: widthsize.toDouble(),
    height: heightsize.toDouble(),
    child: TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: DesignConstants.fontSizeM,  // ✅ 16 → 상수
        decorationThickness: 0,
      ),
      decoration: InputDecoration(
        hintText: title,
        hintStyle: TextStyle(
          fontSize: DesignConstants.fontSizeM,  // ✅ 16 → 상수
          color: color,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(DesignConstants.spacing12),  // ✅ 12.0 → 상수
          child: SvgPicture.asset(
            svgPath,
            width: DesignConstants.iconSizeM,  // ✅ 24 → 상수
            height: DesignConstants.iconSizeM,  // ✅ 24 → 상수
          ),
        ),
      ),
    ),
  );
}

// 상단 스낵바 표시
void showTopSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + DesignConstants.spacing10,  // ✅ 10 → 상수
      left: DesignConstants.spacing20,  // ✅ 20 → 상수
      right: DesignConstants.spacing20,  // ✅ 20 → 상수
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacing16,  // ✅ 16 → 상수
            vertical: DesignConstants.spacing12,    // ✅ 12 → 상수
          ),
          decoration: BoxDecoration(
            color: getColorgray_Type8(),
            borderRadius: BorderRadius.circular(DesignConstants.radiusM),  // ✅ 10 → 상수
            boxShadow: [
              BoxShadow(
                color: getColorgray_Type9(),
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: DesignConstants.spacing10),  // ✅ 10 → 상수
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
  // ✅ Duration(seconds: 3) → 상수
  Future.delayed(AnimationConstants.notificationDuration, () {
    overlayEntry.remove();
  });
}

// 현재 날짜 구하기
String getCurrentDateString() {
  DateTime now = DateTime.now();
  return DateFormat(FormatConstants.yearMonthFormat).format(now);  // ✅ 포맷 상수 사용
}
EOF

# 3. 실제 교체 스크립트 예시
echo "📝 [3/3] 자동 교체 스크립트 생성..."
cat > auto_replace_constants.sh << 'SCRIPT'
#!/bin/bash

echo "🔄 하드코딩된 값들을 자동으로 상수로 교체..."

# fontSize 교체
find lib -name "*.dart" -type f -exec sed -i \
  -e 's/fontSize: 10[^0-9]/fontSize: DesignConstants.fontSizeXXS/g' \
  -e 's/fontSize: 12[^0-9]/fontSize: DesignConstants.fontSizeXS/g' \
  -e 's/fontSize: 14[^0-9]/fontSize: DesignConstants.fontSizeS/g' \
  -e 's/fontSize: 16[^0-9]/fontSize: DesignConstants.fontSizeM/g' \
  -e 's/fontSize: 18[^0-9]/fontSize: DesignConstants.fontSizeL/g' \
  -e 's/fontSize: 20[^0-9]/fontSize: DesignConstants.fontSizeXL/g' \
  -e 's/fontSize: 24[^0-9]/fontSize: DesignConstants.fontSizeXXL/g' \
  {} +

# EdgeInsets.all() 교체
find lib -name "*.dart" -type f -exec sed -i \
  -e 's/EdgeInsets\.all(8)/EdgeInsets.all(DesignConstants.spacing8)/g' \
  -e 's/EdgeInsets\.all(10)/EdgeInsets.all(DesignConstants.spacing10)/g' \
  -e 's/EdgeInsets\.all(12)/EdgeInsets.all(DesignConstants.spacing12)/g' \
  -e 's/EdgeInsets\.all(16)/EdgeInsets.all(DesignConstants.spacing16)/g' \
  -e 's/EdgeInsets\.all(20)/EdgeInsets.all(DesignConstants.spacing20)/g' \
  {} +

# SizedBox 교체
find lib -name "*.dart" -type f -exec sed -i \
  -e 's/SizedBox(height: 8)/SizedBox(height: DesignConstants.spacing8)/g' \
  -e 's/SizedBox(height: 10)/SizedBox(height: DesignConstants.spacing10)/g' \
  -e 's/SizedBox(height: 12)/SizedBox(height: DesignConstants.spacing12)/g' \
  -e 's/SizedBox(height: 16)/SizedBox(height: DesignConstants.spacing16)/g' \
  -e 's/SizedBox(height: 20)/SizedBox(height: DesignConstants.spacing20)/g' \
  {} +

# Duration 교체
find lib -name "*.dart" -type f -exec sed -i \
  -e 's/Duration(milliseconds: 300)/AnimationConstants.durationQuick/g' \
  -e 's/Duration(milliseconds: 500)/AnimationConstants.durationNormal/g' \
  -e 's/Duration(seconds: 2)/AnimationConstants.autoScrollDelay/g' \
  -e 's/Duration(seconds: 3)/AnimationConstants.splashDuration/g' \
  -e 's/Duration(seconds: 30)/AnimationConstants.weatherUpdateInterval/g' \
  {} +

# BorderRadius 교체
find lib -name "*.dart" -type f -exec sed -i \
  -e 's/BorderRadius\.circular(6)/BorderRadius.circular(DesignConstants.radiusS)/g' \
  -e 's/BorderRadius\.circular(10)/BorderRadius.circular(DesignConstants.radiusM)/g' \
  -e 's/BorderRadius\.circular(16)/BorderRadius.circular(DesignConstants.radiusL)/g' \
  -e 's/BorderRadius\.circular(20)/BorderRadius.circular(DesignConstants.radiusXL)/g' \
  {} +

echo "✅ 자동 교체 완료!"
SCRIPT

chmod +x auto_replace_constants.sh

echo ""
echo "================================"
echo "✅ 상수 교체 예시 생성 완료!"
echo ""
echo "📊 생성된 파일들:"
echo "  • common_widgets_refactored.dart - 리팩토링 예시"
echo "  • auto_replace_constants.sh - 자동 교체 스크립트"
echo ""
echo "🔧 사용 방법:"
echo "1. 먼저 상수 파일 생성:"
echo "   ./extract_constants.sh"
echo ""
echo "2. 자동 교체 실행 (선택적):"
echo "   ./auto_replace_constants.sh"
echo ""
echo "3. 수동 교체가 필요한 부분들:"
echo "   - 복잡한 계산식에 포함된 값들"
echo "   - 문자열 내부의 숫자들"
echo "   - 조건문에 사용된 매직넘버들"
echo ""
echo "⚠️ 주의사항:"
echo "  • 자동 교체 전 반드시 백업하세요"
echo "  • 교체 후 flutter analyze로 검증하세요"
echo "  • 일부는 수동으로 확인이 필요할 수 있습니다"
