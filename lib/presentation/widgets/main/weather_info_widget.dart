import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';

/// 상단 날씨 정보 위젯 (파고/시정)
class WeatherInfoWidget extends StatefulWidget {
  const WeatherInfoWidget({super.key});

  @override
  State<WeatherInfoWidget> createState() => _WeatherInfoWidgetState();
}

class _WeatherInfoWidgetState extends State<WeatherInfoWidget> {
  bool isWaveSelected = true;
  bool isVisibilitySelected = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, viewModel, _) {
        return Padding(
          padding: EdgeInsets.only(
            top: getSize56().toDouble(),
            bottom: getSize32().toDouble(),
            right: getSize20().toDouble(),
            left: getSize20().toDouble(),
          ),
          child: Column(
            children: [
              // 파고 버튼
              buildCircularButtonSlideOn(
                'assets/kdn/home/img/top_pago_img.svg',
                viewModel.getWaveColor(viewModel.wave),
                getSize56(),
                getSize56(),
                '파고',
                getSize160(),
                viewModel.getFormattedWaveThresholdText(viewModel.wave),
                isSelected: isWaveSelected,
                onTap: () => setState(() => isWaveSelected = !isWaveSelected),
              ),

              // 시정 버튼
              buildCircularButtonSlideOn(
                'assets/kdn/home/img/top_visibility_img.svg',
                viewModel.getVisibilityColor(viewModel.visibility),
                getSize56(),
                getSize56(),
                '시정',
                getSize160(),
                viewModel
                    .getFormattedVisibilityThresholdText(viewModel.visibility),
                isSelected: isVisibilitySelected,
                onTap: () => setState(
                    () => isVisibilitySelected = !isVisibilitySelected),
              ),
            ],
          ),
        );
      },
    );
  }
}
