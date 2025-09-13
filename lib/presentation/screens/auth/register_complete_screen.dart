import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/screens/auth/login_screen.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:vms_app/presentation/widgets/common/custom_app_bar.dart';

class RegisterCompleteView extends StatelessWidget {
  const RegisterCompleteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getColorWhiteType1(),
      appBar: AppBar(
        title: const AppBarLayerView('회원가입'),
        centerTitle: true,
      ),
      body: Container(
        // 배경이미지 추가
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/kdn/usm/img/membership_clear2.png'),
            fit: BoxFit.cover,
            opacity: 0.3, // 배경이미지 투명도 조절 (콘텐츠 가독성 확보)
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 진행 단계 표시
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepIndicator(1, '약관동의', false),
                    _buildStepConnector(),
                    _buildStepIndicator(2, '정보입력', false),
                    _buildStepConnector(),
                    _buildStepIndicator(3, '가입완료', true),
                  ],
                ),
                const SizedBox(height: 50),

                // 완료 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getColorSkyType2().withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: getColorSkyType2(),
                  ),
                ),
                const SizedBox(height: 30),

                // 타이틀
                TextWidgetString(
                  'K-VMS',
                  getTextcenter(),
                  28,
                  getText700(),
                  getColorBlackType2(),
                ),
                const SizedBox(height: 16),

                // 완료 메시지
                TextWidgetString(
                  '회원가입이 완료되었습니다',
                  getTextcenter(),
                  20,
                  getText700(),
                  getColorBlackType2(),
                ),
                const SizedBox(height: 12),
                TextWidgetString(
                  '이제 K-VMS의 모든 서비스를\n이용하실 수 있습니다.',
                  getTextcenter(),
                  14,
                  getText400(),
                  getColorGrayType2(),
                ),
                const SizedBox(height: 50),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginView(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getColorSkyType2(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '로그인하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: getText700(),
                        color: getColorWhiteType1(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 단계 표시기
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
          12,
          getText400(),
          isActive ? getColorBlackType2() : getColorGrayType2(),
        ),
      ],
    );
  }

  // 단계 연결선
  Widget _buildStepConnector() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: getColorGrayType3(),
    );
  }
}
