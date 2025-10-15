// lib/main.dart
import 'dart:math' as math;
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/firebase_options.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/providers/emergency_provider.dart';
import 'package:vms_app/presentation/screens/auth/login_screen.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';

/// Flutter 로컬 알림 플러그인 인스턴스
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Flutter 알림 설정 초기화
/// Android 및 iOS 플랫폼별 알림 채널 및 초기 설정 수행
Future<void> _setupFlutterNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(channel);
  }

  const initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettingsIOS = DarwinInitializationSettings();

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

/// 앱 권한 관리 클래스
class PermissionManager {
  PermissionManager._();

  /// 앱 실행에 필요한 권한 요청
  static Future<void> requestPermissions() async {
    await Permission.location.request();
    await Permission.notification.request();
  }
}

/// 앱 진입점
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _setupFlutterNotifications();
  await initializeDateFormatting('ko_KR', null);

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await dotenv.load(fileName: '.env');
  await initInjection();
  await AppInitializer.initializeSecurity();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserState()),
        ChangeNotifierProvider(create: (_) => VesselProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
      ],
      child: MyApp(prefs: prefs),
    ),
  );
}

/// 앱의 최상위 위젯
class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        scaffoldBackgroundColor: AppColors.whiteType1,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.whiteType1,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppColors.blackType1),
          titleTextStyle: TextStyle(
            color: AppColors.blackType1,
            fontSize: AppSizes.s20.toDouble(),
            fontWeight: FontWeights.bold,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(prefs: prefs),
    );
  }
}

/// 스플래시 화면 위젯
class SplashScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const SplashScreen({super.key, required this.prefs});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// 자동 로그인 재시도 설정
class _AutoLoginRetryConfig {
  const _AutoLoginRetryConfig._();

  static const int maxRetries = 3;
  static const Duration retryDelay = AppDurations.seconds2;
}

