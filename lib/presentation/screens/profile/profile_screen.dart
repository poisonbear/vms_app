// lib/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/screens/auth/login_screen.dart';
import 'package:vms_app/presentation/screens/profile/edit_profile_screen.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import 'package:vms_app/presentation/screens/main/utils/navigation_utils.dart';

class MemberInformationView extends StatefulWidget {
  final String username;

  const MemberInformationView({super.key, required this.username});

  @override
  _RegisterCompleteViewState createState() => _RegisterCompleteViewState();
}

class _RegisterCompleteViewState extends State<MemberInformationView> {
  bool _isSwitched = false;
  final _secureStorage = SecureStorageService(); // ✅ SecureStorage 인스턴스

  @override
  void initState() {
    super.initState();
    _loadAutoLogin(); // 자동 로그인 상태 불러오기
  }

  // SharedPreferences에서 자동 로그인 상태 불러오기
  Future<void> _loadAutoLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwitched = prefs.getBool('auto_login') ?? false;
    });
  }

  Future<void> _saveAutoLogin(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_login', value);

    AppLogger.d('자동 로그인 설정 변경: $value');
  }

  /// SecureStorage도 정리하는 로그아웃
  Future<void> _logout() async {
    try {
      AppLogger.d('로그아웃 시작...');

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. SharedPreferences 데이터 삭제
      await Future.wait([
        prefs.remove('firebase_token'),
        prefs.remove('auto_login'),
        prefs.remove('username'),
        prefs.remove('saved_id'),
        prefs.remove('saved_pw'),
      ]);

      AppLogger.d('SharedPreferences 데이터 삭제 완료');

      // 2. ✅ SecureStorage 데이터 삭제
      await _secureStorage.clearAll();
      AppLogger.d('SecureStorage 데이터 삭제 완료');

      // 3. UserState 초기화 (Provider 사용)
      if (mounted) {
        try {
          final userState = context.read<UserState>();
          await userState.clearUserData();
          AppLogger.d('UserState 초기화 완료');
        } catch (e) {
          AppLogger.e('UserState 초기화 실패: $e');
        }
      }

      // 4. UI 업데이트
      if (mounted) {
        setState(() {
          _isSwitched = false;  // 자동 로그인 스위치 끄기
        });
      }

      AppLogger.i('로그아웃 완료');

    } catch (e) {
      AppLogger.e('로그아웃 중 오류 발생', e);

      // 에러가 발생해도 계속 진행
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃 중 일부 오류가 발생했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const AppBarLayerView('마이페이지'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            right: AppSizes.s20,
            left: AppSizes.s20,
            bottom: AppSizes.s20,
          ),
          child: Column(
            children: [
              // 프로필 이미지와 이름 (세로 배치로 변경)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.s40),
                child: Column(
                  children: [
                    // 프로필 이미지
                    Center(
                      child: SizedBox(
                        width: AppSizes.s96,
                        height: AppSizes.s96,
                        child: SvgPicture.asset(
                          'assets/kdn/usm/img/defult_img.svg',
                          height: AppSizes.s96,
                          width: AppSizes.s96,
                        ),
                      ),
                    ),
                    // 이름과 환영 메시지 (세로 배치)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSizes.s6),
                      child: Column(
                        children: [
                          TextWidgetString(
                              '${widget.username}님',
                              TextAligns.center,
                              AppSizes.i20,
                              FontWeights.w700,
                              AppColors.blackType2),
                          const SizedBox(height: AppSizes.s8),
                          TextWidgetString(
                              '반갑습니다.',
                              TextAligns.center,
                              AppSizes.i12,
                              FontWeights.w700,
                              AppColors.grayType3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 프로필과 로그인/회원정보 섹션 사이 간격 추가
              const SizedBox(height: AppSizes.s20),

              Padding(
                padding: const EdgeInsets.only(
                    top: AppSizes.s20,
                    bottom: AppSizes.s20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextWidgetString(
                    '로그인/회원정보',
                    TextAligns.left,
                    AppSizes.i20,
                    FontWeights.w700,
                    AppColors.blackType2,
                  ),
                ),
              ),

              Container(
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: AppSizes.s12,
                      left: AppSizes.s12,
                      bottom: AppSizes.s8,
                      top: AppSizes.s8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        TextWidgetString(
                          '로그인 정보',
                          TextAligns.left,
                          AppSizes.i16,
                          FontWeights.w700,
                          AppColors.grayType3,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            // ✅ 로그아웃 수행 후 화면 이동
                            await _logout();

                            // 로그인 화면으로 이동
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginView()),
                                    (Route<dynamic> route) => false,
                              );
                            }
                          },
                          child: TextWidgetString(
                            '로그아웃',
                            TextAligns.left,
                            AppSizes.i16,
                            FontWeights.w700,
                            AppColors.redType3,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(
                thickness: AppSizes.s1,
                height: AppSizes.s12,
                indent: 0,
                endIndent: 0,
                color: AppColors.grayType10,
              ),

              Padding(
                padding: const EdgeInsets.only(
                    right: AppSizes.s12,
                    left: AppSizes.s12),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(children: [
                      TextWidgetString('자동 로그인',
                          TextAligns.left,
                          AppSizes.i16,
                          FontWeights.w700,
                          AppColors.grayType3),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSwitched = !_isSwitched;
                          });
                          // ✅ setState 밖에서 비동기 작업 수행
                          _saveAutoLogin(_isSwitched);
                        },
                        child: AnimatedContainer(
                          duration: AppDurations.milliseconds200,
                          width: AppSizes.s70,
                          height: AppSizes.s36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(DesignConstants.radiusXL),
                            border: Border.all(
                              color: _isSwitched ? AppColors.skyType2 : AppColors.grayType11,
                            ),
                            color: _isSwitched ? AppColors.skyType2 : AppColors.grayType11,
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: AppDurations.milliseconds200 ,
                                curve: Curves.easeInOut,
                                left: _isSwitched ? AppSizes.s30 : AppSizes.s0,
                                right: _isSwitched ? AppSizes.s0 : AppSizes.s30,
                                top: AppSizes.s4,
                                bottom: AppSizes.s4,
                                child: Container(
                                  width: AppSizes.s30,
                                  height: AppSizes.s30,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.whiteType1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ])),
              ),

              const Divider(
                thickness: AppSizes.s1,
                height: AppSizes.s12,
                indent: 0,
                endIndent: 0,
                color: AppColors.grayType10,
              ),

              Container(
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: AppSizes.s12,
                      left: AppSizes.s12,
                      bottom: AppSizes.s8,
                      top: AppSizes.s8),
                  child: GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      if (mounted) {
                        Navigator.push(
                          context,
                          createSlideTransition(
                            MemberInformationChange(nowTime: now),
                          ),
                        );
                      }
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          TextWidgetString(
                            '회원정보 수정',
                            TextAligns.left,
                            AppSizes.i16,
                            FontWeights.w700,
                            AppColors.grayType3,
                          ),
                          const Spacer(),
                          SvgPicture.asset(
                            'assets/kdn/usm/img/chevron-right_type1.svg',
                            height: AppSizes.s24,
                            width: AppSizes.s24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 키보드가 올라와도 충분한 여백 확보
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + AppSizes.s50),
            ],
          ),
        ),
      ),
    );
  }
}