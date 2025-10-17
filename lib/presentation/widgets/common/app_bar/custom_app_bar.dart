// lib/presentation/widgets/common/app_bar/custom_app_bar.dart

import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';

class AppBarLayerView extends StatelessWidget {
  final String title;

  const AppBarLayerView(
    this.title, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s16),
      child: TextWidgetString(
        title,
        TextAligns.center,
        AppSizes.i20,
        FontWeights.w700,
        AppColors.blackType1,
      ),
    );
  }
}
