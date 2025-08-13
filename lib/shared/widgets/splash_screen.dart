import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../core/services/storage_service.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/main/views/main_view.dart';

/// 스플래시 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String fcmToken = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// 자동로그인 상태 체크
  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    String? token = await StorageService.getFirebaseToken();
    bool autoLogin = await StorageService.getAutoLogin();

    fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (token != null && autoLogin) {
        String? username = await StorageService.getUsername();

        try {
          final authCubit = context.read<AuthCubit>();
          final result = await authCubit.autoLogin(
            token: token,
            fcmToken: fcmToken,
          );

          if (result.isSuccess) {
            final fetchedUsername = result.username ?? username ?? '사용자';
            await StorageService.saveUsername(fetchedUsername);
            _navigateToMain(fetchedUsername);
          } else {
            await StorageService.saveAutoLogin(false);
            _navigateToLogin();
          }
        } catch (e) {
          _navigateToLogin();
        }
      } else {
        _navigateToLogin();
      }
    });
  }

  void _navigateToMain(String username) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainView(username: username),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}