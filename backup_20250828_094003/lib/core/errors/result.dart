/// Result 패턴 - 성공 또는 실패를 명시적으로 표현
sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get data => isSuccess ? (this as Success<T, E>).value : null;
  E? get error => isFailure ? (this as Failure<T, E>).exception : null;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onFailure,
  }) {
    if (this is Success<T, E>) {
      return onSuccess((this as Success<T, E>).value);
    } else {
      return onFailure((this as Failure<T, E>).exception);
    }
  }
}

class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

class Failure<T, E> extends Result<T, E> {
  final E exception;
  const Failure(this.exception);
}
