// lib/main.dart
import 'dart:math' as math;
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/utils/password_utils.dart';
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
import 'package:vms_app/presentation/providers/route_provider.dart';
import 'package:vms_app/presentation/screens/auth/login_screen.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _setupFlutterNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

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

class PermissionManager {
  PermissionManager._();

  static Future<void> requestPermissions() async {
    await Permission.location.request();
    await Permission.notification.request();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _setupFlutterNotifications();
  AppLogger.d('백그라운드 메시지 처리: ${message.messageId}');
}

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final secureStorage = SecureStorageService();
    await secureStorage.migrateFromSharedPreferences();
    AppLogger.i('보안 저장소 마이그레이션 완료');

    try {
      await dotenv.load(fileName: '.env');
      AppLogger.d('환경 변수 로드 완료');
    } catch (e) {
      AppLogger.e('환경 변수 로드 실패', e);
    }

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await _setupFlutterNotifications();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.d('포그라운드 메시지 수신: ${message.notification?.title}');
    });

    await initializeDateFormatting('ko_KR', null);
    setupDependencies();

    final prefs = await SharedPreferences.getInstance();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserState()),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(create: (_) => RouteProvider()),
          ChangeNotifierProvider(create: (_) => VesselProvider()),
          ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ],
        child: MyApp(prefs: prefs),
      ),
    );
  }, (error, stack) {
    AppLogger.e('앱 크래시', error, stack);
  });
}

//수정: MaterialApp을 반환하도록 변경
class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VMS App',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(prefs: prefs),
    );
  }
}

class _AutoLoginRetryConfig {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}

class SplashScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SplashScreen({super.key, required this.prefs});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String fcmToken = StringConstants.emptyString;
  late AnimationController _rotationController;
  final _secureStorage = SecureStorageService();

  final String apiUrl = ApiConfig.authLogin;
  final String apiUrl2 = ApiConfig.authRole;
  final dioRequest = DioRequest();

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

  Future<void> _checkLoginStatus() async {
    await Future.delayed(AppDurations.seconds3);
    await PermissionManager.requestPermissions();
    await _initializeFcmToken();

    if (apiUrl.isEmpty || apiUrl2.isEmpty) {
      AppLogger.e(ErrorMessages.apiUrlNotSet);
      _navigateToLogin();
      return;
    }

    final isAutoLogin = widget.prefs.getBool(StringConstants.autoLoginKey);

    final credentials = await _secureStorage.loadCredentials();
    final savedId = credentials['id'];
    final savedPw = credentials['password'];

    _logAutoLoginCheck(isAutoLogin, savedId, savedPw);

    if (isAutoLogin == true && savedId != null && savedPw != null) {
      await _performAutoLogin(savedId, savedPw);
    } else {
      _navigateToLogin();
    }
  }

  Future<void> _initializeFcmToken() async {
    try {
      fcmToken = await FirebaseMessaging.instance.getToken() ??
          StringConstants.emptyString;

      if (fcmToken.isEmpty) {
        AppLogger.w(LogMessages.fcmTokenRetry);
        await Future.delayed(AppDurations.seconds2);
        fcmToken = await FirebaseMessaging.instance.getToken() ??
            StringConstants.emptyString;
      }

      if (fcmToken.isNotEmpty) {
        final preview = fcmToken.substring(0, math.min(20, fcmToken.length));
        AppLogger.d('FCM 토큰 초기화 완료: $preview... (길이: ${fcmToken.length})');
      } else {
        AppLogger.e('FCM 토큰 초기화 실패');
      }

      widget.prefs.setString('fcm_token', fcmToken);
    } catch (e) {
      AppLogger.e('FCM 토큰 가져오기 실패: $e');
      fcmToken = StringConstants.emptyString;
    }
  }

  void _logAutoLoginCheck(bool? isAutoLogin, String? savedId, String? savedPw) {
    AppLogger.d(LogMessages.autoLoginCheck);
    AppLogger.d('자동 로그인 상태: $isAutoLogin');
    AppLogger.d(
        '저장된 계정 정보: ${savedId != null && savedPw != null ? "존재" : "없음"}');
    AppLogger.d(LogMessages.separator);
  }

  Future<void> _performAutoLogin(String userId, String password,
      {int retryCount = 0}) async {
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

      if (firebaseToken.isNotEmpty) {
        final tokenPreview =
            firebaseToken.substring(0, math.min(20, firebaseToken.length));
        AppLogger.d(
            'Firebase 토큰 획득: $tokenPreview... (길이: ${firebaseToken.length})');
      }

      await _secureStorage.saveSessionData(
        firebaseToken: firebaseToken,
        uuid: uuid ?? '',
      );

      final pureUserId = _extractPureUserId(userId);
      final response =
          await _callLoginApi(pureUserId, password, firebaseToken, uuid);

      _validateApiResponse(response);

      final roleData = await _fetchUserRole(pureUserId);
      final mmsi = _extractMmsi(roleData);
      final role = roleData[StringConstants.roleKey]?.toString();

      AppLogger.d('사용자 정보 조회 완료');
      AppLogger.d('MMSI: $mmsi, Role: $role');

      await _updateUserState(role, mmsi);
      await _updateFirebaseToken(pureUserId);

      if (!mounted) return;
      if (!context.mounted) return;

      _logSuccessAndNavigate(pureUserId);
    } on FirebaseAuthException catch (e) {
      if (_isNetworkError(e.code) &&
          retryCount < _AutoLoginRetryConfig.maxRetries) {
        AppLogger.w(
            '네트워크 에러 감지 - 재시도 예정 (${retryCount + 1}/${_AutoLoginRetryConfig.maxRetries})');
        await Future.delayed(_AutoLoginRetryConfig.retryDelay);
        return _performAutoLogin(userId, password, retryCount: retryCount + 1);
      }
      _handleFirebaseAuthError(e, retryCount);
    } on DioException catch (e) {
      if (_isDioNetworkError(e) &&
          retryCount < _AutoLoginRetryConfig.maxRetries) {
        AppLogger.w(
            '서버 통신 에러 감지 - 재시도 예정 (${retryCount + 1}/${_AutoLoginRetryConfig.maxRetries})');
        await Future.delayed(_AutoLoginRetryConfig.retryDelay);
        return _performAutoLogin(userId, password, retryCount: retryCount + 1);
      }
      _handleDioError(e);
    } catch (e) {
      _handleGeneralError(e);
    }
  }

  bool _isNetworkError(String errorCode) {
    return errorCode == 'network-request-failed' ||
        errorCode == 'unknown' ||
        errorCode == 'timeout';
  }

  bool _isDioNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  String _buildFirebaseEmail(String userId) {
    return userId.contains('@')
        ? userId
        : '$userId${StringConstants.emailDomain}';
  }

  String _extractPureUserId(String userId) {
    return userId.contains('@') ? userId.split('@')[0] : userId;
  }

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
        'user_pwd': PasswordUtils.hash(password), // 해싱된 비밀번호 전송
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

  void _validateApiResponse(Response response) {
    AppLogger.d('로그인 API 응답: ${response.statusCode}');

    if (response.statusCode != NumericConstants.httpStatusOk) {
      throw Exception('${ErrorMessages.loginFailed}: ${response.statusCode}');
    }

    if (response.data == null) {
      throw Exception(ErrorMessages.dataFormat);
    }
  }

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

  Future<void> _updateUserState(String? role, int mmsi) async {
    if (!mounted) return;
    if (!context.mounted) return;

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

  void _handleFirebaseAuthError(FirebaseAuthException e, int retryCount) {
    AppLogger.e(LogMessages.autoLoginFailed);
    AppLogger.e('Firebase 인증 실패 - 에러 코드: ${e.code}');

    if (retryCount > 0) {
      AppLogger.e('총 $retryCount회 재시도했으나 실패');
    }

    if (_isNetworkError(e.code)) {
      AppLogger.e('네트워크 연결 문제로 인한 실패');
    }

    if (e.code == 'user-not-found' || e.code == 'wrong-password') {
      _clearAutoLoginData();
    }

    AppLogger.e(LogMessages.separator);
    _navigateToLogin();
  }

  void _handleDioError(DioException e) {
    AppLogger.e(LogMessages.autoLoginFailed);
    AppLogger.e('서버 통신 실패 - 타입: ${e.type}');
    if (e.response?.statusCode != null) {
      AppLogger.e('응답 코드: ${e.response?.statusCode}');
    }
    AppLogger.e(LogMessages.separator);
    _navigateToLogin();
  }

  void _handleGeneralError(dynamic e) {
    AppLogger.e(LogMessages.autoLoginFailed);
    AppLogger.e('예상치 못한 에러가 발생했습니다');
    AppLogger.e(LogMessages.separator);
    _navigateToLogin();
  }

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

  int _extractMmsi(Map<String, dynamic> data) {
    final mmsiValue = data['mmsi'];
    if (mmsiValue == null) return NumericConstants.zeroValue;
    if (mmsiValue is int) return mmsiValue;
    return int.tryParse(mmsiValue.toString()) ?? NumericConstants.zeroValue;
  }

  Future<void> _clearAutoLoginData() async {
    await _secureStorage.deleteCredentials();
    await widget.prefs.setBool(StringConstants.autoLoginKey, false);
    AppLogger.d(LogMessages.autoLoginDataCleared);
  }

  void _navigateToLogin() {
    if (!mounted) return;
    if (!context.mounted) return;
    AppLogger.d(LogMessages.navigateToLogin);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

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

  //스플래시 화면 UI
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
