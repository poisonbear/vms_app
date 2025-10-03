import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/terms_model.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';

// 동적 페이지를 구현 할려면
class AppBarLayerView extends StatefulWidget {
  // StatefulWidget 상속받기
  final String title; // 만약 값을 받아야 한다면  변수 타입과, 변수명 설정 , 추가 설정도 가능
  const AppBarLayerView(this.title, {super.key});

  @override
  State<AppBarLayerView> createState() => _AppBarState();
}

class _AppBarState extends State<AppBarLayerView> {
  late List<CmdModel> cmdList; // 변수명도 camelCase로 수정

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSizes.s16,
        bottom: AppSizes.s16,
      ),
      child: TextWidgetString(
        widget.title, TextAligns.center, AppSizes.i20, FontWeights.w700,
        AppColors.blackType1, // 받은값은 widget.title로 기재 가능
      ),
    );
  }
}
