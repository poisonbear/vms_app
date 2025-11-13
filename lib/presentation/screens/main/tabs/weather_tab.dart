import 'dart:math';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/presentation/providers/weather_provider.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';

// 싱글톤 인스턴스 관리
class WeatherProviderManager {
  static WidWeatherInfoViewModel? _instance;

  static WidWeatherInfoViewModel getInstance() {
    _instance ??= WidWeatherInfoViewModel();
    return _instance!;
  }

  static void dispose() {
    _instance = null;
  }
}

// 메인 위젯
Widget MainScreenWindy(BuildContext context, {Function? onClose}) {
  return ChangeNotifierProvider<WidWeatherInfoViewModel>.value(
    value: WeatherProviderManager.getInstance(),
    child: _WeatherBottomSheet(onClose: onClose),
  );
}

// 내부 위젯으로 분리
class _WeatherBottomSheet extends StatefulWidget {
  final Function? onClose;

  const _WeatherBottomSheet({this.onClose});

  @override
  State<_WeatherBottomSheet> createState() => _WeatherBottomSheetState();
}

class _WeatherBottomSheetState extends State<_WeatherBottomSheet> {
  bool _isClosing = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isClosing,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop || _isClosing) return;

        final mainScreenState =
            context.findAncestorStateOfType<State<MainScreen>>();
        if (mainScreenState != null) {
          try {
            (mainScreenState as dynamic).selectedIndex = -1;
          } catch (e) {
            AppLogger.e('Error: $e');
          }
        }

        setState(() {
          _isClosing = true;
        });
        Navigator.of(context).pop();
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            minHeight: AppSizes.s350,
            maxHeight: MediaQuery.of(context).size.height * 0.61,
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
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.s20),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A5F), // 어두운 푸른색
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.s20),
          topRight: Radius.circular(AppSizes.s20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud,
            color: AppColors.whiteType1,
            size: 22,
          ),
          const SizedBox(width: AppSizes.s6),
          TextWidgetString(
            '기상정보',
            TextAligns.left,
            AppSizes.i18,
            FontWeights.w700,
            AppColors.whiteType1,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _handleClose(context),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.s8),
              color: Colors.transparent,
              child: const Icon(
                Icons.close,
                color: AppColors.whiteType1,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleClose(BuildContext context) {
    try {
      if (widget.onClose != null) {
        widget.onClose!();
      }

      final mainScreenState =
          context.findAncestorStateOfType<State<MainScreen>>();
      if (mainScreenState != null) {
        try {
          (mainScreenState as dynamic).selectedIndex = -1;
        } catch (e) {
          AppLogger.e('Error: $e');
        }
      }

      setState(() {
        _isClosing = true;
      });

      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.e('닫기 버튼 오류: $e');
    }
  }

  Widget _buildContent(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelsColumn(),
          Expanded(child: _buildDataSection()),
        ],
      ),
    );
  }

  Widget _buildLabelsColumn() {
    final labels = ['', '시간', '풍향', '풍속', '파고', '돌풍', '온도'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 (빈칸)
        Padding(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: TextWidgetString(
            labels[0],
            TextAligns.left,
            AppSizes.i14,
            FontWeights.w700,
            AppColors.blackType2,
          ),
        ),

        // 시간
        Padding(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: TextWidgetString(
            labels[1],
            TextAligns.left,
            AppSizes.i14,
            FontWeights.w700,
            AppColors.blackType2,
          ),
        ),

        // 풍향 (특별 처리)
        Padding(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: SizedBox(
            height:
                AppSizes.s36 + AppSizes.s4 + AppSizes.s9, // 아이콘 + 간격 + 방향텍스트 높이
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextWidgetString(
                labels[2],
                TextAligns.left,
                AppSizes.i14,
                FontWeights.w700,
                AppColors.blackType2,
              ),
            ),
          ),
        ),

        // 풍속
        Padding(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: TextWidgetString(
            labels[3],
            TextAligns.left,
            AppSizes.i14,
            FontWeights.w700,
            AppColors.blackType2,
          ),
        ),

        // 파고
        Padding(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: TextWidgetString(
            labels[4],
            TextAligns.left,
            AppSizes.i14,
            FontWeights.w700,
            AppColors.blackType2,
          ),
        ),

        // 돌풍
        Padding(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: TextWidgetString(
            labels[5],
            TextAligns.left,
            AppSizes.i14,
            FontWeights.w700,
            AppColors.blackType2,
          ),
        ),

        // 온도
        Padding(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: TextWidgetString(
            labels[6],
            TextAligns.left,
            AppSizes.i14,
            FontWeights.w700,
            AppColors.blackType2,
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Consumer<WidWeatherInfoViewModel>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final widList = provider.WidList;
        if (widList == null || widList.isEmpty) {
          return const Center(child: Text('데이터가 없습니다'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            //최적화: ValueKey 추가
            children: List.generate(widList.length, (i) {
              return _WeatherDataColumn(
                key: ValueKey('weather_$i'), //Key 추가
                data: widList[i],
                index: i,
                provider: provider,
              );
            }),
          ),
        );
      },
    );
  }
}

