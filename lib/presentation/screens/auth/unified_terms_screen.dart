import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/terms_model.dart';
import 'package:vms_app/presentation/providers/terms_provider.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';

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
            getSize24(),
            getSize24(),
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
                getSizeInt16(),
                getText400(),
                getColorGrayType2(),
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
      padding: EdgeInsets.all(getSize20()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 진행 상태 표시 - 회원정보 입력 화면과 동일한 스타일
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator(1, '약관동의', true),
              _buildStepConnector(),
              _buildStepIndicator(2, '정보입력', false),
              _buildStepConnector(),
              _buildStepIndicator(3, '가입완료', false),
            ],
          ),

          SizedBox(height: getSize30()),

          // K-VMS 타이틀
          TextWidgetString(
            'K-VMS',
            getTextcenter(),
            getSizeInt32(),
            getText700(),
            getColorBlackType2(),
          ),
          TextWidgetString(
            '약관동의',
            getTextcenter(),
            getSizeInt32(),
            getText700(),
            getColorBlackType2(),
          ),

          // 소제목
          Padding(
            padding: EdgeInsets.only(
              top: getSize14(),
              bottom: getSize40(),
            ),
            child: TextWidgetString(
              '회원가입을 위해 필수항목 및 선택항목 약관에 동의 해주시기 바랍니다.',
              getTextcenter(),
              getSizeInt14(),
              getText400(),
              getColorGrayType2(),
            ),
          ),

          // 약관 내용
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(getSize16()),
            decoration: BoxDecoration(
              border: Border.all(
                color: getColorGrayType4(),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(getSize4()),
            ),
            child: TextWidgetString(
              terms.terms_ctt ?? '약관 내용을 불러올 수 없습니다.',
              TextAlign.left,
              getSizeInt14(),
              getText400(),
              getColorBlackType2(),
            ),
          ),
        ],
      ),
    );
  }

  // 단계 표시기 - 회원정보 입력 화면과 동일한 스타일
  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? getColorSkyType2() : getColorGrayType3(),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 16,
                fontWeight: getText600(),
                color: getColorWhiteType1(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextWidgetString(
          label,
          getTextcenter(),
          getSizeInt12(),
          getText400(),
          isActive ? getColorBlackType2() : getColorGrayType2(),
        ),
      ],
    );
  }

  // 단계 연결선 - 회원정보 입력 화면과 동일한 스타일
  Widget _buildStepConnector() {
    return Container(
      width: getSize40(),
      height: getSize2(),
      margin: const EdgeInsets.only(bottom: 20),
      color: getColorGrayType3(),
    );
  }
}
