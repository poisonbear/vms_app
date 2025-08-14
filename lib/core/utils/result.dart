/// 함수형 프로그래밍 스타일의 Result 타입
sealed class Result<T> {
  const Result();

  /// 성공 케이스
  const factory Result.success(T data) = Success<T>;

  /// 실패 케이스
  const factory Result.failure(Exception error) = Failure<T>;

  /// 성공 여부 확인
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// 데이터 접근 (성공 시에만)
  T? get data => switch (this) {
    Success<T> success => success.data,
    Failure<T> _ => null,
  };

  /// 에러 접근 (실패 시에만)
  Exception? get error => switch (this) {
    Success<T> _ => null,
    Failure<T> failure => failure.error,
  };

  /// 값 변환
  Result<R> map<R>(R Function(T) transform) => switch (this) {
    Success<T> success => Result.success(transform(success.data)),
    Failure<T> failure => Result.failure(failure.error),
  };

  /// 비동기 값 변환
  Future<Result<R>> mapAsync<R>(Future<R> Function(T) transform) async {
    return switch (this) {
      Success<T> success => Result.success(await transform(success.data)),
      Failure<T> failure => Result.failure(failure.error),
    };
  }

  /// 에러 처리
  Result<T> mapError(Exception Function(Exception) transform) {
    return switch (this) {
      Success<T> success => success,
      Failure<T> failure => Result.failure(transform(failure.error)),
    };
  }

  /// 값이 있을 때만 실행
  Result<T> when({
    Function(T)? success,
    Function(Exception)? failure,
  }) {
    switch (this) {
      case Success<T> s:
        success?.call(s.data);
        break;
      case Failure<T> f:
        failure?.call(f.error);
        break;
    }
    return this;
  }

  /// 값 언래핑 (실패 시 기본값 반환)
  T getOrElse(T defaultValue) => data ?? defaultValue;

  /// 값 언래핑 (실패 시 예외 발생)
  T getOrThrow() => switch (this) {
    Success<T> success => success.data,
    Failure<T> failure => throw failure.error,
  };
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Success<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final Exception error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Failure<T> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}

// 확장 함수들
extension FutureResultExtension<T> on Future<T> {
  /// Future를 Result로 래핑
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (error) {
      if (error is Exception) {
        return Result.failure(error);
      } else {
        return Result.failure(Exception(error.toString()));
      }
    }
  }
}

extension ResultListExtension<T> on List<Result<T>> {
  /// 모든 Result가 성공인지 확인
  bool get allSuccess => every((result) => result.isSuccess);

  /// 성공한 결과들만 추출
  List<T> get successes =>
      where((result) => result.isSuccess)
          .map((result) => result.data!)
          .toList();

  /// 실패한 결과들만 추출
  List<Exception> get failures =>
      where((result) => result.isFailure)
          .map((result) => result.error!)
          .toList();
}