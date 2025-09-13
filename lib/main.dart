// lib/main.dart
import 'dart:math' as math;
import 'dart:async';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
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
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/core/security/app_initializer.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/firebase_options.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/navigation_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
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

  final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
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
  static Future<void> requestPermissions() async {
    // 위치 권한
    await Permission.location.request();

    // 알림 권한
    await Permission.notification.request();

    // 카메라 권한 (필요한 경우)
    // await Permission.camera.request();

    // 저장소 권한 (필요한 경우)
    // await Permission.storage.request();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 알림 설정
  await _setupFlutterNotifications();

  // 로케일 초기화
  await initializeDateFormatting('ko_KR', null);

  // SharedPreferences 초기화
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // 환경 변수 로드
  await dotenv.load(fileName: '.env');

  // DI 컨테이너 초기화
  await initInjection();

  // 보안 설정 초기화
  await AppInitializer.initializeSecurity();

  // MultiProvider로 앱 실행
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserState()),
        ChangeNotifierProvider(create: (_) => VesselProvider()),
      ],
      child: MyApp(prefs: prefs),
    ),
  );
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        scaffoldBackgroundColor: getColorWhiteType1(),
        appBarTheme: AppBarTheme(
          backgroundColor: getColorWhiteType1(),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: getColorBlackType1()),
          titleTextStyle: TextStyle(
            color: getColorBlackType1(),
            fontSize: getSize20().toDouble(),
            fontWeight: getTextbold(),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(prefs: prefs),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const SplashScreen({super.key, required this.prefs});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String fcmToken = '';
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  final String apiUrl = dotenv.env['kdn_loginForm_key'] ?? '';
  final String apiUrl2 = dotenv.env['kdn_usm_select_role_data_key'] ?? '';
  final dioRequest = DioRequest();

  Future<void> _checkLoginStatus() async {
    await Future.delayed(AnimationConstants.splashDuration);

    // 권한 확인 및 요청
    await PermissionManager.requestPermissions();

    // Firebase 토큰 가져오기
    fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
    AppLogger.d('Firebase Token: $fcmToken');

    // SharedPreferences에 토큰 저장
    widget.prefs.setString('firebase_token', fcmToken);

    // 자동 로그인 상태 확인
    bool? isAutoLogin = widget.prefs.getBool('auto_login');
    String? savedId = widget.prefs.getString('saved_id');
    String? savedPw = widget.prefs.getString('saved_pw');

    // ========== 디버그 로그 추가 ==========
    AppLogger.d('========== 자동 로그인 체크 ==========');
    AppLogger.d('자동 로그인 상태: $isAutoLogin');
    AppLogger.d('저장된 ID: $savedId');
    AppLogger.d('저장된 PW 존재: ${savedPw != null}');
    AppLogger.d('=====================================');

    if (isAutoLogin == true && savedId != null && savedPw != null) {
      // 자동 로그인이 활성화되어 있고 저장된 정보가 있으면
      await _performAutoLogin(savedId, savedPw);
    } else {
      // 자동 로그인이 비활성화되어 있거나 저장된 정보가 없으면 로그인 화면으로
      if (!mounted) return;

      AppLogger.d('🔄 로그인 화면으로 이동');
      if (mounted) {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
      }
    }
  }

  // 자동 로그인 수행
  Future<void> _performAutoLogin(String userId, String password) async {
    try {
      AppLogger.d('========== 자동 로그인 시작 ==========');
      AppLogger.d('사용자 ID: $userId');

      // 로그인 API 호출
      final response = await dioRequest.dio.post(
        apiUrl,
        data: {'user_id': userId, 'passwd': password},
      );

      AppLogger.d('로그인 API 응답: ${response.statusCode}');

      // 권한 정보 가져오기
      final roleResponse = await dioRequest.dio.post(
        apiUrl2,
        data: {'user_id': userId},
      );

      final List<dynamic> result = roleResponse.data;
      AppLogger.d('권한 정보 응답: $result');

      // MMSI 값 추출
      int mmsi = 0;
      if (result.isNotEmpty && result[0]['mmsi'] != null) {
        mmsi = result[0]['mmsi'];
      }

      AppLogger.d('추출된 MMSI: $mmsi');

      // UserState Provider에 사용자 정보 저장 (화면 이동 전에 설정)
      if (!mounted) return;
      final userState = Provider.of<UserState>(context, listen: false);

      // 역할 정보 설정
      if (result.isNotEmpty && result[0]['role'] != null) {
        userState.setRole(result[0]['role'].toString());
        AppLogger.d('역할 설정: ${result[0]['role']}');
      }

      // MMSI 설정
      if (mmsi != 0) {
        userState.setMmsi(mmsi);
        AppLogger.d('MMSI 설정 완료: $mmsi');
      }

      // Firebase 토큰 업데이트
      await _updateFirebaseToken(userId);

      // ========== 중요: autoFocusLocation 추가 ==========
      if (!mounted) return;

      AppLogger.d('🚢 MainScreen으로 이동 (autoFocusLocation: true, MMSI: $mmsi)');

      AppLogger.d('========================================');
      AppLogger.d('🚀 자동 로그인 성공! MainScreen으로 이동');
      AppLogger.d('👤 userId: $userId');
      AppLogger.d('✅ autoFocusLocation: true 설정');
      AppLogger.d('========================================');

      if (mounted) {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(
            username: userId,
            autoFocusLocation: true, // ✅ 자동 포커스 활성화
          ),
        ),
      );
      }

      AppLogger.d('========== 자동 로그인 완료 ==========');
    } catch (e) {
      AppLogger.e('========== 자동 로그인 실패 ==========');
      AppLogger.e('에러: $e');
      AppLogger.e('=====================================');

      // 자동 로그인 실패 시 로그인 화면으로
      if (!mounted) return;
      if (mounted) {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
      }
    }
  }

  // Firebase 토큰 업데이트
  Future<void> _updateFirebaseToken(String userId) async {
    try {
      AppLogger.d('Firebase 토큰 업데이트 시작: $userId');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('firebase_App')
            .doc('userToken')
            .collection('users')
            .doc(userId)
            .set({
          'token': fcmToken,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        AppLogger.d('Firebase 토큰 업데이트 성공');
      } else {
        AppLogger.w('Firebase 사용자가 null입니다');
      }
    } catch (e) {
      AppLogger.e('Firebase 토큰 업데이트 실패: $e');
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
              Color(0xFF00BFFF),  // 위: 딥 스카이 블루 (맑은 하늘)
              Color(0xFFF0FFFF),  // 중간: 연한 청록 구름 (Azure)
              Color(0xFF1E90FF),  // 아래: 다저 블루 (깊은 바다)
            ],
            stops: [0.0, 0.5, 1.0],  // 그라데이션 위치
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 터빈 애니메이션 컨테이너
                  SizedBox(
                    width: 300,
                    height: 500,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // 터빈 기둥 (고정)
                        Positioned(
                          bottom: 0,
                          child: SvgPicture.asset(
                            'assets/kdn/home/img/turbine_pole.svg',
                            width: 150,
                            height: 300,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // 터빈 날개 컨테이너 (고정)
                        Positioned(
                          bottom: 230, // 조정된 위치 (SVG 내부 중심점 보정)
                          width: 200,
                          height: 200,
                          child: AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationController.value * 2 * math.pi,
                                // SVG 파일 내 실제 회전축 위치로 조정
                                alignment: const Alignment(0.0, 0.29),
                                child: child,
                              );
                            },
                            child: SvgPicture.asset(
                              'assets/kdn/home/img/turbine_blade.svg',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 앱 이름
                  Text(
                    'K-VMS',
                    style: TextStyle(
                      color: getColorWhiteType1(),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 로딩 텍스트
                  Text(
                    'loading...',
                    style: TextStyle(
                      color: getColorWhiteType1().withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
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