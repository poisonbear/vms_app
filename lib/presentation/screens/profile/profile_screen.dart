import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
            right: getSize20(),
            left: getSize20(),
            bottom: getSize20(),
          ),
          child: Column(
            children: [
              // 프로필 이미지와 이름 (세로 배치로 변경)
              Padding(
                padding: EdgeInsets.only(top: getSize40()),
                child: Column(
                  children: [
                    // 프로필 이미지
                    Center(
                      child: SizedBox(
                        width: getSize96(),
                        height: getSize96(),
                        child: SvgPicture.asset(
                          'assets/kdn/usm/img/defult_img.svg',
                          height: getSize96(),
                          width: getSize96(),
                        ),
                      ),
                    ),
                    // 이름과 환영 메시지 (세로 배치)
                    Padding(
                      padding: EdgeInsets.only(top: getSize6()),
                      child: Column(
                        children: [
                          TextWidgetString(
                              '${widget.username}님',
                              getTextcenter(),
                              getSizeInt20(),
                              getText700(),
                              getColorBlackType2()),
                          SizedBox(height: getSize8()),
                          TextWidgetString(
                              '반갑습니다.',
                              getTextcenter(),
                              getSizeInt12(),
                              getText700(),
                              getColorGrayType3()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 프로필과 로그인/회원정보 섹션 사이 간격 추가
              SizedBox(height: getSize20()),

              Padding(
                padding: EdgeInsets.only(
                    top: getSize20(),
                    bottom: getSize20()),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextWidgetString(
                    '로그인/회원정보',
                    getTextleft(),
                    getSizeInt20(),
                    getText700(),
                    getColorBlackType2(),
                  ),
                ),
              ),

              Container(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: getSize12(),
                      left: getSize12(),
                      bottom: getSize8(),
                      top: getSize8()),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        TextWidgetString(
                          '로그인 정보',
                          getTextleft(),
                          getSizeInt16(),
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
                            getSizeInt16(),
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
                thickness: getSize1(),
                height: getSize12(),
                indent: 0,
                endIndent: 0,
                color: getColorGrayType10(),
              ),

              Padding(
                padding: EdgeInsets.only(
                    right: getSize12(),
                    left: getSize12()),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(children: [
                      TextWidgetString('자동 로그인',
                          getTextleft(),
                          getSizeInt16(),
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
                          duration: AppDurations.milliseconds200,
                          width: getSize70(),
                          height: getSize36(),
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
                                duration: AppDurations.milliseconds200 ,
                                curve: Curves.easeInOut,
                                left: _isSwitched ? getSize30() : getSize0(),
                                right: _isSwitched ? getSize0() : getSize30(),
                                top: getSize4(),
                                bottom: getSize4(),
                                child: Container(
                                  width: getSize30(),
                                  height: getSize30(),
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
                thickness: getSize1(),
                height: getSize12(),
                indent: 0,
                endIndent: 0,
                color: getColorGrayType10(),
              ),

              Container(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: getSize12(),
                      left: getSize12(),
                      bottom: getSize8(),
                      top: getSize8()),
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
                            getSizeInt16(),
                            getText700(),
                            getColorGrayType3(),
                          ),
                          const Spacer(),
                          SvgPicture.asset(
                            'assets/kdn/usm/img/chevron-right_type1.svg',
                            height: getSize24(),
                            width: getSize24(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 키보드가 올라와도 충분한 여백 확보
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + getSize50()),
            ],
          ),
        ),
      ),
    );
  }
}