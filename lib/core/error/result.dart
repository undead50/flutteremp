import 'package:relay/core/error/failure.dart';

/// Outcome of an operation that can fail in an expected way.
///
/// Domain and data layers return [Result] instead of throwing, so the UI is
/// forced (by the compiler, via exhaustive `switch`) to handle failures.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = Err<T>;

  R when<R>({required R Function(T value) success, required R Function(Failure failure) failure}) =>
      switch (this) {
        Success<T>(:final value) => success(value),
        Err<T>(failure: final f) => failure(f),
      };

  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Err<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Err<T>(:final failure) => failure,
  };

  bool get isSuccess => this is Success<T>;

  /// Unwraps the value or throws an [AppException] (used inside AsyncNotifiers,
  /// where `AsyncValue.error` is the natural carrier of a failure).
  T getOrThrow() => switch (this) {
    Success<T>(:final value) => value,
    Err<T>(:final failure) => throw AppException(failure),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
