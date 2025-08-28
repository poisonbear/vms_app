// lib/main.dart

import 'dart:async';
import 'package:vms_app/core/constants/constants.dart';
import 'dart:convert';
import 'dart:developer';
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
import 'package:vms_app/core/di/injection.dart'; // ✅ DI 추가
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
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(channel);
  }


  const initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettingsIOS =
  DarwinInitializationSettings();

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// ✅ PermissionManager 클래스 추가 (별도 파일로 분리하는 것이 좋습니다)
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

  // ✅ DI 컨테이너 초기화 추가
  await initInjection();

  // MultiProvider로 앱 실행
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()), //항행이력 목록조회
        ChangeNotifierProvider(create: (_) => UserState()), //사용자 권한 가져오기
        ChangeNotifierProvider(create: (_) => VesselProvider()), //현재선박 좌표 조회
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
        scaffoldBackgroundColor: getColorwhite_type1(),
        appBarTheme: AppBarTheme(
          backgroundColor: getColorwhite_type1(),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: getColorblack_type1()),
          titleTextStyle: TextStyle(
            color: getColorblack_type1(),
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

class _SplashScreenState extends State<SplashScreen> {
  String fcmToken = ''; // fcm 토큰

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); //앱 실행될 때, 현재 자동로그인 상태 유/무 체크
  }

  final String apiUrl = dotenv.env['kdn_loginForm_key'] ?? '';
  final String apiUrl2 = dotenv.env['kdn_usm_select_role_data_key'] ?? '';
  final dioRequest = DioRequest();

  Future<void> _checkLoginStatus() async {
    await Future.delayed(AnimationConstants.splashDuration); // 스플래시 화면 3초 유지

    // 권한 확인 및 요청
    await PermissionManager.requestPermissions();

    // Firebase 토큰 가져오기
    fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
    log('Firebase Token: $fcmToken');

    // SharedPreferences에 토큰 저장
    widget.prefs.setString('firebase_token', fcmToken);

    // 자동 로그인 상태 확인
    bool? isAutoLogin = widget.prefs.getBool('auto_login');
    String? savedId = widget.prefs.getString('saved_id');
    String? savedPw = widget.prefs.getString('saved_pw');

    log('자동 로그인 상태: $isAutoLogin');
    log('저장된 ID: $savedId');

    if (isAutoLogin == true && savedId != null && savedPw != null) {
      // 자동 로그인이 활성화되어 있고 저장된 정보가 있으면
      await _performAutoLogin(savedId, savedPw);
    } else {
      // 자동 로그인이 비활성화되어 있거나 저장된 정보가 없으면 로그인 화면으로
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  // 자동 로그인 수행
  Future<void> _performAutoLogin(String userId, String password) async {
    try {
      // 로그인 API 호출
      final response = await dioRequest.dio.post(
        apiUrl,
        data: {'user_id': userId, 'passwd': password},
      );

      // 권한 정보 가져오기
      final roleResponse = await dioRequest.dio.post(
        apiUrl2,
        data: {'user_id': userId},
      );

      final List<dynamic> result = roleResponse.data;

      // MMSI 값 추출
      int mmsi = 0;
      if (result.isNotEmpty && result[0]['mmsi'] != null) {
        mmsi = result[0]['mmsi'];
      }

      // Firebase 토큰 업데이트
      await _updateFirebaseToken(userId);

      // 자동 로그인 성공 시 메인 화면으로 이동
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => mainView(
            username: userId,
          ),
        ),
      );

      // UserState Provider에 사용자 정보 저장
      if (!mounted) return;
      final userState = Provider.of<UserState>(context, listen: false);

      // ✅ setRole 메서드가 String을 받는다면 JSON 문자열로 변환
      userState.setRole(jsonEncode(result));
      // 또는 setRoleData 같은 다른 메서드가 있을 수 있습니다
      // userState.setRoleData(result);

      // MMSI 설정 (UserState에 해당 메서드가 있는 경우)
      // userState.setMMSI(mmsi);

    } catch (e) {
      log('자동 로그인 실패: $e');
      // 자동 로그인 실패 시 로그인 화면으로
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  // Firebase 토큰 업데이트
  Future<void> _updateFirebaseToken(String userId) async {
    try {
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
      }
    } catch (e) {
      log('Firebase 토큰 업데이트 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getColorsky_Type2(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지
            SvgPicture.asset(
              'assets/kdn/splash_logo.svg',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: DesignConstants.spacing20),
            // 로딩 인디케이터
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(getColorwhite_type1()),
            ),
          ],
        ),
      ),
    );
  }
}