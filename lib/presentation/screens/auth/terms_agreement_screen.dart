import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/presentation/providers/terms_provider.dart';
import 'package:vms_app/presentation/screens/auth/unified_terms_screen.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:vms_app/presentation/screens/auth/register_screen.dart';
import 'package:vms_app/presentation/screens/main/utils/navigation_utils.dart';

/// 약관 동의 화면
class CmdChoiceView extends StatelessWidget {
  const CmdChoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => TermsProvider(), child: const _CmdChoiceViewBody());
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
              padding: const EdgeInsets.all(AppSizes.s20),
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
        // 진행 단계 표시 - 회원정보 입력 화면과 동일한 스타일로 변경
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.s20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator(1, '약관동의', true),
              _buildStepConnector(),
              _buildStepIndicator(2, '정보입력', false),
              _buildStepConnector(),
              _buildStepIndicator(3, '가입완료', false),
            ],
          ),
        ),
        TextWidgetString('K-VMS', TextAligns.center, AppSizes.i32,
            FontWeights.w700, AppColors.blackType2),
        TextWidgetString('약관동의', TextAligns.center, AppSizes.i32,
            FontWeights.w700, AppColors.blackType2),
        Padding(
          padding:
              const EdgeInsets.only(top: AppSizes.s12, bottom: AppSizes.s60),
          child: TextWidgetString(
            '회원가입을 위해 필수항목 및 선택항목 약관에 동의 해주시기 바랍니다.',
            TextAligns.center,
            AppSizes.i12,
            FontWeights.w700,
            AppColors.grayType2,
          ),
        ),
      ],
    );
  }

  Widget _buildAllAgreementSection(
      BuildContext context, TermsProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s20),
      padding: const EdgeInsets.all(AppSizes.s14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grayType4, width: AppSizes.s1),
        borderRadius: BorderRadius.circular(AppSizes.s4),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: AppSizes.s1_333,
            child: Checkbox(
              value: provider.isAllAgreed,
              onChanged: (value) =>
                  provider.updateAllAgreements(value ?? false),
              activeColor: AppColors.skyType3,
              checkColor: AppColors.whiteType1,
              shape: const CircleBorder(),
            ),
          ),
          TextWidgetString('약관에 모두 동의합니다', TextAlign.left, AppSizes.i14,
              FontWeights.w700, AppColors.blackType2),
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
        padding: const EdgeInsets.symmetric(vertical: AppSizes.s8),
        child: Row(
          children: [
            Transform.scale(
              scale: 1.333,
              child: Checkbox(
                value: agreed,
                onChanged: (value) =>
                    provider.updateAgreement(type, value ?? false),
                activeColor: AppColors.skyType3,
                checkColor: AppColors.whiteType1,
                shape: const CircleBorder(),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextWidgetString(title, TextAlign.left, AppSizes.i14,
                          FontWeights.w400, AppColors.blackType2),
                      const SizedBox(width: AppSizes.s4),
                      TextWidgetString(
                        subtitle,
                        TextAlign.left,
                        AppSizes.i12,
                        FontWeights.w400,
                        isRequired ? AppColors.redType1 : AppColors.grayType2,
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: AppSizes.s16,
                    color: AppColors.grayType3,
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
      padding: const EdgeInsets.only(top: AppSizes.s40),
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

                  AppLogger.d('버튼 클릭 시간: ${DateTime.now()}');
                  AppLogger.d('선택된 약관: $selectedAgreements');

                  Navigator.push(
                    context,
                    createSlideTransition(
                      const RegisterScreen(),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.skyType2,
            shape: Borders.rounded10,
            elevation: 0,
            padding: const EdgeInsets.all(AppSizes.s18),
          ),
          child: TextWidgetString(
            '약관에 동의하고 계속하기',
            TextAligns.center,
            AppSizes.i16,
            FontWeights.w700,
            AppColors.whiteType1,
          ),
        ),
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
            color: isActive ? AppColors.skyType2 : AppColors.grayType3,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeights.w600,
                color: AppColors.whiteType1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextWidgetString(
          label,
          TextAligns.center,
          12,
          FontWeights.w400,
          isActive ? AppColors.blackType2 : AppColors.grayType2,
        ),
      ],
    );
  }

  // 단계 연결선 - 회원정보 입력 화면과 동일한 스타일
  Widget _buildStepConnector() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: AppColors.grayType3,
    );
  }
}
