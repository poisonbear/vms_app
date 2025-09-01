import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/presentation/providers/terms_provider.dart';
import 'package:vms_app/presentation/screens/auth/register_screen.dart';
import 'package:vms_app/presentation/screens/auth/unified_terms_screen.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:vms_app/presentation/widgets/common/custom_app_bar.dart';

/// 리팩토링된 약관 동의 화면
class CmdChoiceViewRefactored extends StatelessWidget {
  const CmdChoiceViewRefactored({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TermsProvider(),
      child: const _CmdChoiceViewBody(),
    );
  }
}

class _CmdChoiceViewBody extends StatelessWidget {
  const _CmdChoiceViewBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarLayerView('회원가입'),
        centerTitle: true,
      ),
      body: Consumer<TermsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(getSize20().toDouble()),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildAllAgreementSection(context, provider),
                  _buildTermsList(context, provider),
                  _buildSubmitButton(context, provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: getSize20().toDouble()),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              svgload('assets/kdn/usm/img/Frame_one_on.svg',
                  getSize32().toDouble(), getSize32().toDouble()),
              svgload('assets/kdn/usm/img/Frame_two_off.svg',
                  getSize32().toDouble(), getSize32().toDouble()),
              svgload('assets/kdn/usm/img/Frame_three_off.svg',
                  getSize32().toDouble(), getSize32().toDouble()),
            ],
          ),
        ),
        TextWidgetString('K-VMS', getTextcenter(), getSize32(),
            getText700(), getColorblack_type2()),
        TextWidgetString('약관동의', getTextcenter(), getSize32(),
            getText700(), getColorblack_type2()),
        Padding(
          padding: EdgeInsets.only(
              top: getSize12().toDouble(), bottom: getSize60().toDouble()),
          child: TextWidgetString(
            '회원가입을 위해 필수항목 및 선택항목 약관에 동의 해주시기 바랍니다.',
            getTextcenter(),
            getSize12(),
            getText700(),
            getColorgray_Type2(),
          ),
        ),
      ],
    );
  }

  Widget _buildAllAgreementSection(BuildContext context, TermsProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: getSize20().toDouble()),
      padding: EdgeInsets.all(getSize14().toDouble()),
      decoration: BoxDecoration(
        border: Border.all(color: getColorgray_Type4(), width: getSize1().toDouble()),
        borderRadius: BorderRadius.circular(getSize4().toDouble()),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: getSize1_333(),
            child: Checkbox(
              value: provider.isAllAgreed,
              onChanged: (value) => provider.updateAllAgreements(value ?? false),
              activeColor: getColorsky_Type3(),
              checkColor: getColorwhite_type1(),
              shape: const CircleBorder(),
            ),
          ),
          TextWidgetString('약관에 모두 동의합니다', TextAlign.left,
              getSize14(), getText700(), getColorblack_type2()),
        ],
      ),
    );
  }

  Widget _buildTermsList(BuildContext context, TermsProvider provider) {
    return Column(
      children: [
        _buildTermsRow(
          context,
          provider,
          TermsType.service,
          '서비스 이용약관',
          '(필수)',
          true,
        ),
        _buildTermsRow(
          context,
          provider,
          TermsType.privacy,
          '개인정보수집/이용 동의',
          '(필수)',
          true,
        ),
        _buildTermsRow(
          context,
          provider,
          TermsType.location,
          '위치기반 서비스 이용약관',
          '(필수)',
          true,
        ),
        _buildTermsRow(
          context,
          provider,
          TermsType.marketing,
          '마케팅 활용 동의',
          '(선택)',
          false,
        ),
      ],
    );
  }

  Widget _buildTermsRow(
    BuildContext context,
    TermsProvider provider,
    TermsType type,
    String title,
    String subtitle,
    bool isRequired,
  ) {
    final agreed = provider.agreementStatus[type] ?? false;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          createSlideTransition(
            ChangeNotifierProvider.value(
              value: provider,
              child: UnifiedTermsScreen(
                termsType: type,
                title: title,
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: getSize8().toDouble()),
        child: Row(
          children: [
            Transform.scale(
              scale: 1.333,
              child: Checkbox(
                value: agreed,
                onChanged: (value) => provider.updateAgreement(type, value ?? false),
                activeColor: getColorsky_Type3(),
                checkColor: getColorwhite_type1(),
                shape: const CircleBorder(),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextWidgetString(title, TextAlign.left,
                          getSize14(), getText400(), getColorblack_type2()),
                      SizedBox(width: getSize4().toDouble()),
                      TextWidgetString(
                        subtitle,
                        TextAlign.left,
                        getSize12(),
                        getText400(),
                        isRequired ? getColorred_type1() : getColorgray_Type2(),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: getSize16().toDouble(),
                    color: getColorgray_Type3(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, TermsProvider provider) {
    return Padding(
      padding: EdgeInsets.only(top: getSize40().toDouble()),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: provider.isRequiredAgreed
              ? () {
                  final selectedAgreements = <String>[];
                  if (provider.agreementStatus[TermsType.service]!) {
                    selectedAgreements.add('서비스 이용약관');
                  }
                  if (provider.agreementStatus[TermsType.privacy]!) {
                    selectedAgreements.add('개인정보수집/이용 동의');
                  }
                  if (provider.agreementStatus[TermsType.location]!) {
                    selectedAgreements.add('위치기반 서비스 이용약관');
                  }
                  if (provider.agreementStatus[TermsType.marketing]!) {
                    selectedAgreements.add('마케팅 활용 동의');
                  }

                  debugPrint('버튼 클릭 시간: ${getCurrentDateDateTime()}');
                  debugPrint('선택된 약관: $selectedAgreements');

                  Navigator.push(
                    context,
                    createSlideTransition(
                      Membershipview(nowTime: getCurrentDateDateTime()),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: getColorsky_Type2(),
            shape: getTextradius6(),
            elevation: 0,
            padding: EdgeInsets.all(getSize18().toDouble()),
          ),
          child: TextWidgetString(
            '약관에 동의하고 계속하기',
            getTextcenter(),
            getSize16(),
            getText700(),
            getColorwhite_type1(),
          ),
        ),
      ),
    );
  }
}
