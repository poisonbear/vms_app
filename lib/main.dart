import 'dart:async'; // runZonedGuarded를 위한 import 추가
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'core/services/storage_service.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'core/error/error_handler.dart';
import 'core/error/error_logger.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/datasources/auth_datasource.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/vessel/cubit/vessel_cubit.dart';
import 'features/vessel/datasources/vessel_datasource.dart';
import 'features/vessel/repositories/vessel_repository.dart';
import 'features/navigation/cubit/navigation_cubit.dart';
import 'features/navigation/datasources/navigation_datasource.dart';
import 'features/navigation/repositories/navigation_repository.dart';
import 'shared/widgets/splash_screen.dart';

// 전역 네비게이터 키
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 플러터 로컬 알림 플러그인
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Firebase 백그라운드 메시지 핸들러
/// 앱이 백그라운드에 있을 때 메시지를 처리
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Firebase 초기화 (백그라운드에서 필요)
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    logger.i('백그라운드 메시지 수신: ${message.messageId}');

    // 백그라운드에서 알림 표시
    await _showNotification(
      title: message.notification?.title ?? '새 메시지',
      body: message.notification?.body ?? '새로운 알림이 도착했습니다.',
      payload: message.data['route'],
    );
  } catch (e) {
    print('백그라운드 메시지 처리 실패: $e');
  }
}

/// 알림 표시 헬퍼 함수
Future<void> _showNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  try {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: '중요 알림을 위한 채널입니다.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  } catch (e) {
    print('알림 표시 실패: $e');
  }
}

/// Firebase 및 알림 초기화
Future<void> _initializeFirebaseAndNotifications() async {
  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('Firebase 초기화 완료');

    // Firebase Messaging 설정
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 알림 초기화
    await _setupFlutterNotifications();

    // FCM 토큰 가져오기 및 로깅
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        logger.i('FCM Token: ${token.substring(0, 20)}...'); // 보안을 위해 일부만 로깅
      }
    } catch (e) {
      logger.w('FCM 토큰 가져오기 실패: $e');
    }

    // 포그라운드 메시지 리스너
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i('포그라운드 메시지 수신: ${message.messageId}');

      if (message.notification != null) {
        _showNotification(
          title: message.notification!.title ?? '새 메시지',
          body: message.notification!.body ?? '새로운 알림이 도착했습니다.',
          payload: message.data['route'],
        );
      }
    });

    // 앱이 종료된 상태에서 알림 탭으로 실행되었을 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i('알림으로 앱 실행: ${message.messageId}');
      _handleNotificationTap(message.data);
    });

    // 앱이 완전히 종료된 상태에서 알림 탭으로 실행되었을 때
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      logger.i('초기 메시지로 앱 실행: ${initialMessage.messageId}');
      // 앱이 완전히 로드된 후에 처리하도록 지연
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(initialMessage.data);
      });
    }

  } catch (e, stackTrace) {
    logger.e('Firebase 초기화 실패', error: e, stackTrace: stackTrace);
    // Firebase 초기화 실패해도 앱은 계속 실행되도록 함
  }
}

/// Flutter 알림 초기화
Future<void> _setupFlutterNotifications() async {
  try {
    // Android 알림 채널 생성
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: '중요 알림을 위한 채널입니다.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 알림 초기화 설정
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleLocalNotificationTap(response.payload);
      },
    );

    logger.i('Flutter 알림 초기화 완료');
  } catch (e, stackTrace) {
    logger.e('Flutter 알림 초기화 실패', error: e, stackTrace: stackTrace);
  }
}

/// 알림 탭 처리
void _handleNotificationTap(Map<String, dynamic> data) {
  try {
    final route = data['route'] as String?;
    if (route != null && navigatorKey.currentState != null) {
      // 라우트에 따른 네비게이션 처리
      switch (route) {
        case '/vessel':
        // 선박 화면으로 이동
          break;
        case '/navigation':
        // 항행 화면으로 이동
          break;
        case '/weather':
        // 기상 화면으로 이동
          break;
        default:
        // 기본 화면으로 이동
          break;
      }
    }
  } catch (e) {
    logger.e('알림 탭 처리 실패: $e');
  }
}

