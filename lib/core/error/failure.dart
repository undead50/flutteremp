/// A user-safe description of what went wrong.
///
/// [message] is always a static, human-readable string. It must never be built
/// from server payloads, exception text, tokens or user input, so it can be
/// shown in the UI and written to logs without leaking anything (OWASP A09).
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType';
}

final class NetworkFailure extends Failure {
  const NetworkFailure() : super('You appear to be offline. Check your connection and try again.');
}

final class InsecureConnectionFailure extends Failure {
  const InsecureConnectionFailure()
    : super("We couldn't establish a secure connection. Please try again.");
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure() : super('The request took too long. Please try again.');
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Your session has expired. Please sign in again.');
}

final class InvalidCredentialsFailure extends Failure {
  // Deliberately generic: never reveal whether the email or the password was wrong.
  const InvalidCredentialsFailure() : super('Email or password is incorrect.');
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure() : super("You don't have permission to do that.");
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure() : super("We couldn't find what you were looking for.");
}

final class ConflictFailure extends Failure {
  const ConflictFailure() : super('This item was already updated. Refresh and try again.');
}

final class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Some details need attention. Check your input and try again.',
  ]);
}

final class RateLimitedFailure extends Failure {
  const RateLimitedFailure() : super('Too many attempts. Please wait a moment and try again.');
}

final class ServerFailure extends Failure {
  const ServerFailure() : super('Something went wrong on our side. Please try again shortly.');
}

final class MalformedResponseFailure extends Failure {
  const MalformedResponseFailure() : super('We received an unexpected response. Please try again.');
}

final class NotConfiguredFailure extends Failure {
  const NotConfiguredFailure() : super("This option isn't available for your workspace yet.");
}

final class NoStoredSessionFailure extends Failure {
  const NoStoredSessionFailure() : super('Sign in with your password once to enable quick unlock.');
}

final class BiometricCancelledFailure extends Failure {
  const BiometricCancelledFailure() : super('Verification was cancelled.');
}

final class BiometricUnavailableFailure extends Failure {
  const BiometricUnavailableFailure()
    : super('Biometric verification is not available on this device.');
}

final class BiometricLockedFailure extends Failure {
  const BiometricLockedFailure()
    : super('Biometrics are temporarily locked. Use your device passcode.');
}

final class UnknownFailure extends Failure {
  const UnknownFailure() : super('Something went wrong. Please try again.');
}

/// Thrown by data sources; carries the [Failure] the repository should return.
final class AppException implements Exception {
  const AppException(this.failure);

  final Failure failure;

  @override
  String toString() => 'AppException(${failure.runtimeType})';
}

/// Thrown while parsing an API payload that is missing fields or has the wrong
/// shape. Only the *field name* is kept, never the offending value.
final class MalformedResponseException implements Exception {
  const MalformedResponseException(this.field);

  final String field;

  @override
  String toString() => 'MalformedResponseException($field)';
}
