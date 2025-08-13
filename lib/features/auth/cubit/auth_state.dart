part of 'auth_cubit.dart';

/// 인증 상태
class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage = '',
  });

  /// 사용자 정보
  final UserModel? user;

  /// 인증 여부
  final bool isAuthenticated;

  /// 로딩 상태
  final bool isLoading;

  /// 에러 메시지
  final String errorMessage;

  /// 상태 복사 메소드
  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [user, isAuthenticated, isLoading, errorMessage];
}