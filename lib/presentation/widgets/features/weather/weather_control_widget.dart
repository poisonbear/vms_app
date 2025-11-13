import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';

/// 날씨 정보 컨트롤 위젯 (파고/시정)
class WeatherControlWidget extends StatefulWidget {
  const WeatherControlWidget({super.key});

  @override
  State<WeatherControlWidget> createState() => _WeatherControlWidgetState();
}

class _WeatherControlWidgetState extends State<WeatherControlWidget> {
  bool isWaveSelected = true;
  bool isVisibilitySelected = true;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSizes.s56,
      left: AppSizes.s20,
      child: Consumer<NavigationProvider>(
        builder: (context, viewModel, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 파고 버튼
              buildCircularButtonSlideOn(
                'assets/kdn/home/img/top_pago_img.svg',
                viewModel.getWaveColor(viewModel.wave),
                AppSizes.i56,
                AppSizes.i56,
                '파고',
                AppSizes.i160,
                viewModel.getFormattedWaveThresholdText(viewModel.wave),
                isSelected: isWaveSelected,
                onTap: () {
                  setState(() {
                    isWaveSelected = !isWaveSelected;
                  });
                },
              ),

              // 시정 버튼
              buildCircularButtonSlideOn(
                'assets/kdn/home/img/top_visibility_img.svg',
                viewModel.getVisibilityColor(viewModel.visibility),
                AppSizes.i56,
                AppSizes.i56,
                '시정',
                AppSizes.i160,
                viewModel
                    .getFormattedVisibilityThresholdText(viewModel.visibility),
                isSelected: isVisibilitySelected,
                onTap: () {
                  setState(() {
                    isVisibilitySelected = !isVisibilitySelected;
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

//기존 WeatherControlButtons 별칭 (하위 호환성)
@Deprecated('Use WeatherControlWidget instead')
class WeatherControlButtons extends WeatherControlWidget {
  const WeatherControlButtons({super.key});
}
