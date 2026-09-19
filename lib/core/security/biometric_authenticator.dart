import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';

/// Local (on-device) user presence check.
///
/// This is *friction*, not authorization: a compromised device can bypass it.
/// Anything that must be enforced (e.g. step-up before a sign-off) has to be
/// enforced again by the backend.
abstract interface class BiometricAuthenticator {
  Future<bool> isAvailable();

  Future<Result<void>> authenticate({required String reason});
}

final class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  LocalAuthBiometricAuthenticator({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<Result<void>> authenticate({required String reason}) async {
    try {
      final ok = await _auth.authenticate(localizedReason: reason);
      return ok
          ? const Result<void>.success(null)
          : const Result<void>.failure(BiometricCancelledFailure());
    } on LocalAuthException catch (e) {
      return Result<void>.failure(_map(e.code));
    } on PlatformException {
      return const Result<void>.failure(BiometricUnavailableFailure());
    }
  }

  Failure _map(LocalAuthExceptionCode code) => switch (code) {
    LocalAuthExceptionCode.userCanceled ||
    LocalAuthExceptionCode.systemCanceled ||
    LocalAuthExceptionCode.timeout ||
    LocalAuthExceptionCode.userRequestedFallback => const BiometricCancelledFailure(),
    LocalAuthExceptionCode.noCredentialsSet ||
    LocalAuthExceptionCode.noBiometricsEnrolled ||
    LocalAuthExceptionCode.noBiometricHardware ||
    LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
      const BiometricUnavailableFailure(),
    LocalAuthExceptionCode.temporaryLockout ||
    LocalAuthExceptionCode.biometricLockout => const BiometricLockedFailure(),
    _ => const UnknownFailure(),
  };
}