/// 로컬 알림 탭 처리
void _handleLocalNotificationTap(String? payload) {
  if (payload != null) {
    final data = {'route': payload};
    _handleNotificationTap(data);
  }
}

/// 앱 초기화
Future<void> _initializeApp() async {
  try {
    // 1. 환경 변수 로드
    await dotenv.load(fileName: ".env");
    logger.i('환경 변수 로드 완료');

    // 2. 저장소 서비스 초기화
    await StorageService.init();
    logger.i('저장소 서비스 초기화 완료');

    // 3. 로컬화 초기화
    await initializeDateFormatting('ko_KR', null);
    logger.i('로컬화 초기화 완료');

    // 4. Firebase 및 알림 초기화
    await _initializeFirebaseAndNotifications();

    // 5. 시스템 UI 설정
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // 6. 화면 방향 설정 (세로 모드 고정)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    logger.i('앱 초기화 완료');
  } catch (e, stackTrace) {
    logger.e('앱 초기화 실패', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

/// 애플리케이션 진입점
Future<void> main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 플러터 에러 핸들링
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e('Flutter 에러 발생', error: details.exception, stackTrace: details.stack);
    ErrorLogger.logError(details.exception, stackTrace: details.stack, fatal: false);
  };

  // Zone 에러 핸들링
  runZonedGuarded<Future<void>>(
        () async {
      try {
        // 앱 초기화
        await _initializeApp();

        // 앱 실행
        runApp(const MyApp());
      } catch (e, stackTrace) {
        logger.e('앱 시작 실패', error: e, stackTrace: stackTrace);

        // 에러 발생 시에도 앱을 실행하되, 에러 화면 표시
        runApp(ErrorApp(error: e.toString()));
      }
    },
        (error, stackTrace) {
      logger.e('Zone 에러 발생', error: error, stackTrace: stackTrace);
      ErrorLogger.logError(error, stackTrace: stackTrace, fatal: false);
    },
  );
}

/// 메인 애플리케이션
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // API 클라이언트 제공 (싱글톤)
        RepositoryProvider<ApiClient>(
          create: (context) => ApiClient.instance,
        ),

        // Auth 관련 의존성
        RepositoryProvider<AuthDatasource>(
          create: (context) => AuthDatasource(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(
            datasource: context.read<AuthDatasource>(),
          ),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(
            repository: context.read<AuthRepository>(),
          ),
        ),

        // Vessel 관련 의존성
        RepositoryProvider<VesselDatasource>(
          create: (context) => VesselDatasource(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        RepositoryProvider<VesselRepository>(
          create: (context) => VesselRepository(
            datasource: context.read<VesselDatasource>(),
          ),
        ),
        BlocProvider<VesselCubit>(
          create: (context) => VesselCubit(
            repository: context.read<VesselRepository>(),
          ),
        ),

        // Navigation 관련 의존성
        RepositoryProvider<NavigationDatasource>(
          create: (context) => NavigationDatasource(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        RepositoryProvider<NavigationRepository>(
          create: (context) => NavigationRepository(
            datasource: context.read<NavigationDatasource>(),
          ),
        ),
        BlocProvider<NavigationCubit>(
          create: (context) => NavigationCubit(
            repository: context.read<NavigationRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'VMS App',
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey, // 전역 네비게이터 키 설정
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        // 글로벌 에러 처리 (ErrorWidget 타입 문제 해결)
        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return Material(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '화면 로드 중 오류가 발생했습니다',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorDetails.exception.toString(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          };
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}

/// 에러 발생 시 표시할 앱
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VMS App - Error',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '앱 시작 중 오류가 발생했습니다',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // 앱 재시작 시도
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sky3,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('앱 재시작'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}