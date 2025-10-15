// lib/presentation/screens/auth/login_screen.dart

import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/screens/auth/terms_agreement_screen.dart';
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
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final String apiUrl = ApiConfig.authLogin;
  final String apiUrl2 = ApiConfig.authRole;
  bool auto_login = false;
  bool save_id = false;
  late FirebaseMessaging messaging;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  late String fcmToken;
  final _secureStorage = SecureStorageService();

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
    initFcmToken();
    loadSavedId();
  }

  /// FCM 토큰 초기화 함수
  Future<void> initFcmToken() async {
    try {
      fcmToken = await messaging.getToken() ?? '';
    } catch (e) {
      fcmToken = '';
    }
  }

  /// 저장된 ID 불러오기
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
        AppLogger.d('저장된 ID 불러오기 성공');
      }
    } catch (e) {
      AppLogger.e('저장된 ID 불러오기 실패', e);
    }
  }

  /// ID 저장 처리
  Future<void> saveUserId(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      if (save_id) {
        // ID 저장 체크박스가 체크되어 있으면 저장
        await prefs.setBool('save_id_flag', true);
        await prefs.setString('saved_user_id', userId);
        AppLogger.d('ID 저장 완료');
      } else {
        // 체크 해제되어 있으면 삭제
        await prefs.remove('save_id_flag');
        await prefs.remove('saved_user_id');
        AppLogger.d('저장된 ID 삭제 완료');
      }
    } catch (e) {
      AppLogger.e('ID 저장 처리 실패', e);
    }
  }

  /// 로그인 처리
  Future<void> submitForm() async {
    final id = '${idController.text.trim()}@kdn.vms.com';
    final password = passwordController.text.trim();

    // 유효성 검사
    if (idController.text.trim().isEmpty || password.isEmpty) {
      showTopSnackBar(context, '아이디 비밀번호를 입력해주세요.');
      return;
    }

    try {
      // Firebase 인증
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: id, password: password);

      String? firebaseToken = await userCredential.user?.getIdToken();
      String? uuid = userCredential.user?.uid;

      if (firebaseToken == null) {
        showTopSnackBar(context, 'Firebase 토큰을 가져올 수 없습니다.');
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('firebase_token', firebaseToken);

      // ✅ 민감 정보 로그 개선: 실제 값 출력 안함
      AppLogger.i('로그인 API 호출 시작');
      AppLogger.d('API URL: $apiUrl');

      // 서버 로그인 요청
      Response response = await Dio().post(
        apiUrl,
        data: {
          'user_id': id,
          'user_pwd': password,
          'auto_login': auto_login,
          'fcm_tkn': fcmToken,
          'uuid': uuid
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $firebaseToken',
          },
        ),
      );

      // ✅ 민감 정보 로그 제거
      AppLogger.d('로그인 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        String username = response.data['username'];
        await prefs.setString('username', username);

        // UUID 저장
        if (response.data.containsKey('uuid')) {
          String uuid = response.data['uuid'];
          await prefs.setString('uuid', uuid);
        }

        // ID 저장 처리
        await saveUserId(id);

        // 자동 로그인 설정
        auto_login = true;
        await prefs.setBool('auto_login', auto_login);

        // ✅ 수정: 비밀번호를 SecureStorage에 저장
        if (auto_login) {
          await _secureStorage.saveCredentials(
            id: id,
            password: password,
          );
          AppLogger.i('로그인 정보가 안전하게 저장되었습니다');
        }

        // 역할 정보 조회
        Response roleResponse = await Dio().post(
          apiUrl2,
          data: {'user_id': username},
        );

        if (roleResponse.statusCode == 200) {
          AppLogger.d('사용자 역할 정보 조회 성공');
          String role = roleResponse.data['role'];
          int? mmsi = roleResponse.data['mmsi'];

          // Provider에 역할 저장
          context.read<UserState>().setRole(role);

          // MMSI 저장 또는 복구
          if (mmsi != null && mmsi != 0) {
            context.read<UserState>().setMmsi(mmsi);
          } else {
            // MMSI가 없으면 Firestore에서 조회 시도
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final doc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                if (doc.exists) {
                  final firestoreMmsi = doc.data()?['mmsi'];
                  if (firestoreMmsi != null && mounted) {
                    context.read<UserState>().setMmsi(firestoreMmsi);
                    AppLogger.d('Firestore에서 MMSI 복구 성공');
                  }
                }
              }
            } catch (e) {
              AppLogger.e('Firestore MMSI 조회 실패', e);
            }
          }
        }

        // MainScreen으로 이동
        if (!mounted) return;

        AppLogger.i('로그인 성공 - MainScreen으로 이동');

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
            SnackBar(
              content: Text(
                  '로그인 실패: ${response.data['message'] ?? '잘못된 아이디 또는 비밀번호'}'
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // ✅ 민감 정보 로그 제거: 에러 코드만 기록
      AppLogger.w('Firebase 인증 실패: ${e.code}');

      if (e.code == 'invalid-credential') {
        if (e.message?.contains('password') ?? false) {
          showTopSnackBar(context, '비밀번호를 확인해주세요.');
        } else if (e.message?.contains('email') ?? false) {
          showTopSnackBar(context, '아이디를 확인해주세요.');
        } else {
          showTopSnackBar(context, '아이디 또는 비밀번호를 확인해주세요.');
        }
      } else {
        showTopSnackBar(context, '로그인 중 오류가 발생했습니다.');
      }
    } catch (e) {
      AppLogger.e('로그인 오류', e);
      showTopSnackBar(context, '로그인 중 오류가 발생했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. 배경 이미지
          SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: const RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/kdn/usm/img/blue_sky2.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          ),

          // 2. 로그인 콘텐츠
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: keyboardHeight,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.25,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                        // 로고
                        Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: TextWidgetString(
                            'K-VMS',
                            TextAligns.center,
                            AppSizes.i50,
                            FontWeights.bold,
                            AppColors.blackType1,
                          ),
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
                              AppSizes.i266,
                              AppSizes.i48,
                              idController,
                              '아이디 입력',
                              AppColors.grayType7,
                            ),
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
                            child: inputWidget(
                              AppSizes.i266,
                              AppSizes.i48,
                              passwordController,
                              '비밀번호 입력',
                              AppColors.grayType7,
                              obscureText: true,
                            ),
                          ),
                        ),

                        // ID 저장 체크박스
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
                                      color: save_id
                                          ? AppColors.skyType2
                                          : AppColors.grayType2,
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
                                child: TextWidgetString(
                                  '로그인',
                                  TextAligns.center,
                                  AppSizes.i16,
                                  FontWeights.w700,
                                  AppColors.whiteType1,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 회원가입 버튼
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) {
                                  return const CmdChoiceView();
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
                              child: TextWidgetString(
                                '회원가입',
                                TextAligns.center,
                                AppSizes.i16,
                                FontWeights.w700,
                                AppColors.whiteType1,
                              ),
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

          // 3. 하단 로고 (고정 위치)
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
                const SizedBox(height: AppSizes.spacing8),
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