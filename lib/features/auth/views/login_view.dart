// lib/features/auth/views/login_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/crypto_utils.dart';
import '../../../core/error/error_reporter.dart';
import '../../../core/services/storage_service.dart';
import '../cubit/auth_cubit.dart';
import '../models/auth_model.dart';
import '../../main/views/main_view.dart';

/// 로그인 화면
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _autoLogin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 저장된 로그인 정보 불러오기
  Future<void> _loadSavedCredentials() async {
    try {
      final username = await StorageService.getUsername();
      final autoLogin = await StorageService.getAutoLogin();

      if (mounted) {
        setState(() {
          if (username != null) {
            _userIdController.text = username;
          }
          _autoLogin = autoLogin;
        });
      }
    } catch (e) {
      // 저장된 정보 불러오기 실패해도 계속 진행
    }
  }

  /// 로그인 수행
  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // FCM 토큰 가져오기
      final fcmToken = await _getFCMToken();

      // 로그인 요청
      final authCubit = context.read<AuthCubit>();
      final result = await authCubit.login(
        userId: _userIdController.text.trim(),
        password: _passwordController.text,
        autoLogin: _autoLogin,
        fcmToken: fcmToken,
      );

      if (mounted) {
        if (result.isSuccess) {
          // 로그인 성공 시 메인 화면으로 이동
          _navigateToMain(result.username ?? _userIdController.text.trim());
        } else {
          // 로그인 실패 시 에러 메시지 표시 - reportError 사용
          ErrorReporter.reportError(
            context,
            result.errorMessage ?? '로그인에 실패했습니다.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // 예외 발생 시 - reportError 사용
        ErrorReporter.reportError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// FCM 토큰 가져오기
  Future<String> _getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token ?? '';
    } catch (e) {
      return '';
    }
  }

  /// 메인 화면으로 이동
  void _navigateToMain(String username) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainView(username: username),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  /// 회원가입 화면으로 이동
  void _navigateToRegister() {
    // 회원가입 기능 준비중 메시지
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('회원가입 기능 준비중입니다.'),
        backgroundColor: AppColors.yellow2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // 앱 로고
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.sky3,
                    ),
                    child: const Icon(
                      Icons.sailing,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 앱 타이틀
                const Text(
                  'VMS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sky3,
                  ),
                ),

                const Text(
                  'Vessel Management System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.gray2,
                  ),
                ),

                const SizedBox(height: 50),

                // 아이디 입력
                TextFormField(
                  controller: _userIdController,
                  decoration: InputDecoration(
                    labelText: '아이디',
                    hintText: '아이디를 입력하세요',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gray4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.sky3),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '아이디를 입력해주세요';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // 비밀번호 입력
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '비밀번호를 입력하세요',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gray4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.sky3),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _performLogin(),
                ),

                const SizedBox(height: 16),

                // 자동 로그인 체크박스
                Row(
                  children: [
                    Checkbox(
                      value: _autoLogin,
                      onChanged: (value) {
                        setState(() {
                          _autoLogin = value ?? false;
                        });
                      },
                      activeColor: AppColors.sky3,
                    ),
                    const Text('자동 로그인'),
                  ],
                ),

                const SizedBox(height: 30),

                // 로그인 버튼
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _performLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sky3,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 회원가입 링크
                TextButton(
                  onPressed: _navigateToRegister,
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: AppColors.gray2),
                      children: [
                        TextSpan(text: '아직 계정이 없으신가요? '),
                        TextSpan(
                          text: '회원가입',
                          style: TextStyle(
                            color: AppColors.sky3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 버전 정보
                const Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.gray13,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}