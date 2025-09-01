import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/presentation/providers/terms_provider.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:vms_app/presentation/widgets/common/custom_app_bar.dart';

/// 통합 약관 상세 화면
class UnifiedTermsScreen extends StatelessWidget {
  final TermsType termsType;
  final String title;

  const UnifiedTermsScreen({
    super.key,
    required this.termsType,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBarLayerView(title),
        leading: IconButton(
          icon: svgload(
            'assets/kdn/usm/img/arrow-left.svg',
            getSize24().toDouble(),
            getSize24().toDouble(),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Consumer<TermsProvider>(
        builder: (context, provider, child) {
          final terms = provider.getTermsByType(termsType);
          
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (terms == null) {
            return Center(
              child: TextWidgetString(
                '약관 정보를 불러올 수 없습니다.',
                getTextcenter(),
                getSize16(),
                getText400(),  // getText500 → getText400으로 수정
                getColorgray_Type2(),
              ),
            );
          }
          
          return _buildTermsContent(terms);
        },
      ),
    );
  }

  Widget _buildTermsContent(CmdModel terms) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(getSize20().toDouble()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 진행 상태 표시
          _buildProgressIndicator(),
          
          // K-VMS 타이틀
          TextWidgetString(
            'K-VMS',
            getTextcenter(),
            getSize32(),
            getText700(),
            getColorblack_type2(),
          ),
          TextWidgetString(
            '약관동의',
            getTextcenter(),
            getSize32(),
            getText700(),
            getColorblack_type2(),
          ),
          
          // 소제목
          Padding(
            padding: EdgeInsets.only(
              top: getSize12().toDouble(),
              bottom: getSize40().toDouble(),
            ),
            child: TextWidgetString(
              '회원가입을 위해 필수항목 및 선택항목 약관에 동의 해주시기 바랍니다.',
              getTextcenter(),
              getSize12(),
              getText700(),
              getColorgray_Type2(),
            ),
          ),
          
          // 약관 제목
          Container(
            padding: EdgeInsets.all(getSize16().toDouble()),
            decoration: BoxDecoration(
              color: getColorsky_Type1(),
              borderRadius: BorderRadius.circular(getSize8().toDouble()),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: getColorwhite_type1(),
                  size: getSize24().toDouble(),
                ),
                SizedBox(width: getSize12().toDouble()),
                Expanded(
                  child: TextWidgetString(
                    terms.terms_nm ?? '약관',  // cmdNm → terms_nm으로 수정
                    TextAlign.left,
                    getSize16(),
                    getText700(),
                    getColorwhite_type1(),
                  ),
                ),
              ],
            ),
          ),
          
          // 약관 내용
          Container(
            margin: EdgeInsets.only(top: getSize20().toDouble()),
            padding: EdgeInsets.all(getSize16().toDouble()),
            decoration: BoxDecoration(
              border: Border.all(
                color: getColorgray_Type4(),
                width: getSize1().toDouble(),
              ),
              borderRadius: BorderRadius.circular(getSize8().toDouble()),
            ),
            child: TextWidgetString(
              terms.terms_ctt ?? '약관 내용을 불러올 수 없습니다.',  // cmdTxt → terms_ctt으로 수정
              TextAlign.left,
              getSize14(),
              getText400(),
              getColorblack_type2(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: getSize20().toDouble()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          svgload(
            'assets/kdn/usm/img/Frame_one_on.svg',
            getSize32().toDouble(),
            getSize32().toDouble(),
          ),
          SizedBox(width: getSize8().toDouble()),
          svgload(
            'assets/kdn/usm/img/Frame_two_off.svg',
            getSize32().toDouble(),
            getSize32().toDouble(),
          ),
          SizedBox(width: getSize8().toDouble()),
          svgload(
            'assets/kdn/usm/img/Frame_three_off.svg',
            getSize32().toDouble(),
            getSize32().toDouble(),
          ),
        ],
      ),
    );
  }
}
