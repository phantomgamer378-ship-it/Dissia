import 'app_error.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
    Success<T> s => s.value,
    Failure<T> _ => null,
  };

  AppError? get errorOrNull => switch (this) {
    Success<T> _ => null,
    Failure<T> f => f.error,
  };

  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) =>
      switch (this) {
        Success<T> s => success(s.value),
        Failure<T> f => failure(f.error),
      };
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}