// 날씨 데이터 컬럼 위젯
class _WeatherDataColumn extends StatelessWidget {
  final dynamic data;
  final int index;
  final WidWeatherInfoViewModel provider;

  const _WeatherDataColumn({
    super.key, //Key 파라미터 추가
    required this.data,
    required this.index,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    final textColor = isFirst ? AppColors.skyType2 : AppColors.blackType2;

    return Column(
      children: [
        _buildDate(textColor),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s6),
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: const Radius.circular(AppSizes.s5),
            dashPattern: const [5, 2],
            color: AppColors.grayType7,
            strokeWidth: AppSizes.s1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.grayType12,
                borderRadius: BorderRadius.circular(AppSizes.s5),
              ),
              child: _buildDataContent(textColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDate(Color textColor) {
    String dateText = '';
    try {
      final ts = data.ts?.toString() ?? '';
      if (ts.length >= 13) {
        final hour = ts.substring(11, 13);
        if (hour == '00' || index == 0) {
          dateText = ts.substring(0, 10);
        }
      }
    } catch (e) {
      AppLogger.e('날짜 파싱 오류: $e');
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.s8),
      child: TextWidgetString(
        dateText,
        TextAligns.left,
        AppSizes.i11,
        FontWeights.w700,
        textColor,
      ),
    );
  }

  Widget _buildDataContent(Color textColor) {
    return Column(
      children: [
        _buildTimeText(textColor),
        _buildWindDirection(textColor),
        _buildDataText(
          _safeGetWindSpeed(),
          textColor,
        ),
        _buildDataText(
          '${data.wave_height?.toStringAsFixed(1) ?? '0.0'} m',
          textColor,
        ),
        _buildDataText(
          '${data.gust_surface?.toStringAsFixed(0) ?? '0'} m/s',
          textColor,
        ),
        _buildDataText(
          _calculateTemperature(),
          textColor,
        ),
      ],
    );
  }

  Widget _buildTimeText(Color textColor) {
    String timeText = '00시';
    try {
      final ts = data.ts?.toString() ?? '';
      if (ts.length >= 13) {
        timeText = '${ts.substring(11, 13)}시';
      }
    } catch (e) {
      AppLogger.e('시간 파싱 오류: $e');
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.s8),
      child: TextWidgetString(
        timeText,
        TextAligns.left,
        AppSizes.i14,
        FontWeights.w700,
        textColor,
      ),
    );
  }

  Widget _buildWindDirection(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s8),
      child: Column(
        children: [
          FutureBuilder<Widget>(
            future: svgload(
              'assets/kdn/wid/img/gray_point_rotation0.svg',
              AppSizes.s36,
              AppSizes.s36,
              _safeGetWindIcon(),
              _safeGetWindSpeed(),
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              }
              return const SizedBox(
                width: AppSizes.s36,
                height: AppSizes.s36,
              );
            },
          ),
          const SizedBox(height: AppSizes.s4),
          TextWidgetString(
            _safeGetWindDirection(),
            TextAligns.left,
            AppSizes.i9,
            FontWeights.w700,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDataText(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s8),
      child: TextWidgetString(
        text,
        TextAligns.left,
        AppSizes.i14,
        FontWeights.w700,
        textColor,
      ),
    );
  }

  String _safeGetWindIcon() {
    try {
      return index < provider.windIcon.length
          ? provider.windIcon[index]
          : 'ro0';
    } catch (e) {
      return 'ro0';
    }
  }

  String _safeGetWindSpeed() {
    try {
      return index < provider.windSpeed.length
          ? provider.windSpeed[index]
          : '0 m/s';
    } catch (e) {
      return '0 m/s';
    }
  }

  String _safeGetWindDirection() {
    try {
      return index < provider.windDirection.length
          ? provider.windDirection[index]
          : '';
    } catch (e) {
      return '';
    }
  }

  String _calculateTemperature() {
    try {
      final temp = data.current_temp ?? data.temp_surface;
      if (temp == null) return '0°C';
      final celsius = temp - 273.15;
      return '${celsius.toStringAsFixed(1)}°C';
    } catch (e) {
      AppLogger.e('온도 계산 오류: $e');
      return '0°C';
    }
  }
}

// 원본 svgload 함수
Future<Widget> svgload(
  String svgurl,
  double height,
  double width,
  String windIcon,
  String windSpeed,
) async {
  try {
    AppLogger.d(
        'SVG 로딩: url=$svgurl, windIcon=$windIcon, windSpeed=$windSpeed');

    final speedStr =
        windSpeed.isEmpty ? '0' : windSpeed.replaceAll('m/s', '').trim();
    final speed = double.tryParse(speedStr) ?? 0;

    final String svgString = await rootBundle.loadString(svgurl);
    String pathFillColor = '';

    // 풍속에 따른 색상 변경
    if (speed < 5) {
      pathFillColor = '#666666'; // 회색
    } else if (speed >= 5 && speed < 10) {
      pathFillColor = '#FFD700'; // 노란색
    } else {
      pathFillColor = '#FF0000'; // 빨간색
    }

    RegExp pathRegex = RegExp(r'<path[^>]*>');
    RegExp strokeRectRegex =
        RegExp(r'<rect[^>]*stroke="#[0-9A-Fa-f]{6}"[^>]*>');
    String modifiedSvg = svgString;

    // SVG 색상 변경
    modifiedSvg = modifiedSvg.replaceAllMapped(pathRegex, (Match match) {
      String matchText = match.group(0) ?? '';
      if (matchText.contains('fill="#')) {
        return matchText.replaceAll(
            RegExp(r'fill="#[0-9A-Fa-f]{6}"'), 'fill="$pathFillColor"');
      }
      return matchText;
    });

    modifiedSvg = modifiedSvg.replaceAllMapped(strokeRectRegex, (Match match) {
      String matchText = match.group(0) ?? '';
      if (matchText.contains('stroke="#')) {
        return matchText.replaceAll(
            RegExp(r'stroke="#[0-9A-Fa-f]{6}"'), 'stroke="$pathFillColor"');
      }
      return matchText;
    });

    final iconName = windIcon.isEmpty ? 'ro0' : windIcon;

    // 회전 적용
    if (iconName.startsWith('ro')) {
      final angleStr = iconName.replaceAll('ro', '');
      final angle = int.tryParse(angleStr) ?? 0;
      return Transform.rotate(
        angle: angle * pi / 180,
        child: SvgPicture.string(
          modifiedSvg,
          height: height,
          width: width,
          fit: BoxFit.contain,
        ),
      );
    }

    return SvgPicture.string(
      modifiedSvg,
      height: height,
      width: width,
      fit: BoxFit.contain,
    );
  } catch (e) {
    AppLogger.e('SVG 로딩 오류: $e');
    return Container(
      height: height,
      width: width,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.error_outline, size: 20),
      ),
    );
  }
}
