import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  // Rate Limiting
  int _loginAttempts = 0;
  DateTime? _lastAttemptTime;
  bool _isProcessing = false;

  @override
  void dispose() {
    idController.clear();
    passwordController.clear();
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

  bool _checkRateLimit() {
    if (_loginAttempts >= 5) {
      final now = DateTime.now();
      if (_lastAttemptTime != null &&
          now.difference(_lastAttemptTime!).inMinutes < 5) {
        return false;
      } else {
        _loginAttempts = 0;
      }
    }
    return true;
  }

  String? _validateInput(String id, String password) {
    if (id.isEmpty || password.isEmpty) {
      return ErrorMessages.idPasswordRequired;
    }

    if (id.length < ValidationRules.idMinLength ||
        id.length > ValidationRules.idMaxLength) {
      return '아이디는 ${ValidationRules.idMinLength}-${ValidationRules.idMaxLength}자여야 합니다.';
    }

    if (!ValidationRules.idRegExp.hasMatch(id)) {
      return '아이디는 영문, 숫자만 사용 가능합니다.';
    }

    if (password.length < ValidationRules.passwordMinLength ||
        password.length > ValidationRules.passwordMaxLength) {
      return '비밀번호는 ${ValidationRules.passwordMinLength}-${ValidationRules.passwordMaxLength}자여야 합니다.';
    }

    return null;
  }

  String _maskSensitiveData(String data) {
    if (data.length <= 10) return '***';
    return '${data.substring(0, 5)}...${data.substring(data.length - 5)}';
  }

  Future<void> submitForm() async {
    if (_isProcessing) return;

    final idInput = idController.text.trim();
    final password = passwordController.text.trim();

    if (!_checkRateLimit()) {
      showTopSnackBar(context, '로그인 시도 횟수를 초과했습니다. 5분 후 다시 시도해주세요.');
      return;
    }

    final validationError = _validateInput(idInput, password);
    if (validationError != null) {
      showTopSnackBar(context, validationError);
      return;
    }

    setState(() => _isProcessing = true);

    _lastAttemptTime = DateTime.now();
    _loginAttempts++;

    final id = '$idInput@kdn.vms.com';

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: id, password: password);

      String? firebaseToken = await userCredential.user?.getIdToken();
      String? uuid = userCredential.user?.uid;

      if (firebaseToken == null) {
        showTopSnackBar(context, ErrorMessages.firebaseTokenMissing);
        return;
      }

      await _secureStorage.saveSessionData(
        firebaseToken: firebaseToken,
        uuid: uuid ?? '',
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();

      AppLogger.i('로그인 API 호출 시작');
      if (kDebugMode) {
        AppLogger.d('토큰 길이: ${firebaseToken.length}');
        AppLogger.d('UUID: ${_maskSensitiveData(uuid ?? '')}');
      }

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
          headers: {'Authorization': 'Bearer $firebaseToken'},
        ),
      );

      AppLogger.d('로그인 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        _loginAttempts = 0;
        _lastAttemptTime = null;

        String username = response.data['username'];
        await prefs.setString('username', username);
        await saveUserId(id);

        // ✅ 자동 로그인 설정 (사용자가 체크했을 때만)
        await prefs.setBool('auto_login', auto_login);

        // ✅ 자동 로그인을 위한 자격증명 저장 (SecureStorage 사용)
        if (auto_login) {
          await _secureStorage.saveCredentials(
            id: id,
            password: password,
          );
          AppLogger.i('자동 로그인 정보가 안전하게 저장되었습니다');
        } else {
          // 자동 로그인 해제 시 자격증명 삭제
          await _secureStorage.deleteCredentials();
          AppLogger.i('자동 로그인 정보가 삭제되었습니다');
        }

        Response roleResponse = await Dio().post(
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
                    AppLogger.d('Firestore에서 MMSI 복구');
                  }
                }
              }
            } catch (e) {
              AppLogger.e('Firestore MMSI 조회 실패', e);
            }
          }

          await updateFirebaseToken(username);

          // ✅ autoFocusLocation 파라미터 추가
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => MainScreen(
                  username: username,
                  autoFocusLocation: true, // ✅ 오토포커싱 활성화
                ),
              ),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          showTopSnackBar(context, ErrorMessages.roleInfoLoadFailed);
        }
      } else {
        showTopSnackBar(context, ErrorMessages.loginFailed);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = ErrorMessages.userNotFound;
          break;
        case 'wrong-password':
          errorMessage = ErrorMessages.wrongPassword;
          break;
        case 'invalid-email':
          errorMessage = ErrorMessages.invalidEmail;
          break;
        case 'user-disabled':
          errorMessage = ErrorMessages.userDisabled;
          break;
        case 'too-many-requests':
          errorMessage = ErrorMessages.tooManyRequestsAuth;
          break;
        case 'invalid-credential':
          errorMessage = '아이디 또는 비밀번호를 확인해주세요.';
          break;
        default:
          errorMessage = ErrorMessages.loginError;
          AppLogger.e('Firebase Auth Error: ${e.code}', e);
      }
      showTopSnackBar(context, errorMessage);
    } catch (e) {
      showTopSnackBar(context, ErrorMessages.loginError);
      AppLogger.e('Login Error', e);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
                image: AssetImage('assets/kdn/usm/img/blue_sky2.png'),
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

                // ID 저장 & 자동 로그인 체크박스
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: AppSizes.s266,
                    child: Column(
                      children: [
                        // ID 저장
                        Row(
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
                            const SizedBox(width: 20),
                            // 자동 로그인
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: auto_login,
                                onChanged: (bool? value) {
                                  setState(() {
                                    auto_login = value ?? false;
                                  });
                                },
                                activeColor: AppColors.skyType2,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: auto_login
                                      ? AppColors.skyType2
                                      : AppColors.grayType3,
                                  width: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '자동 로그인',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.blackType2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 로그인 & 회원가입 버튼
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 로그인 버튼
                      SizedBox(
                        width: 127,
                        height: AppSizes.s48,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.skyType2,
                            disabledBackgroundColor:
                                AppColors.skyType2.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignConstants.radiusS),
                            ),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  '로그인',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 회원가입 버튼
                      SizedBox(
                        width: 127,
                        height: AppSizes.s48,
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CmdChoiceView(),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.grayType3,
                            disabledBackgroundColor:
                                AppColors.grayType3.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignConstants.radiusS),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
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
        enabled: !_isProcessing,
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
