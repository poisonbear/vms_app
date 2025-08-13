import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Flutter 알림 초기화
Future<void> _setupFlutterNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: '중요 알림을 위한 채널입니다.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettingsIOS = DarwinInitializationSettings();

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 알림 초기화
  await _setupFlutterNotifications();

  // 로컬화 초기화
  await initializeDateFormatting('ko_KR', null);

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

  // 저장소 서비스 초기화
  await StorageService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // API 클라이언트 제공
        RepositoryProvider<ApiClient>(
          create: (context) => ApiClient(),
        ),

        // Auth 관련
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

        // Vessel 관련
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

        // Navigation 관련
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
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}