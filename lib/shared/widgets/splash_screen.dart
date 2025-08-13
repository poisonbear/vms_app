import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/services/storage_service.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/error_reporter.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/main/views/main_view.dart';

/// 개선된 스플래시 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  bool _isInitializing = false;
  bool _hasNavigated = false;
  String _statusMessage = '앱을 시작하는 중...';

  // 타임아웃 설정
  static const Duration _initializationTimeout = Duration(seconds: 15);
  static const Duration _minimumSplashDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _safeInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitializing = false;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 다시 활성화될 때 초기화가 완료되지 않았다면 재시도
    if (state == AppLifecycleState.resumed &&
        !_hasNavigated &&
        !_isInitializing) {
      _safeInitialize();
    }
  }

  /// 안전한 초기화 수행
  Future<void> _safeInitialize() async {
    if (_isInitializing || _hasNavigated || !mounted) return;

    _isInitializing = true;
    final startTime = DateTime.now();

    try {
      _updateStatus('초기화 중...');

      // 타임아웃과 함께 초기화 수행
      await Future.any([
        _performInitialization(),
        Future.delayed(_initializationTimeout).then((_) =>
        throw TimeoutException('초기화 시간 초과', _initializationTimeout)),
      ]);

      // 최소 스플래시 시간 보장
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime < _minimumSplashDuration) {
        await Future.delayed(_minimumSplashDuration - elapsedTime);
      }

    } catch (e) {
      if (mounted) {
        _handleInitializationError(e);
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// 실제 초기화 로직 수행
  Future<void> _performInitialization() async {
    try {
      // 1. 저장된 인증 정보 확인
      _updateStatus('인증 정보 확인 중...');
      final authInfo = await _getStoredAuthInfo();

      // 2. FCM 토큰 가져오기
      _updateStatus('알림 설정 확인 중...');
      final fcmToken = await _getFCMToken();

      // 3. 자동 로그인 시도
      if (authInfo.hasValidToken && authInfo.autoLoginEnabled) {
        _updateStatus('자동 로그인 중...');
        final result = await _attemptAutoLogin(authInfo.token!, fcmToken);

        if (result.isSuccess && mounted) {
          await _navigateToMain(result.username ?? authInfo.username ?? '사용자');
          return;
        } else {
          // 자동 로그인 실패 시 설정 해제
          await StorageService.saveAutoLogin(false);
        }
      }

      // 4. 로그인 화면으로 이동
      if (mounted) {
        await _navigateToLogin();
      }

    } catch (e) {
      rethrow;
    }
  }

  /// 저장된 인증 정보 가져오기
  Future<_AuthInfo> _getStoredAuthInfo() async {
    final results = await Future.wait([
      StorageService.getFirebaseToken(),
      StorageService.getAutoLogin(),
      StorageService.getUsername(),
    ]);

    return _AuthInfo(
      token: results[0] as String?,
      autoLoginEnabled: results[1] as bool,
      username: results[2] as String?,
    );
  }

  /// FCM 토큰 가져오기
  Future<String> _getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token ?? '';
    } catch (e) {
      // FCM 토큰 가져오기 실패해도 계속 진행
      return '';
    }
  }

  /// 자동 로그인 시도
  Future<LoginResult> _attemptAutoLogin(String token, String fcmToken) async {
    if (!mounted) {
      return const LoginResult(isSuccess: false, errorMessage: 'Widget disposed');
    }

    try {
      final authCubit = context.read<AuthCubit>();
      return await authCubit.autoLogin(token: token, fcmToken: fcmToken);
    } catch (e) {
      return LoginResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  /// 메인 화면으로 이동
  Future<void> _navigateToMain(String username) async {
    if (_hasNavigated || !mounted) return;

    _hasNavigated = true;
    _updateStatus('로그인 완료');

    await Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainView(username: username),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// 로그인 화면으로 이동
  Future<void> _navigateToLogin() async {
    if (_hasNavigated || !mounted) return;

    _hasNavigated = true;
    _updateStatus('로그인 화면으로 이동');

    await Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const LoginView(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// 초기화 에러 처리
  void _handleInitializationError(dynamic error) {
    final appException = ErrorHandler.handleError(error);

    _updateStatus('초기화 실패');

    // 에러 리포팅
    ErrorReporter.reportError(context, appException, showSnackBar: false);

    // 사용자에게 에러 다이얼로그 표시
    _showErrorDialog(appException);
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(dynamic error) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('초기화 오류'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '앱 초기화 중 오류가 발생했습니다.\n${ErrorHandler.getUserFriendlyMessage(error)}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _retryInitialization();
              },
              child: const Text('다시 시도'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _forceNavigateToLogin();
              },
              child: const Text('로그인 화면으로'),
            ),
          ],
        );
      },
    );
  }

  /// 초기화 재시도
  void _retryInitialization() {
    if (mounted) {
      setState(() {
        _hasNavigated = false;
        _statusMessage = '다시 시도하는 중...';
      });
      _safeInitialize();
    }
  }

  /// 강제로 로그인 화면으로 이동
  void _forceNavigateToLogin() {
    if (mounted && !_hasNavigated) {
      _navigateToLogin();
    }
  }

  /// 상태 메시지 업데이트
  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 로고 또는 아이콘
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).primaryColor,
                ),
                child: const Icon(
                  Icons.sailing,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              // 앱 이름
              Text(
                'VMS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),

              Text(
                'Vessel Management System',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 60),

              // 로딩 인디케이터
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),

              const SizedBox(height: 20),

              // 상태 메시지
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusMessage,
                  key: ValueKey(_statusMessage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 100),

              // 버전 정보 (선택적)
              Text(
                'v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 인증 정보 저장용 헬퍼 클래스
class _AuthInfo {
  final String? token;
  final bool autoLoginEnabled;
  final String? username;

  const _AuthInfo({
    required this.token,
    required this.autoLoginEnabled,
    required this.username,
  });

  bool get hasValidToken => token != null && token!.isNotEmpty;
}

/// 타임아웃 예외
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (${timeout.inSeconds}s)';
}