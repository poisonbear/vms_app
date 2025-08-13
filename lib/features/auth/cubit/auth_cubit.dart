import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_model.dart';
import '../repositories/auth_repository.dart';

part 'auth_state.dart';

/// 인증 관련 비즈니스 로직을 처리하는 Cubit
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository repository,
  }) : _repository = repository, super(const AuthState());

  final AuthRepository _repository;

  /// 로그인
  Future<LoginResult> login({
    required String userId,
    required String password,
    bool autoLogin = false,
    String? fcmToken,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      final loginRequest = LoginRequest(
        userId: '${userId.trim()}@kdn.vms.com',
        password: password.trim(),
        autoLogin: autoLogin,
        fcmToken: fcmToken,
      );

      final result = await _repository.login(loginRequest);

      if (result.isSuccess) {
        emit(state.copyWith(
          user: result.user,
          isAuthenticated: true,
          isLoading: false,
          errorMessage: '',
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result.errorMessage ?? '로그인에 실패했습니다.',
        ));
      }

      return result;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '로그인 중 오류가 발생했습니다: $e',
      ));
      return LoginResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 자동 로그인
  Future<LoginResult> autoLogin({
    required String token,
    required String fcmToken,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.autoLogin(
        token: token,
        fcmToken: fcmToken,
      );

      if (result.isSuccess) {
        emit(state.copyWith(
          user: result.user,
          isAuthenticated: true,
          isLoading: false,
          errorMessage: '',
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result.errorMessage ?? '자동 로그인에 실패했습니다.',
        ));
      }

      return result;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '자동 로그인 중 오류가 발생했습니다: $e',
      ));
      return LoginResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 회원가입
  Future<RegisterResult> register(RegisterRequest request) async {
    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.register(request);

      emit(state.copyWith(
        isLoading: false,
        errorMessage: result.isSuccess ? '' : result.errorMessage ?? '회원가입에 실패했습니다.',
      ));

      return result;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '회원가입 중 오류가 발생했습니다: $e',
      ));
      return RegisterResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 아이디 중복 확인
  Future<bool> checkUserIdAvailability(String userId) async {
    try {
      return await _repository.checkUserIdAvailability(userId);
    } catch (e) {
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      await _repository.logout();
      emit(const AuthState());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '로그아웃 중 오류가 발생했습니다: $e',
      ));
    }
  }

  /// 사용자 정보 업데이트
  void updateUser(UserModel user) {
    emit(state.copyWith(user: user));
  }

  /// 에러 메시지 초기화
  void clearError() {
    emit(state.copyWith(errorMessage: ''));
  }
}

/// 로그인 결과
class LoginResult extends Equatable {
  const LoginResult({
    required this.isSuccess,
    this.user,
    this.username,
    this.errorMessage,
  });

  final bool isSuccess;
  final UserModel? user;
  final String? username;
  final String? errorMessage;

  @override
  List<Object?> get props => [isSuccess, user, username, errorMessage];
}

/// 회원가입 결과
class RegisterResult extends Equatable {
  const RegisterResult({
    required this.isSuccess,
    this.errorMessage,
  });

  final bool isSuccess;
  final String? errorMessage;

  @override
  List<Object?> get props => [isSuccess, errorMessage];
}