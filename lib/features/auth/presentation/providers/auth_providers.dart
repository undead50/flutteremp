import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/providers/core_providers.dart';
import 'package:relay/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:relay/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:relay/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:relay/features/auth/domain/entities/user_profile.dart';
import 'package:relay/features/auth/domain/repositories/auth_repository.dart';
import 'package:relay/features/auth/domain/usecases/auth_usecases.dart';

// ── Data wiring ───────────────────────────────────────────────────────────

final Provider<AuthRemoteDataSource> authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => ref.watch(appConfigProvider).useMockBackend
      ? AuthMockDataSource()
      : AuthRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokens: ref.watch(tokenStoreProvider),
    logger: ref.watch(loggerProvider),
  ),
);

// ── Use cases ─────────────────────────────────────────────────────────────

final Provider<SignInWithCredentials> signInWithCredentialsProvider =
    Provider<SignInWithCredentials>(
      (ref) => SignInWithCredentials(ref.watch(authRepositoryProvider)),
    );

final Provider<SignInWithSso> signInWithSsoProvider = Provider<SignInWithSso>(
  (ref) => SignInWithSso(ref.watch(authRepositoryProvider)),
);

final Provider<RestoreSession> restoreSessionProvider = Provider<RestoreSession>(
  (ref) => RestoreSession(ref.watch(authRepositoryProvider)),
);

final Provider<QuickUnlock> quickUnlockProvider = Provider<QuickUnlock>(
  (ref) => QuickUnlock(
    repository: ref.watch(authRepositoryProvider),
    biometrics: ref.watch(biometricAuthenticatorProvider),
  ),
);

final Provider<SignOut> signOutProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

// ── Session state ─────────────────────────────────────────────────────────

/// The signed-in user, as far as this device knows.
///
/// * `AsyncLoading`  - restoring a stored session at launch
/// * `AsyncData(null)` - signed out
/// * `AsyncData(user)` - signed in
///
/// The router uses this only to decide which screens to *show*. It is not an
/// authorization boundary: every API call is authorised by the backend.
final AsyncNotifierProvider<SessionController, UserProfile?> sessionControllerProvider =
    AsyncNotifierProvider<SessionController, UserProfile?>(SessionController.new);

/// Convenience: the current user or `null`.
final Provider<UserProfile?> currentUserProvider = Provider<UserProfile?>(
  (ref) => ref.watch(sessionControllerProvider).value,
);

class SessionController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final expiry = ref.watch(sessionEventsProvider).expired.listen((_) => _onExpired());
    ref.onDispose(expiry.cancel);

    final restored = await ref.read(restoreSessionProvider)();
    return restored.valueOrNull;
  }

  void signedIn(UserProfile user) => state = AsyncData<UserProfile?>(user);

  Future<void> signOut() async {
    await ref.read(signOutProvider)();
    state = const AsyncData<UserProfile?>(null);
  }

  void _onExpired() => state = const AsyncData<UserProfile?>(null);
}