/// 스플래시 화면 상태 관리 클래스
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String fcmToken = StringConstants.emptyString;
  late AnimationController _rotationController;

  final String apiUrl = ApiConfig.authLogin;
  final String apiUrl2 = ApiConfig.authRole;
  final dioRequest = DioRequest();
  final _secureStorage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: AppDurations.seconds2,
      vsync: this,
    )..repeat();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// 로그인 상태 확인 메서드
  Future<void> _checkLoginStatus() async {
    await Future.delayed(AppDurations.seconds3);
    await PermissionManager.requestPermissions();
    await _initializeFcmToken();

    if (apiUrl.isEmpty || apiUrl2.isEmpty) {
      AppLogger.e(ErrorMessages.apiUrlNotSet);
      _navigateToLogin();
      return;
    }

    final isAutoLogin = widget.prefs.getBool(StringConstants.autoLoginKey) ?? false;

    // ✅ SecureStorage에서 암호화된 데이터 읽기
    final credentials = await _secureStorage.loadCredentials();
    final savedId = credentials['id'];
    final savedPw = credentials['password'];

    _logAutoLoginCheck(isAutoLogin, savedId, savedPw);

    if (isAutoLogin && savedId != null && savedPw != null) {
      await _performAutoLogin(savedId, savedPw);
    } else {
      _navigateToLogin();
    }
  }

  /// FCM 토큰 초기화
  Future<void> _initializeFcmToken() async {
    try {
      fcmToken = await FirebaseMessaging.instance.getToken() ?? StringConstants.emptyString;

      if (fcmToken.isEmpty) {
        AppLogger.w(LogMessages.fcmTokenRetry);
        await Future.delayed(AppDurations.seconds2);
        fcmToken = await FirebaseMessaging.instance.getToken() ?? StringConstants.emptyString;
      }

      // ✅ 토큰 일부 + 길이값 함께 표시
      if (fcmToken.isNotEmpty) {
        final preview = fcmToken.substring(0, math.min(20, fcmToken.length));
        AppLogger.d('FCM 토큰 초기화 완료: $preview... (길이: ${fcmToken.length})');
      } else {
        AppLogger.e('FCM 토큰 초기화 실패');
      }

      widget.prefs.setString(StringConstants.firebaseTokenKey, fcmToken);
    } catch (e) {
      AppLogger.e('FCM 토큰 가져오기 실패: $e');
      fcmToken = StringConstants.emptyString;
    }
  }

  /// 자동 로그인 체크 로그 출력
  void _logAutoLoginCheck(bool? isAutoLogin, String? savedId, String? savedPw) {
    AppLogger.d(LogMessages.autoLoginCheck);
    AppLogger.d('자동 로그인 상태: $isAutoLogin');
    // ✅ 보안: 계정 정보 존재 여부만 표시
    AppLogger.d('저장된 계정 정보: ${savedId != null && savedPw != null ? "존재" : "없음"}');
    AppLogger.d(LogMessages.separator);
  }

  /// 자동 로그인 수행 (재시도 로직 포함)
  Future<void> _performAutoLogin(String userId, String password, {int retryCount = 0}) async {
    try {
      AppLogger.d(LogMessages.autoLoginStart);
      if (retryCount > 0) {
        AppLogger.d('재시도 횟수: $retryCount/${_AutoLoginRetryConfig.maxRetries}');
      }

      final firebaseEmail = _buildFirebaseEmail(userId);
      AppLogger.d('Firebase 인증 시도 중...');

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: firebaseEmail, password: password);

      final firebaseToken = await userCredential.user?.getIdToken();
      final uuid = userCredential.user?.uid;

      if (firebaseToken == null) {
        throw Exception(ErrorMessages.firebaseTokenMissing);
      }

      AppLogger.d(LogMessages.firebaseAuthSuccess);

      // ✅ Firebase 토큰도 일부만 표시
      if (firebaseToken.isNotEmpty) {
        final tokenPreview = firebaseToken.substring(0, math.min(20, firebaseToken.length));
        AppLogger.d('Firebase 토큰 획득: $tokenPreview... (길이: ${firebaseToken.length})');
      }

      await widget.prefs.setString(StringConstants.firebaseTokenKey, firebaseToken);

      final pureUserId = _extractPureUserId(userId);
      final response = await _callLoginApi(pureUserId, password, firebaseToken, uuid);

      _validateApiResponse(response);

      final roleData = await _fetchUserRole(pureUserId);
      final mmsi = _extractMmsi(roleData);
      final role = roleData[StringConstants.roleKey]?.toString();

      AppLogger.d('사용자 정보 조회 완료');
      // ✅ MMSI는 공개 정보이므로 표시 가능
      AppLogger.d('MMSI: $mmsi, Role: $role');

      await _updateUserState(role, mmsi);
      await _updateFirebaseToken(pureUserId);

      if (!mounted) return;

      _logSuccessAndNavigate(pureUserId);
    } on FirebaseAuthException catch (e) {
      // 네트워크 에러이고 재시도 횟수가 남아있으면 재시도
      if (_isNetworkError(e.code) && retryCount < _AutoLoginRetryConfig.maxRetries) {
        AppLogger.w('네트워크 에러 감지 - 재시도 예정 (${retryCount + 1}/${_AutoLoginRetryConfig.maxRetries})');
        await Future.delayed(_AutoLoginRetryConfig.retryDelay);
        return _performAutoLogin(userId, password, retryCount: retryCount + 1);
      }
      _handleFirebaseAuthError(e, retryCount);
    } on DioException catch (e) {
      // Dio 네트워크 에러도 재시도
      if (_isDioNetworkError(e) && retryCount < _AutoLoginRetryConfig.maxRetries) {
        AppLogger.w('서버 통신 에러 감지 - 재시도 예정 (${retryCount + 1}/${_AutoLoginRetryConfig.maxRetries})');
        await Future.delayed(_AutoLoginRetryConfig.retryDelay);
        return _performAutoLogin(userId, password, retryCount: retryCount + 1);
      }
      _handleDioError(e);
    } catch (e) {
      _handleGeneralError(e);
    }
  }

  /// Firebase 에러가 네트워크 관련 에러인지 확인
  bool _isNetworkError(String errorCode) {
    return errorCode == 'network-request-failed' ||
        errorCode == 'unknown' ||
        errorCode == 'timeout';
  }

  /// Dio 에러가 네트워크 관련 에러인지 확인
  bool _isDioNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  /// Firebase 이메일 형식 생성
  String _buildFirebaseEmail(String userId) {
    return userId.contains('@')
        ? userId
        : '$userId${StringConstants.emailDomain}';
  }

  /// 순수 사용자 ID 추출
  String _extractPureUserId(String userId) {
    return userId.contains('@') ? userId.split('@')[0] : userId;
  }

  /// 서버 로그인 API 호출
  Future<Response> _callLoginApi(
      String userId,
      String password,
      String firebaseToken,
      String? uuid,
      ) async {
    return await dioRequest.dio.post(
      apiUrl,
      data: {
        'user_id': userId,
        'user_pwd': password,
        'auto_login': true,
        'fcm_tkn': fcmToken,
        'uuid': uuid,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $firebaseToken'},
        sendTimeout: AppDurations.seconds10,
        receiveTimeout: AppDurations.seconds10,
      ),
    );
  }

  /// API 응답 검증
  void _validateApiResponse(Response response) {
    AppLogger.d('로그인 API 응답: ${response.statusCode}');

    if (response.statusCode != NumericConstants.httpStatusOk) {
      throw Exception('${ErrorMessages.loginFailed}: ${response.statusCode}');
    }

    if (response.data == null) {
      throw Exception(ErrorMessages.dataFormat);
    }
  }

  /// 사용자 권한 정보 조회
  Future<Map<String, dynamic>> _fetchUserRole(String userId) async {
    final roleResponse = await dioRequest.dio.post(
      apiUrl2,
      data: {'user_id': userId},
      options: Options(
        sendTimeout: AppDurations.seconds10,
        receiveTimeout: AppDurations.seconds10,
      ),
    );

    AppLogger.d('권한 정보 조회 완료');

    final roleData = _parseRoleResponse(roleResponse.data);
    if (roleData == null) {
      throw Exception(ErrorMessages.roleDataMissing);
    }

    return roleData;
  }

  /// Provider에 사용자 정보 업데이트
  Future<void> _updateUserState(String? role, int mmsi) async {
    if (!mounted) return;

    try {
      final userState = context.read<UserState>();

      if (role != null) {
        await userState.setRole(role);
        AppLogger.d('${LogMessages.roleSetComplete}: $role');
      }

      if (mmsi != NumericConstants.zeroValue) {
        await userState.setMmsi(mmsi);
        AppLogger.d('${LogMessages.mmsiSetComplete}: $mmsi');
      }
    } catch (e) {
      AppLogger.e('${LogMessages.userInfoSaveFailed}: $e');
    }
  }

  /// 성공 로그 출력 및 메인 화면 이동
  void _logSuccessAndNavigate(String userId) {
    AppLogger.d(LogMessages.separator);
    AppLogger.d('자동 로그인 성공! ${LogMessages.navigateToMain}');
    AppLogger.d('자동 위치 포커스: 활성화');
    AppLogger.d(LogMessages.separator);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          username: userId,
          autoFocusLocation: true,
        ),
      ),
    );

    AppLogger.d(LogMessages.autoLoginComplete);
  }

  /// Firebase 인증 에러 처리
  void _handleFirebaseAuthError(FirebaseAuthException e, int retryCount) {
    AppLogger.e(LogMessages.autoLoginFailed);
    // ✅ 보안: 에러 코드만 표시, 메시지는 제외
    AppLogger.e('Firebase 인증 실패 - 에러 코드: ${e.code}');

    // 재시도 횟수 정보 로그
    if (retryCount > 0) {
      AppLogger.e('총 $retryCount회 재시도했으나 실패');
    }

    // 네트워크 에러인 경우
    if (_isNetworkError(e.code)) {
      AppLogger.e('네트워크 연결 문제로 인한 실패');
    }

    // 잘못된 자격 증명인 경우만 자동 로그인 데이터 삭제
    if (e.code == FirebaseErrorCodes.userNotFound ||
        e.code == FirebaseErrorCodes.wrongPassword) {
      _clearAutoLoginData();
    }

    AppLogger.e(LogMessages.separator);
    _navigateToLogin();
  }

  /// Dio 통신 에러 처리
  void _handleDioError(DioException e) {
    AppLogger.e(LogMessages.autoLoginFailed);
    AppLogger.e('서버 통신 실패 - 타입: ${e.type}');
    if (e.response?.statusCode != null) {
      AppLogger.e('응답 코드: ${e.response?.statusCode}');
    }
    AppLogger.e(LogMessages.separator);
    _navigateToLogin();
  }

  /// 일반 에러 처리
  void _handleGeneralError(dynamic e) {
    AppLogger.e(LogMessages.autoLoginFailed);
    AppLogger.e('예상치 못한 에러가 발생했습니다');
    AppLogger.e(LogMessages.separator);
    _navigateToLogin();
  }

  /// 역할 응답 데이터 파싱
  Map<String, dynamic>? _parseRoleResponse(dynamic responseData) {
    if (responseData is List &&
        responseData.isNotEmpty &&
        responseData[0] is Map) {
      return responseData[0] as Map<String, dynamic>;
    } else if (responseData is Map) {
      return responseData as Map<String, dynamic>;
    }
    return null;
  }

  /// MMSI 값 추출
  int _extractMmsi(Map<String, dynamic> data) {
    final mmsiValue = data['mmsi'];
    if (mmsiValue == null) return NumericConstants.zeroValue;
    if (mmsiValue is int) return mmsiValue;
    return int.tryParse(mmsiValue.toString()) ?? NumericConstants.zeroValue;
  }

  /// 자동 로그인 데이터 삭제
  Future<void> _clearAutoLoginData() async {
    // ✅ SecureStorage 먼저 삭제 (가장 중요!)
    await _secureStorage.clearAll();
    // SharedPreferences 플래그 정리
    await widget.prefs.setBool(StringConstants.autoLoginKey, false);
    AppLogger.d(LogMessages.autoLoginDataCleared);
  }

  /// 로그인 화면으로 이동
  void _navigateToLogin() {
    if (!mounted) return;
    AppLogger.d(LogMessages.navigateToLogin);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  /// Firestore에 FCM 토큰 업데이트
  Future<void> _updateFirebaseToken(String userId) async {
    try {
      AppLogger.d('${LogMessages.firebaseTokenUpdate} 시작');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection(StringConstants.firestoreAppCollection)
            .doc(StringConstants.userTokenDoc)
            .collection(StringConstants.usersCollection)
            .doc(userId)
            .set({
          'token': fcmToken,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        AppLogger.d('${LogMessages.firebaseTokenUpdate} 성공');
      } else {
        AppLogger.w('Firebase 사용자가 null입니다');
      }
    } catch (e) {
      AppLogger.e('${LogMessages.firebaseTokenUpdate} 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(SplashConstants.gradientTop),
              Color(SplashConstants.gradientMiddle),
              Color(SplashConstants.gradientBottom),
            ],
            stops: SplashConstants.gradientStops,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: SplashConstants.turbineBottom,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: SplashConstants.containerHeight,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          bottom: 0,
                          child: SvgPicture.asset(
                            StringConstants.turbinePoleAsset,
                            width: SplashConstants.turbineWidth,
                            height: SplashConstants.turbineHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          bottom: SplashConstants.bladeBottom,
                          width: SplashConstants.bladeSize,
                          height: SplashConstants.bladeSize,
                          child: AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationController.value * 2 * math.pi,
                                alignment: const Alignment(
                                  SplashConstants.turbineAlignmentX,
                                  SplashConstants.turbineAlignmentY,
                                ),
                                child: child,
                              );
                            },
                            child: SvgPicture.asset(
                              StringConstants.turbineBladeAsset,
                              width: SplashConstants.bladeSize,
                              height: SplashConstants.bladeSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SplashConstants.textSpacing),
                  Text(
                    InfoMessages.loading,
                    style: TextStyle(
                      color: AppColors.whiteType1.withValues(
                        alpha: SplashConstants.textOpacity,
                      ),
                      fontSize: SplashConstants.textSize,
                      fontWeight: FontWeight.w400,
                      letterSpacing: SplashConstants.textLetterSpacing,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}