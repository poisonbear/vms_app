import 'package:vms_app/core/exceptions/app_exceptions.dart';

sealed class Result<T, E extends AppException> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get dataOrNull => isSuccess ? (this as Success<T, E>).data : null;
  E? get errorOrNull => isFailure ? (this as Failure<T, E>).error : null;

  /// 성공 시 변환
  Result<R, E> map<R>(R Function(T) mapper) {
    if (this is Success<T, E>) {
      return Success(mapper((this as Success<T, E>).data));
    }
    return Failure((this as Failure<T, E>).error);
  }

  /// 성공 시 비동기 변환
  Future<Result<R, E>> mapAsync<R>(Future<R> Function(T) mapper) async {
    if (this is Success<T, E>) {
      try {
        final result = await mapper((this as Success<T, E>).data);
        return Success(result);
      } catch (e) {
        return Failure(
          (e is E ? e : BusinessException(e.toString())) as E,
        );
      }
    }
    return Failure((this as Failure<T, E>).error);
  }

  /// fold 패턴
  R fold<R>({
    required R Function(T) onSuccess,
    required R Function(E) onFailure,
  }) {
    if (this is Success<T, E>) {
      return onSuccess((this as Success<T, E>).data);
    }
    return onFailure((this as Failure<T, E>).error);
  }

  /// 성공 시 실행
  void onSuccess(void Function(T) action) {
    if (this is Success<T, E>) {
      action((this as Success<T, E>).data);
    }
  }

  /// 실패 시 실행
  void onFailure(void Function(E) action) {
    if (this is Failure<T, E>) {
      action((this as Failure<T, E>).error);
    }
  }
}

/// 성공 결과
class Success<T, E extends AppException> extends Result<T, E> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// 실패 결과
class Failure<T, E extends AppException> extends Result<T, E> {
  final E error;

  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';
}

/// 하위 호환성을 위한 단일 타입 파라미터 Result (Deprecated)
@Deprecated('Use Result<T, AppException> instead')
typedef SimpleResult<T> = Result<T, AppException>;
