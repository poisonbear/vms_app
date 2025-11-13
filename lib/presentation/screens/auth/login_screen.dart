// lib/presentation/screens/auth/login_screen.dart

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
  // ========================================
  // Controllers
  // ========================================
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ========================================
  // Constants
  // ========================================
  final String apiUrl = ApiConfig.authLogin;
  final String apiUrl2 = ApiConfig.authRole;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _secureStorage = SecureStorageService();

  late final FirebaseMessaging messaging;
  String? fcmToken;

  // ========================================
  // State Variables
  // ========================================
  bool auto_login = false;
  bool save_id = false;
  bool _isPasswordVisible = false;

  // Rate Limiting
  int _loginAttempts = 0;
  DateTime? _lastAttemptTime;
  bool _isProcessing = false;

  // ========================================
  // Lifecycle Methods
  // ========================================

  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await Future.wait([
      initFcmToken(),
      loadSavedId(),
    ]);
  }

  @override
  void dispose() {
    idController.clear();
    passwordController.clear();
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ========================================
  // FCM 토큰 초기화
  // ========================================

  Future<void> initFcmToken() async {
    try {
      fcmToken = await messaging.getToken();

      if (fcmToken != null && fcmToken!.isNotEmpty) {
        final preview =
            fcmToken!.length > 20 ? fcmToken!.substring(0, 20) : fcmToken!;
        AppLogger.d('FCM 토큰 초기화 성공: $preview...');
      } else {
        AppLogger.w('FCM 토큰이 null이거나 비어있습니다.');
      }
    } catch (e) {
      AppLogger.e('FCM 토큰 초기화 실패', e);
      fcmToken = null;
    }
  }

  // ========================================
  // ID 저장/불러오기
  // ========================================

  Future<void> loadSavedId() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? savedIdFlag = prefs.getBool('save_id_flag');
      final String? savedId = prefs.getString('saved_user_id');

      if (savedIdFlag == true && savedId != null) {
        if (mounted) {
          setState(() {
            save_id = true;
            idController.text =
                savedId.replaceAll(StringConstants.emailDomain, '');
          });
        }
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

  // ========================================
  // Validation Methods
  // ========================================

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

  // ========================================
  // 로그인 처리
  // ========================================

  Future<void> submitForm() async {
    if (_isProcessing) return;

    final idInput = idController.text.trim();
    final password = passwordController.text.trim();

    // Rate limit 체크
    if (!_checkRateLimit()) {
      showTopSnackBar(context, '로그인 시도 횟수를 초과했습니다. 5분 후 다시 시도해주세요.');
      return;
    }

    // 입력값 검증
    final validationError = _validateInput(idInput, password);
    if (validationError != null) {
      showTopSnackBar(context, validationError);
      return;
    }

    setState(() => _isProcessing = true);

    _lastAttemptTime = DateTime.now();
    _loginAttempts++;

    final id = '$idInput${StringConstants.emailDomain}';

    try {
      // Firebase 로그인
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: id, password: password);

      String? firebaseToken = await userCredential.user?.getIdToken();
      String? uuid = userCredential.user?.uid;

      if (firebaseToken == null) {
        if (!mounted) {
          setState(() => _isProcessing = false);
          return;
        }
        showTopSnackBar(context, ErrorMessages.firebaseTokenMissing);
        return;
      }

      // 세션 데이터 저장
      await _secureStorage.saveSessionData(
        firebaseToken: firebaseToken,
        uuid: uuid ?? '',
      );

      if (!mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();

      AppLogger.i('로그인 API 호출 시작');
      if (kDebugMode) {
        AppLogger.d('토큰 길이: ${firebaseToken.length}');
        AppLogger.d('UUID: ${_maskSensitiveData(uuid ?? '')}');
      }

      // 로그인 API 호출
      Response response = await Dio().post(
        apiUrl,
        data: {
          'user_id': id,
          'user_pwd': password,
          'auto_login': auto_login,
          'fcm_tkn': fcmToken ?? '',
          'uuid': uuid
        },
        options: Options(
          headers: {'Authorization': 'Bearer $firebaseToken'},
        ),
      );

      AppLogger.d('로그인 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 로그인 성공
        _loginAttempts = 0;
        _lastAttemptTime = null;

        String username;

        if (response.data is String && response.data.isEmpty) {
          username = idInput;
          AppLogger.w('백엔드 응답이 비어있습니다. 입력 ID 사용: $username');
        } else if (response.data is Map && response.data['username'] != null) {
          username = response.data['username'];
          AppLogger.d('백엔드에서 username 수신: $username');
        } else {
          username = idInput;
          AppLogger.w('username을 찾을 수 없어 입력 ID 사용: $username');
        }

        await prefs.setString('username', username);
        await saveUserId(id);

        // 자동 로그인 설정
        await prefs.setBool('auto_login', auto_login);

        if (auto_login) {
          await _secureStorage.saveCredentials(
            id: id,
            password: password,
          );
          AppLogger.i('자동 로그인 정보가 안전하게 저장되었습니다');
        } else {
          await _secureStorage.deleteCredentials();
          AppLogger.i('자동 로그인 정보가 삭제되었습니다');
        }

        // 역할 정보 조회
        Response roleResponse = await Dio().post(
          apiUrl2,
          data: {'user_id': username},
        );

        if (roleResponse.statusCode == 200) {
          AppLogger.d('사용자 역할 정보 조회 성공');

          String? role;
          int? mmsi;

          if (roleResponse.data is Map && roleResponse.data.isNotEmpty) {
            role = roleResponse.data['role']?.toString();
            mmsi = roleResponse.data['mmsi'] is int
                ? roleResponse.data['mmsi']
                : int.tryParse(roleResponse.data['mmsi']?.toString() ?? '');
            AppLogger.d('역할 정보 (Map): role=$role, mmsi=$mmsi');
          } else if (roleResponse.data is List &&
              roleResponse.data.isNotEmpty) {
            final firstItem = roleResponse.data[0];
            role = firstItem['role']?.toString();
            mmsi = firstItem['mmsi'] is int
                ? firstItem['mmsi']
                : int.tryParse(firstItem['mmsi']?.toString() ?? '');
            AppLogger.d('역할 정보 (List): role=$role, mmsi=$mmsi');
          } else if (roleResponse.data is String && roleResponse.data.isEmpty) {
            AppLogger.w('역할 API 응답이 비어있습니다.');
          }

          if (!mounted) {
            setState(() => _isProcessing = false);
            return;
          }

          if (role != null) {
            context.read<UserState>().setRole(role);
            AppLogger.i('사용자 역할 설정 완료: $role');

            if (mmsi != null && mmsi != 0) {
              context.read<UserState>().setMmsi(mmsi);
              AppLogger.i('MMSI 설정 완료: $mmsi');
            } else {
              // Firestore에서 MMSI 복구 시도
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final doc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  if (doc.exists) {
                    final firestoreMmsi = doc.data()?['mmsi'] as int?;
                    if (firestoreMmsi != null) {
                      if (mounted) {
                        context.read<UserState>().setMmsi(firestoreMmsi);
                        AppLogger.i(' Firestore에서 MMSI 복구 완료: $firestoreMmsi');
                      }
                    }
                  }
                }
              } catch (e) {
                AppLogger.w('Firestore에서 MMSI 복구 실패', e);
              }
            }
          } else {
            AppLogger.w('역할 정보를 찾을 수 없습니다. 기본값으로 진행합니다.');
          }
        } else {
          AppLogger.w('역할 API 응답 상태 코드: ${roleResponse.statusCode}');
        }

        // FCM 토큰 업데이트
        await _updateFcmToken(username);

        if (mounted) {
          AppLogger.i(' 로그인 완료 - 메인 화면으로 이동');
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
        if (!mounted) {
          setState(() => _isProcessing = false);
          return;
        }
        showTopSnackBar(context, ErrorMessages.loginFailed);
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.w('Firebase 인증 실패: ${e.code}');
      String errorMessage = ErrorMessages.loginFailed;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = ErrorMessages.userNotFound;
          break;
        case 'wrong-password':
          errorMessage = ErrorMessages.wrongPassword;
          break;
        case 'invalid-credential':
          errorMessage = '아이디 또는 비밀번호를 확인해주세요.';
          break;
        case 'user-disabled':
          errorMessage = ErrorMessages.userDisabled;
          break;
        case 'too-many-requests':
          errorMessage = ErrorMessages.tooManyRequestsAuth;
          break;
      }

      if (!mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      showTopSnackBar(context, errorMessage);
    } on DioException catch (e) {
      AppLogger.e('로그인 API 오류', e);

      String errorMessage;
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        errorMessage = responseData is Map && responseData['message'] != null
            ? responseData['message']
            : statusCode == 401
                ? '아이디 또는 비밀번호를 확인해주세요.'
                : statusCode == 500
                    ? ErrorMessages.serverError
                    : ErrorMessages.loginFailed;
      } else {
        errorMessage = ErrorMessages.serverConnection;
      }

      if (!mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      showTopSnackBar(context, errorMessage);
    } catch (e) {
      AppLogger.e('예상치 못한 로그인 오류', e);

      if (!mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      showTopSnackBar(context, ErrorMessages.loginError);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ========================================
  // FCM 토큰 Firestore 업데이트
  // ========================================

  Future<void> _updateFcmToken(String username) async {
    try {
      final token = fcmToken;
      if (token == null || token.isEmpty) {
        AppLogger.w('FCM 토큰이 없어 Firestore 업데이트를 건너뜁니다.');
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
        username: token,
      }, SetOptions(merge: true));

      AppLogger.d('FCM 토큰이 Firestore에 업데이트되었습니다.');
    } catch (e) {
      AppLogger.e('FCM 토큰 업데이트 실패', e);
    }
  }

  // ========================================
  // Build Method
  // ========================================

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
              color: Colors.black.withValues(alpha: 0.3),
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
                  padding: const EdgeInsets.only(bottom: AppSizes.s12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(DesignConstants.radiusS),
                    ),
                    child: passwordInputWidget(
                      AppSizes.s266,
                      AppSizes.s48,
                      passwordController,
                      '비밀번호 입력',
                      AppColors.grayType7,
                    ),
                  ),
                ),

                // 자동 로그인 & 아이디 저장 체크박스 (터치 영역 확대)
                SizedBox(
                  width: AppSizes.s266,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSizes.s20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 자동 로그인 체크박스 (터치 영역 확대)
                        InkWell(
                          onTap: _isProcessing
                              ? null
                              : () {
                                  setState(() {
                                    auto_login = !auto_login;
                                  });
                                },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: AppSizes.s20,
                                  height: AppSizes.s20,
                                  child: Checkbox(
                                    value: auto_login,
                                    onChanged: _isProcessing
                                        ? null
                                        : (bool? value) {
                                            setState(() {
                                              auto_login = value ?? false;
                                            });
                                          },
                                    activeColor: AppColors.skyType2,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TextWidgetString(
                                  '자동 로그인',
                                  TextAligns.left,
                                  AppSizes.i12,
                                  FontWeights.w500,
                                  AppColors.blackType2,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 아이디 저장 체크박스 (터치 영역 확대)
                        InkWell(
                          onTap: _isProcessing
                              ? null
                              : () {
                                  setState(() {
                                    save_id = !save_id;
                                  });
                                },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: AppSizes.s20,
                                  height: AppSizes.s20,
                                  child: Checkbox(
                                    value: save_id,
                                    onChanged: _isProcessing
                                        ? null
                                        : (bool? value) {
                                            setState(() {
                                              save_id = value ?? false;
                                            });
                                          },
                                    activeColor: AppColors.skyType2,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TextWidgetString(
                                  '아이디 저장',
                                  TextAligns.left,
                                  AppSizes.i12,
                                  FontWeights.w500,
                                  AppColors.blackType2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 로그인 & 회원가입 버튼
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.s12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 로그인 버튼
                      SizedBox(
                        width: AppSizes.s127,
                        height: AppSizes.s48,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.skyType2,
                            disabledBackgroundColor:
                                AppColors.skyType2.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignConstants.radiusS),
                            ),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: AppSizes.s20,
                                  height: AppSizes.s20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: AppSizes.s2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  '로그인',
                                  style: TextStyle(
                                    fontSize: DesignConstants.fontSizeM,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(width: AppSizes.s12),

                      // 회원가입 버튼
                      SizedBox(
                        width: AppSizes.s127,
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
                                AppColors.grayType3.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignConstants.radiusS),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: DesignConstants.fontSizeM,
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
            bottom: AppSizes.s20,
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
                  height: AppSizes.s20,
                  width: AppSizes.s150,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Input Widget
  // ========================================

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
          fontSize: DesignConstants.fontSizeS,
          color: AppColors.blackType2,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: DesignConstants.fontSizeS,
            color: hintColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s16,
            vertical: AppSizes.s12,
          ),
        ),
      ),
    );
  }

  // ========================================
  // Password Input Widget with Visibility Toggle
  // ========================================

  Widget passwordInputWidget(
    double width,
    double height,
    TextEditingController controller,
    String hintText,
    Color hintColor,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        obscureText: !_isPasswordVisible,
        enabled: !_isProcessing,
        style: const TextStyle(
          fontSize: DesignConstants.fontSizeS,
          color: AppColors.blackType2,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: DesignConstants.fontSizeS,
            color: hintColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s16,
            vertical: AppSizes.s12,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: AppColors.grayType2,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
      ),
    );
  }
}
