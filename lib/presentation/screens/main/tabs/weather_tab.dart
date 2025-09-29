import 'dart:math';
import 'package:vms_app/core/utils/app_logger.dart';
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

        // ✅ MainScreen의 selectedIndex를 -1로 설정
        final mainScreenState = context.findAncestorStateOfType<State<MainScreen>>();
        if (mainScreenState != null) {
          try {
            (mainScreenState as dynamic).selectedIndex = -1;
          } catch (e) {}
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
            minHeight: getSize350(),
            maxHeight: MediaQuery.of(context).size.height * 0.61,
          ),
          width: double.infinity,
          padding: EdgeInsets.all(getSize20()),
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
              _buildHeader(context),
              _buildTitle(),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: getSize24(),
            height: getSize24(),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: SvgPicture.asset(
                'assets/kdn/usm/img/close.svg',
                width: getSize24(),
                height: getSize24(),
              ),
              onPressed: () => _handleClose(context),
            ),
          ),
        ],
      ),
    );
  }

  void _handleClose(BuildContext context) {
    try {
      // onClose 콜백 호출
      if (widget.onClose != null) {
        widget.onClose!();
      }

      // ✅ MainScreen의 selectedIndex를 -1로 설정
      final mainScreenState = context.findAncestorStateOfType<State<MainScreen>>();
      if (mainScreenState != null) {
        try {
          (mainScreenState as dynamic).selectedIndex = -1;
        } catch (e) {}
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

  Widget _buildTitle() {
    return Row(
      children: [
        TextWidgetString(
          '기상정보',
          getTextleft(),
          getSizeInt30(),
          getText700(),
          getColorBlackType2(),
        ),
      ],
    );
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
    final paddings = [
      const EdgeInsets.only(top: 6, bottom: 10, left: 8, right: 8),
      const EdgeInsets.all(10),
      const EdgeInsets.only(top: 20, bottom: 37, left: 8, right: 8),
      const EdgeInsets.all(10),
      const EdgeInsets.all(10),
      const EdgeInsets.all(10),
      const EdgeInsets.all(10),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(labels.length, (index) {
        return Padding(
          padding: paddings[index].copyWith(
            top: paddings[index].top * getSize1(),
            bottom: paddings[index].bottom * getSize1(),
            left: paddings[index].left * getSize1(),
            right: paddings[index].right * getSize1(),
          ),
          child: TextWidgetString(
            labels[index],
            getTextleft(),
            getSizeInt16(),
            getText700(),
            getColorBlackType2(),
          ),
        );
      }),
    );
  }

  Widget _buildDataSection() {
    return Consumer<WidWeatherInfoViewModel>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
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
            children: List.generate(widList.length, (i) {
              return _WeatherDataColumn(
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
    required this.data,
    required this.index,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    final textColor = isFirst ? getColorSkyType2() : getColorBlackType2();

    return Column(
      children: [
        _buildDate(textColor),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacing8,
          ),
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: const Radius.circular(DesignConstants.radiusS),
            dashPattern: const [6, 3],
            color: getColorGrayType7(),
            strokeWidth: getSize1(),
            child: Container(
              decoration: BoxDecoration(
                color: getColorGrayType12(),
                borderRadius: BorderRadius.circular(6.0),
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
      padding: EdgeInsets.all(getSize10()),
      child: TextWidgetString(
        dateText,
        getTextleft(),
        getSizeInt12(),
        getText700(),
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
      padding: EdgeInsets.all(getSize10()),
      child: TextWidgetString(
        timeText,
        getTextleft(),
        getSizeInt16(),
        getText700(),
        textColor,
      ),
    );
  }

  Widget _buildWindDirection(Color textColor) {
    return Padding(
      padding: EdgeInsets.all(getSize10()),
      child: Column(
        children: [
          FutureBuilder<Widget>(
            future: svgload(
              'assets/kdn/wid/img/gray_point_rotation0.svg',
              getSize40(),
              getSize40(),
              _safeGetWindIcon(),
              _safeGetWindSpeed(),
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              }
              return const SizedBox(width: 40, height: 40);
            },
          ),
          const SizedBox(height: 5),
          TextWidgetString(
            _safeGetWindDirection(),
            getTextleft(),
            getSizeInt10(),
            getText700(),
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDataText(String text, Color textColor) {
    return Padding(
      padding: EdgeInsets.all(getSize10()),
      child: TextWidgetString(
        text,
        getTextleft(),
        getSizeInt16(),
        getText700(),
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
      final temp = data.current_temp ?? 0;
      final celsius = temp - 273.15;
      return '${celsius.toStringAsFixed(0)}°C';
    } catch (e) {
      return '0°C';
    }
  }
}

// svgload 함수 - 그대로 유지
Future<Widget> svgload(String svgurl, double height, double width,
    String windIcon, String windSpeed) async {
  try {
    AppLogger.d('SVG 로딩: url=$svgurl, windIcon=$windIcon, windSpeed=$windSpeed');

    final speedStr = windSpeed.isEmpty ? '0' : windSpeed.replaceAll('m/s', '').trim();
    final speed = double.tryParse(speedStr) ?? 0;

    final String svgString = await rootBundle.loadString(svgurl);
    String pathFillColor = '';

    if (speed < 5) {
      pathFillColor = '#666666';
    } else if (speed >= 5 && speed < 10) {
      pathFillColor = '#FFD700';
    } else {
      pathFillColor = '#FF0000';
    }

    RegExp pathRegex = RegExp(r'<path[^>]*>');
    RegExp strokeRectRegex = RegExp(r'<rect[^>]*stroke="#[0-9A-Fa-f]{6}"[^>]*>');
    String modifiedSvg = svgString;

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