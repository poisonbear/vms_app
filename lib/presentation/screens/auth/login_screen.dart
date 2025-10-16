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
import 'package:vms_app/core/infrastructure/network_client.dart'; // ✅ 추가
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/screens/auth/terms_agreement_screen.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

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
  final _dioRequest = DioRequest();

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

  Future<void> initFcmToken() async {
    try {
      fcmToken = await messaging.getToken() ?? '';
    } catch (e) {
      fcmToken = '';
    }
  }

  Future<void> loadSavedId() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? savedIdFlag = prefs.getBool('save_id_flag');
      final String? savedId = prefs.getString('saved_user_id');

      if (savedIdFlag == true && savedId != null) {
        setState(() {
          save_id = true;
          idController.text = savedId.replaceAll('@kdn.vms.com', '');
        });
        AppLogger.d('저장된 ID 불러오기 성공');
      }
    } catch (e) {
      AppLogger.e('저장된 ID 불러오기 실패', e);
    }
  }

  Future<void> saveUserId(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      if (save_id) {
        await prefs.setBool('save_id_flag', true);
        await prefs.setString('saved_user_id', userId);
        AppLogger.d('ID 저장 완료');
      } else {
        await prefs.remove('save_id_flag');
        await prefs.remove('saved_user_id');
        AppLogger.d('저장된 ID 삭제 완료');
      }
    } catch (e) {
      AppLogger.e('ID 저장 처리 실패', e);
    }
  }

  Future<void> submitForm() async {
    final id = '${idController.text.trim()}@kdn.vms.com';
    final password = passwordController.text.trim();

    if (idController.text.trim().isEmpty || password.isEmpty) {
      showTopSnackBar(context, '아이디 비밀번호를 입력해주세요.');
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: id, password: password);

      String? firebaseToken = await userCredential.user?.getIdToken();
      String? uuid = userCredential.user?.uid;

      if (firebaseToken == null) {
        showTopSnackBar(context, 'Firebase 토큰을 가져올 수 없습니다.');
        return;
      }

      await _secureStorage.saveSessionData(
        firebaseToken: firebaseToken,
        uuid: uuid ?? '',
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();

      AppLogger.i('로그인 API 호출 시작');
      AppLogger.d('API URL: $apiUrl');

      Response response = await _dioRequest.dio.post(
        // ✅ 수정
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

      AppLogger.d('로그인 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        String username = response.data['username'];
        await prefs.setString('username', username);

        await saveUserId(id);

        auto_login = true;
        await prefs.setBool('auto_login', auto_login);

        if (auto_login) {
          await _secureStorage.saveCredentials(
            id: id,
            password: password,
          );
          AppLogger.i('로그인 정보가 안전하게 저장되었습니다');
        }

        Response roleResponse = await _dioRequest.dio.post(
          // ✅ 수정
          apiUrl2,
          data: {'user_id': username},
        );

        if (roleResponse.statusCode == 200) {
          AppLogger.d('사용자 역할 정보 조회 성공');
          String role = roleResponse.data['role'];
          int? mmsi = roleResponse.data['mmsi'];

          context.read<UserState>().setRole(role);

          if (mmsi != null && mmsi != 0) {
            context.read<UserState>().setMmsi(mmsi);
          } else {
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final doc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                if (doc.exists) {
                  final firestoreMmsi = doc.data()?['mmsi'] as int?;
                  if (firestoreMmsi != null && firestoreMmsi != 0) {
                    context.read<UserState>().setMmsi(firestoreMmsi);
                    AppLogger.d('Firestore에서 MMSI 복구: $firestoreMmsi');
                  }
                }
              }
            } catch (e) {
              AppLogger.e('Firestore MMSI 조회 실패', e);
            }
          }

          await updateFirebaseToken(username);

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => MainScreen(username: username),
              ),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          showTopSnackBar(context, '사용자 역할 정보를 불러오지 못했습니다.');
        }
      } else {
        showTopSnackBar(context, '로그인에 실패했습니다.');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = '등록되지 않은 사용자입니다.';
          break;
        case 'wrong-password':
          errorMessage = '비밀번호가 올바르지 않습니다.';
          break;
        case 'invalid-email':
          errorMessage = '이메일 형식이 올바르지 않습니다.';
          break;
        case 'user-disabled':
          errorMessage = '비활성화된 계정입니다.';
          break;
        case 'too-many-requests':
          errorMessage = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
          break;
        default:
          errorMessage = '로그인 중 오류가 발생했습니다: ${e.code}';
      }
      showTopSnackBar(context, errorMessage);
      AppLogger.e('Firebase Auth Error: ${e.code}', e);
    } catch (e) {
      showTopSnackBar(context, '로그인 중 오류가 발생했습니다.');
      AppLogger.e('Login Error', e);
    }
  }

  Future<void> updateFirebaseToken(String username) async {
    try {
      if (fcmToken.isEmpty) {
        AppLogger.w('FCM 토큰이 비어있어 업데이트를 건너뜁니다.');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.w('현재 사용자가 없어 FCM 토큰 업데이트를 건너뜁니다.');
        return;
      }

      await FirebaseFirestore.instance
          .collection('firebase_App')
          .doc('userToken')
          .set({
        username: fcmToken,
      }, SetOptions(merge: true));

      AppLogger.d('FCM 토큰이 Firestore에 업데이트되었습니다.');
    } catch (e) {
      AppLogger.e('FCM 토큰 업데이트 실패', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kdn/background_img.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Blur 효과
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // 로그인 폼
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                      borderRadius:
                          BorderRadius.circular(DesignConstants.radiusS),
                    ),
                    child: inputWidget(
                      AppSizes.s266,
                      AppSizes.s48,
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
                      borderRadius:
                          BorderRadius.circular(DesignConstants.radiusS),
                    ),
                    child: inputWidget(
                      AppSizes.s266,
                      AppSizes.s48,
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
                                  : AppColors.grayType3,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ID 저장',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.blackType2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 로그인 버튼
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: AppSizes.s266,
                    height: AppSizes.s48,
                    child: ElevatedButton(
                      onPressed: submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.skyType2,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignConstants.radiusS),
                        ),
                      ),
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // 회원가입 버튼
                SizedBox(
                  width: AppSizes.s266,
                  height: AppSizes.s48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CmdChoiceView(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.skyType2,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignConstants.radiusS),
                      ),
                    ),
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.skyType2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 하단 로고
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

  Widget inputWidget(
    double width,
    double height,
    TextEditingController controller,
    String hintText,
    Color hintColor, {
    bool obscureText = false,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.blackType2,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            color: hintColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
