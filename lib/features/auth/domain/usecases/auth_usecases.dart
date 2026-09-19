import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/security/biometric_authenticator.dart';
import 'package:relay/core/security/input_sanitizer.dart';
import 'package:relay/core/security/validators.dart';
import 'package:relay/features/auth/domain/entities/user_profile.dart';
import 'package:relay/features/auth/domain/repositories/auth_repository.dart';

/// Email + password sign-in. Re-validates and sanitises the input even though
/// the form already did: the use case must be safe regardless of its caller.
final class SignInWithCredentials {
  const SignInWithCredentials(this._repository);

  final AuthRepository _repository;

  Future<Result<UserProfile>> call({required String email, required String password}) {
    if (Validators.email(email) != null || Validators.password(password) != null) {
      return Future<Result<UserProfile>>.value(
        const Result<UserProfile>.failure(ValidationFailure()),
      );
    }
    return _repository.signInWithCredentials(
      email: InputSanitizer.email(email),
      password: password,
    );
  }
}

final class SignInWithSso {
  const SignInWithSso(this._repository);

  final AuthRepository _repository;

  Future<Result<UserProfile>> call() => _repository.signInWithSso();
}

final class RestoreSession {
  const RestoreSession(this._repository);

  final AuthRepository _repository;

  Future<Result<UserProfile>> call() => _repository.restoreSession();
}

/// Face ID / fingerprint unlock. It never signs anyone in from scratch: it only
/// lets the device owner resume a session whose refresh token is already in
/// secure storage, and the backend still validates that session.
final class QuickUnlock {
  const QuickUnlock({
    required AuthRepository repository,
    required BiometricAuthenticator biometrics,
  }) : _repository = repository,
       _biometrics = biometrics;

  final AuthRepository _repository;
  final BiometricAuthenticator _biometrics;

  Future<Result<UserProfile>> call() async {
    if (!await _repository.hasStoredSession()) {
      return const Result<UserProfile>.failure(NoStoredSessionFailure());
    }
    final check = await _biometrics.authenticate(reason: 'Unlock your Relay workspace');
    if (check case Err<void>(:final failure)) return Result<UserProfile>.failure(failure);
    return _repository.restoreSession();
  }
}

final class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
