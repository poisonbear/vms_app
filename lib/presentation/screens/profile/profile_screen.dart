import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // ✅ Provider 추가
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/app_logger.dart';  // ✅ AppLogger 추가
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';  // ✅ UserState 추가
import 'package:vms_app/presentation/screens/auth/login_screen.dart';
import 'package:vms_app/presentation/screens/profile/edit_profile_screen.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:vms_app/presentation/widgets/common/custom_app_bar.dart';

class MemberInformationView extends StatefulWidget {
  final String username;

  const MemberInformationView({super.key, required this.username});

  @override
  _RegisterCompleteViewState createState() => _RegisterCompleteViewState();
}

class _RegisterCompleteViewState extends State<MemberInformationView> {
  bool _isSwitched = false;

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

  // ✅ 수정된 _logout 메서드
  Future<void> _logout() async {
    try {
      AppLogger.d('로그아웃 시작...');

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. 비동기 작업을 먼저 수행 (setState 밖에서)
      await prefs.remove('firebase_token');
      await prefs.remove('auto_login');
      await prefs.remove('username');
      await prefs.remove('saved_id');  // ✅ 저장된 ID 제거
      await prefs.remove('saved_pw');  // ✅ 저장된 PW 제거

      AppLogger.d('SharedPreferences 데이터 삭제 완료');

      // 2. UserState 초기화 (Provider 사용)
      if (mounted) {
        try {
          final userState = context.read<UserState>();
          await userState.clearUserData();
          AppLogger.d('UserState 초기화 완료');
        } catch (e) {
          AppLogger.e('UserState 초기화 실패: $e');
        }
      }

      // 3. UI 업데이트가 필요한 경우만 setState 호출 (동기적으로)
      if (mounted) {
        setState(() {
          _isSwitched = false;  // 자동 로그인 스위치 끄기
        });
      }

      AppLogger.d('✅ 로그아웃 완료');

    } catch (e) {
      AppLogger.e('로그아웃 중 오류 발생: $e');

      // 에러가 발생해도 로그인 화면으로는 이동
      if (mounted) {
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
          padding: EdgeInsets.only(
            right: getSize20().toDouble(),
            left: getSize20().toDouble(),
            bottom: getSize20().toDouble(),
          ),
          child: Column(
            children: [
              // 프로필 이미지와 이름 (세로 배치로 변경)
              Padding(
                padding: EdgeInsets.only(top: getSize40().toDouble()),
                child: Column(
                  children: [
                    // 프로필 이미지
                    Center(
                      child: SizedBox(
                        width: getSize96().toDouble(),
                        height: getSize96().toDouble(),
                        child: SvgPicture.asset(
                          'assets/kdn/usm/img/defult_img.svg',
                          height: getSize96().toDouble(),
                          width: getSize96().toDouble(),
                        ),
                      ),
                    ),
                    // 이름과 환영 메시지 (세로 배치)
                    Padding(
                      padding: EdgeInsets.only(top: getSize6().toDouble()),
                      child: Column(
                        children: [
                          TextWidgetString(
                              '${widget.username}님',
                              getTextcenter(),
                              getSize20(),
                              getText700(),
                              getColorBlackType2()),
                          SizedBox(height: getSize8().toDouble()),
                          TextWidgetString(
                              '반갑습니다.',
                              getTextcenter(),
                              getSize12(),
                              getText700(),
                              getColorGrayType3()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 프로필과 로그인/회원정보 섹션 사이 간격 추가
              SizedBox(height: getSize20().toDouble()),

              Padding(
                padding: EdgeInsets.only(
                    top: getSize20().toDouble(),
                    bottom: getSize20().toDouble()),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextWidgetString(
                    '로그인/회원정보',
                    getTextleft(),
                    getSize20(),
                    getText700(),
                    getColorBlackType2(),
                  ),
                ),
              ),

              Container(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: getSize12().toDouble(),
                      left: getSize12().toDouble(),
                      bottom: getSize8().toDouble(),
                      top: getSize8().toDouble()),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        TextWidgetString(
                          '로그인 정보',
                          getTextleft(),
                          getSize16(),
                          getText700(),
                          getColorGrayType3(),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            // ✅ 로그아웃 수행 후 화면 이동
                            await _logout();

                            // 로그인 화면으로 이동
                            if (mounted) {
                              if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginView()),
                                    (Route<dynamic> route) => false,
                              );
                              }
                            }
                          },
                          child: TextWidgetString(
                            '로그아웃',
                            getTextleft(),
                            getSize16(),
                            getText700(),
                            getColorRedType3(),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              Divider(
                thickness: 1,
                height: 12,
                indent: 0,
                endIndent: 0,
                color: getColorGrayType10(),
              ),

              Padding(
                padding: EdgeInsets.only(
                    right: getSize12().toDouble(),
                    left: getSize12().toDouble()),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(children: [
                      TextWidgetString('자동 로그인',
                          getTextleft(),
                          getSize16(),
                          getText700(),
                          getColorGrayType3()),
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
                          duration: AnimationConstants.durationQuick,
                          width: getSize70().toDouble(),
                          height: getSize36().toDouble(),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(DesignConstants.radiusXL),
                            border: Border.all(
                              color: _isSwitched ? getColorSkyType2() : getColorGrayType11(),
                            ),
                            color: _isSwitched ? getColorSkyType2() : getColorGrayType11(),
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: AnimationConstants.durationFast,
                                curve: Curves.easeInOut,
                                left: _isSwitched ? getSize30().toDouble() : getSize0().toDouble(),
                                right: _isSwitched ? getSize0().toDouble() : getSize30().toDouble(),
                                top: getSize4().toDouble(),
                                bottom: getSize4().toDouble(),
                                child: Container(
                                  width: getSize30().toDouble(),
                                  height: getSize30().toDouble(),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: getColorWhiteType1(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ])),
              ),

              Divider(
                thickness: 1,
                height: 12,
                indent: 0,
                endIndent: 0,
                color: getColorGrayType10(),
              ),

              Container(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: getSize12().toDouble(),
                      left: getSize12().toDouble(),
                      bottom: getSize8().toDouble(),
                      top: getSize8().toDouble()),
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
                            getTextleft(),
                            getSize16(),
                            getText700(),
                            getColorGrayType3(),
                          ),
                          const Spacer(),
                          SvgPicture.asset(
                            'assets/kdn/usm/img/chevron-right_type1.svg',
                            height: getSize24().toDouble(),
                            width: getSize24().toDouble(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 키보드가 올라와도 충분한 여백 확보
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + getSize50().toDouble()),
            ],
          ),
        ),
      ),
    );
  }
}