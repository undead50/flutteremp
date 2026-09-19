import 'package:relay/core/error/result.dart';
import 'package:relay/features/auth/domain/entities/user_profile.dart';

/// Contract between the auth use cases and whatever backend serves them.
/// Implementations own token persistence; callers only ever see a profile.
abstract interface class AuthRepository {
  Future<Result<UserProfile>> signInWithCredentials({
    required String email,
    required String password,
  });

  /// Enterprise SSO (Google / Okta). The identity provider flow is owned by
  /// the backend integration.
  Future<Result<UserProfile>> signInWithSso();

  /// Validates any stored session against the backend and returns its user.
  Future<Result<UserProfile>> restoreSession();

  Future<bool> hasStoredSession();

  /// Revokes the session server-side (best effort) and always wipes local
  /// credentials, even if the network call fails.
  Future<void> signOut();
}
