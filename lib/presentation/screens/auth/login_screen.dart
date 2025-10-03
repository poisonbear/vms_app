import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/screens/auth/terms_agreement_screen.dart';  // CmdChoiceView import
import 'package:vms_app/presentation/screens/main/main_screen.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
  });

  @override
  State<LoginView> createState() => _CmdViewState();
}

class _CmdViewState extends State<LoginView> {
  final TextEditingController idController = TextEditingController(); // 아이디 입력값
  final TextEditingController passwordController = TextEditingController(); // 비밀번호 입력값
  final String apiUrl = dotenv.env['kdn_loginForm_key'] ?? ''; // 로그인  url
  final String apiUrl2 = dotenv.env['kdn_usm_select_role_data_key'] ?? ''; // 사용자 역할 권한  url
  bool auto_login = false; // 자동 로그인
  bool save_id = false; // ID 저장 체크박스 상태
  late FirebaseMessaging messaging;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  late String fcmToken; //FCM 토큰 저장 변수 추가

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;
    initFcmToken(); // FCM 토큰 초기화 함수 호출
    loadSavedId(); // 저장된 ID 불러오기
  }

  // FCM 토큰 초기화 함수
  Future<void> initFcmToken() async {
    try {
      fcmToken = await messaging.getToken() ?? '';
    } catch (e) {
      fcmToken = ''; // 오류 발생시 빈 문자열로 초기화
    }
  }

  // 저장된 ID 불러오기
  Future<void> loadSavedId() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? savedIdFlag = prefs.getBool('save_id_flag');
      final String? savedId = prefs.getString('saved_user_id');

      if (savedIdFlag == true && savedId != null) {
        setState(() {
          save_id = true;
          // @kdn.vms.com 제거하고 ID만 표시
          idController.text = savedId.replaceAll('@kdn.vms.com', '');
        });
        AppLogger.d('저장된 ID 불러오기 성공: ${idController.text}');
      }
    } catch (e) {
      AppLogger.e('저장된 ID 불러오기 실패: $e');
    }
  }

  // ID 저장 처리
  Future<void> saveUserId(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      if (save_id) {
        // ID 저장 체크박스가 체크되어 있으면 저장
        await prefs.setBool('save_id_flag', true);
        await prefs.setString('saved_user_id', userId);
        AppLogger.d('ID 저장 완료: $userId');
      } else {
        // 체크 해제되어 있으면 삭제
        await prefs.remove('save_id_flag');
        await prefs.remove('saved_user_id');
        AppLogger.d('저장된 ID 삭제 완료');
      }
    } catch (e) {
      AppLogger.e('ID 저장 처리 실패: $e');
    }
  }

  Future<void> submitForm() async {
    final id = '${idController.text.trim()}@kdn.vms.com'; // 아이디
    final password = passwordController.text.trim(); // 비밀번호

    // 유효성 검사
    if (idController.text.trim().isEmpty || password.isEmpty) {
      showTopSnackBar(context, '아이디 비밀번호를 입력해주세요.');
      return;
    }

    try {
      // 토큰 생성
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: id, password: password);

      // ✅ Firebase JWT 토큰 가져오기
      String? firebaseToken = await userCredential.user?.getIdToken();
      String? uuid = userCredential.user?.uid;

      if (firebaseToken == null) {
        showTopSnackBar(context, 'Firebase 토큰을 가져올 수 없습니다.');
        return;
      }

      String? token = firebaseToken;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('firebase_token', token); // firebase 토큰 디바이스에 저장

      //✅ 서버에 JWT 토큰과 함께 로그인 요청
      Response response = await Dio().post(
        apiUrl,
        data: {
          'user_id': id, // 아이디
          'user_pwd': password, // 비밀번호
          'auto_login': auto_login, // 자동 로그인 false값
          'fcm_tkn': fcmToken, // fcm 토큰
          'uuid': uuid // uuid
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $firebaseToken', // 서버에 JWT 토큰 전달
          },
        ),
      );

      AppLogger.i('=== 로그인 응답 디버깅 시작 ===');
      AppLogger.d('➡️ 로그인 요청 API URL: $apiUrl');
      AppLogger.d('✅ Firebase JWT 토큰: $firebaseToken');
      AppLogger.d('✅ Authorization 헤더: Bearer $firebaseToken');
      AppLogger.d('Response data: ${response.data}');
      AppLogger.d('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 요청 성공
        String username = response.data['username'];
        await prefs.setString('username', username); //username을 디바이스에 저장

        // UUID 저장 코드 추가
        if (response.data.containsKey('uuid')) {
          String uuid = response.data['uuid'];
          await prefs.setString('uuid', uuid);
        }

        // ID 저장 처리
        await saveUserId(id);

        //로그인 이후, 자동로그인 값 true로 설정
        auto_login = true;
        await prefs.setBool('auto_login', auto_login); //자동로그인을 디바이스에 저장

        // 자동 로그인용 비밀번호 저장 (자동 로그인 체크 시에만)
        if (auto_login) {
          await prefs.setString('saved_id', id);
          await prefs.setString('saved_pw', password);
        }

        //[1] 역할(role) 요청 API 호출
        Response roleResponse = await Dio().post(
          apiUrl2,
          data: {'user_id': username},
        );

        if (roleResponse.statusCode == 200) {
          AppLogger.d('Role response: ${roleResponse.data}');
          String role = roleResponse.data['role'];
          int? mmsi = roleResponse.data['mmsi'];

          //[2] Provider에 역할 저장
          context.read<UserState>().setRole(role); // 디바이스에 역할 상태 저장

          // MMSI 저장 또는 복구
          if (mmsi != null && mmsi != 0) {
            context.read<UserState>().setMmsi(mmsi);
          } else {
            // MMSI가 없으면 Firestore에서 조회 시도
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

                if (doc.exists) {
                  final firestoreMmsi = doc.data()?['mmsi'];
                  if (firestoreMmsi != null && mounted) {
                    context.read<UserState>().setMmsi(firestoreMmsi);
                    AppLogger.d('Firestore에서 MMSI 복구: $firestoreMmsi');
                  }
                }
              }
            } catch (e) {
              AppLogger.e('Firestore MMSI 조회 실패: $e');
            }
          }
        }

        // ✅ MainScreen으로 이동 - 올바른 생성자 호출
        if (!mounted) return;

        AppLogger.d('========================================');
        AppLogger.d('🚀 로그인 성공! MainScreen으로 이동');
        AppLogger.d('👤 username: $username');
        AppLogger.d('✅ autoFocusLocation: true 설정');
        AppLogger.d('========================================');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(
                username: username,
                autoFocusLocation: true,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인 실패: ${response.data['message'] ?? '잘못된 아이디 또는 비밀번호'}')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        if (e.message?.contains('password') ?? false) {
          showTopSnackBar(context, '비밀번호를 확인해주세요.');
        } else if (e.message?.contains('email') ?? false) {
          showTopSnackBar(context, '아이디를 확인해주세요.');
        } else {
          showTopSnackBar(context, '아이디 또는 비밀번호를 확인해주세요.');
        }
      } else {
        showTopSnackBar(context, '로그인 중 오류가 발생했습니다: ${e.message}');
      }
    } catch (e) {
      AppLogger.e('로그인 오류: $e');
      showTopSnackBar(context, '로그인 중 오류가 발생했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 키보드 높이 감지
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 반드시 false
      body: Stack(
        children: [
          // 1. 배경 이미지를 SizedBox로 고정 크기 설정
          SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: const RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/kdn/usm/img/blue_sky2.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.center, // 중앙 고정
                  ),
                ),
              ),
            ),
          ),

          // 2. 로그인 콘텐츠
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus(); // 키보드 닫기
            },
            child: Center(
              child: SingleChildScrollView(
                // 키보드가 올라올 때만 스크롤
                padding: EdgeInsets.only(
                  bottom: keyboardHeight, // 키보드 높이만큼 패딩
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.25,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 흐림 효과
                          child: Container(
                            width: AppSizes.s330,
                            height: AppSizes.s550,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.5),
                                  Colors.white.withValues(alpha: 0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        // SVG 로고 제거하고 텍스트만 표시
                        Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: TextWidgetString('K-VMS', TextAligns.center,
                              AppSizes.i50, FontWeights.bold, AppColors.blackType1),
                        ),
                        // 아이디 입력
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(DesignConstants.radiusS),
                            ),
                            child: inputWidget(
                                AppSizes.i266, AppSizes.i48, idController, '아이디 입력', AppColors.grayType7),
                          ),
                        ),
                        // 비밀번호 입력
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(DesignConstants.radiusS),
                            ),
                            child: inputWidget(AppSizes.i266, AppSizes.i48, passwordController, '비밀번호 입력',
                                AppColors.grayType7,
                                obscureText: true),
                          ),
                        ),

                        // ID 저장 체크박스 추가
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: AppSizes.s266,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: save_id,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        save_id = value ?? false;
                                      });
                                    },
                                    activeColor: AppColors.skyType2,
                                    checkColor: Colors.white,
                                    side: BorderSide(
                                      color: save_id ? AppColors.skyType2 : AppColors.grayType2,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      save_id = !save_id;
                                    });
                                  },
                                  child: TextWidgetString(
                                    '아이디 저장',
                                    TextAligns.left,
                                    AppSizes.i14,
                                    FontWeights.w400,
                                    AppColors.grayType1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 로그인 버튼
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: GestureDetector(
                            onTap: () async {
                              await submitForm();
                            },
                            child: Container(
                              width: AppSizes.s266,
                              height: AppSizes.s48,
                              decoration: BoxDecoration(
                                color: AppColors.mainType1,
                                borderRadius: BorderRadius.circular(DesignConstants.radiusS),
                              ),
                              child: Center(
                                child: TextWidgetString('로그인', TextAligns.center, AppSizes.i16, FontWeights.w700,
                                    AppColors.whiteType1),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) {
                                  return const CmdChoiceView();  // 수정: CmdChoiceView 사용
                                },
                              ),
                            );
                          },
                          child: Container(
                            width: AppSizes.s266,
                            height: AppSizes.s48,
                            decoration: BoxDecoration(
                              color: AppColors.grayType2,
                              borderRadius: BorderRadius.circular(DesignConstants.radiusS),
                            ),
                            child: Center(
                              child: TextWidgetString('회원가입', TextAligns.center, AppSizes.i16, FontWeights.w700,
                                  AppColors.whiteType1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 하단 로고 (고정 위치) - 원본 코드 복구
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '시스템 문의 : 061-930-4567',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: DesignConstants.fontSizeXS,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignConstants.spacing8),
                SvgPicture.asset(
                  'assets/kdn/usm/img/login_footer_logo.svg',
                  height: 20.0,
                  width: 150.0,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}