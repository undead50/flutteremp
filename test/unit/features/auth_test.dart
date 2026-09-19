import 'package:flutter_test/flutter_test.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/logging/app_logger.dart';
import 'package:relay/core/security/token_store.dart';
import 'package:relay/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:relay/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:relay/features/auth/data/dtos/auth_dtos.dart';
import 'package:relay/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:relay/features/auth/domain/entities/user_profile.dart';
import 'package:relay/features/auth/domain/repositories/auth_repository.dart';
import 'package:relay/features/auth/domain/usecases/auth_usecases.dart';
import 'package:relay/features/auth/presentation/providers/auth_providers.dart';
import 'package:relay/features/auth/presentation/providers/login_controller.dart';
import 'package:relay/core/network/json_reader.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_harness.dart';

/// Scriptable auth backend.
class _FakeRemote implements AuthRemoteDataSource {
  Object? loginError;
  Object? profileError;
  Object? logoutError;
  int logoutCalls = 0;
  int profileCalls = 0;
  final List<({String email, String password})> logins = <({String email, String password})>[];

  static const AuthGrant grant = AuthGrant(
    tokens: AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    user: AuthMockDataSource.elena,
  );

  @override
  Future<AuthGrant> login({required String email, required String password}) async {
    logins.add((email: email, password: password));
    if (loginError case final error?) throw error;
    return grant;
  }

  @override
  Future<AuthGrant> loginWithSso() async => throw const AppException(NotConfiguredFailure());

  @override
  Future<UserProfile> fetchProfile() async {
    profileCalls++;
    if (profileError case final error?) throw error;
    return AuthMockDataSource.elena;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError case final error?) throw error;
  }
}

class _RecordingRepository implements AuthRepository {
  int signIns = 0;
  int restores = 0;
  String? lastEmail;
  bool hasSession = true;

  @override
  Future<Result<UserProfile>> signInWithCredentials({
    required String email,
    required String password,
  }) async {
    signIns++;
    lastEmail = email;
    return const Result<UserProfile>.success(AuthMockDataSource.elena);
  }

  @override
  Future<Result<UserProfile>> signInWithSso() async =>
      const Result<UserProfile>.failure(NotConfiguredFailure());

  @override
  Future<Result<UserProfile>> restoreSession() async {
    restores++;
    return const Result<UserProfile>.success(AuthMockDataSource.elena);
  }

  @override
  Future<bool> hasStoredSession() async => hasSession;

  @override
  Future<void> signOut() async {}
}

void main() {
  group('SignInWithCredentials (use case)', () {
    test('invalid input never reaches the repository', () async {
      final repo = _RecordingRepository();
      final useCase = SignInWithCredentials(repo);

      for (final args in <({String email, String password})>[
        (email: '', password: 'password1'),
        (email: 'not-an-email', password: 'password1'),
        (email: 'a@b.co', password: ''),
        (email: 'a@b.co', password: 'x' * 200),
      ]) {
        final result = await useCase(email: args.email, password: args.password);
        expect(
          result.failureOrNull,
          isA<ValidationFailure>(),
          reason: '${args.email}/${args.password.length}',
        );
      }
      expect(repo.signIns, 0);
    });

    test('normalises the email before sending it', () async {
      final repo = _RecordingRepository();
      await SignInWithCredentials(repo)(email: '  Elena@Company.COM ', password: 'password1');
      expect(repo.lastEmail, 'elena@company.com');
    });
  });

  group('QuickUnlock (use case)', () {
    test('does not even prompt when there is no stored session', () async {
      final repo = _RecordingRepository()..hasSession = false;
      final biometrics = FakeBiometricAuthenticator();

      final result = await QuickUnlock(repository: repo, biometrics: biometrics)();

      expect(result.failureOrNull, isA<NoStoredSessionFailure>());
      expect(biometrics.reasons, isEmpty);
      expect(repo.restores, 0);
    });

    test('a failed or cancelled biometric check never restores the session', () async {
      final repo = _RecordingRepository();
      final biometrics = FakeBiometricAuthenticator(
        outcome: const Result<void>.failure(BiometricCancelledFailure()),
      );

      final result = await QuickUnlock(repository: repo, biometrics: biometrics)();

      expect(result.failureOrNull, isA<BiometricCancelledFailure>());
      expect(repo.restores, 0);
    });

    test('a successful check restores the session via the backend', () async {
      final repo = _RecordingRepository();
      final result = await QuickUnlock(
        repository: repo,
        biometrics: FakeBiometricAuthenticator(),
      )();
      expect(result.valueOrNull, AuthMockDataSource.elena);
      expect(repo.restores, 1);
    });
  });

  group('AuthRepositoryImpl', () {
    late _FakeRemote remote;
    late InMemoryTokenStore tokens;
    late AuthRepositoryImpl repo;

    setUp(() {
      remote = _FakeRemote();
      tokens = InMemoryTokenStore();
      repo = AuthRepositoryImpl(
        remote: remote,
        tokens: tokens,
        logger: const AppLogger(verbose: false),
      );
    });

    test('sign-in persists tokens and returns the user', () async {
      final result = await repo.signInWithCredentials(email: 'a@b.co', password: 'password1');
      expect(result.valueOrNull?.displayName, 'Elena Vance');
      expect((await tokens.read())?.accessToken, 'access-1');
    });

    test('bad credentials keep the vague message and store nothing', () async {
      remote.loginError = const AppException(InvalidCredentialsFailure());
      final result = await repo.signInWithCredentials(email: 'a@b.co', password: 'wrong');
      expect(result.failureOrNull, isA<InvalidCredentialsFailure>());
      expect(await tokens.read(), isNull);
    });

    test('an unexpected exception becomes a generic failure, not a crash', () async {
      remote.loginError = StateError('boom: secret-db-password');
      final result = await repo.signInWithCredentials(email: 'a@b.co', password: 'password1');
      expect(result.failureOrNull, isA<UnknownFailure>());
      expect(result.failureOrNull!.message, isNot(contains('secret')));
    });

    test('a malformed payload maps to MalformedResponseFailure', () async {
      remote.loginError = const MalformedResponseException('user.id');
      final result = await repo.signInWithCredentials(email: 'a@b.co', password: 'password1');
      expect(result.failureOrNull, isA<MalformedResponseFailure>());
    });

    test('restore without tokens is Unauthorized and makes no network call', () async {
      final result = await repo.restoreSession();
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(remote.profileCalls, 0);
    });

    test('restore rejected by the backend wipes the stored tokens', () async {
      await tokens.write(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      remote.profileError = const AppException(UnauthorizedFailure());
      final result = await repo.restoreSession();
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(await tokens.read(), isNull);
    });

    test('an offline restore keeps the tokens so the user can retry', () async {
      await tokens.write(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      remote.profileError = const AppException(NetworkFailure());
      final result = await repo.restoreSession();
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(await tokens.read(), isNotNull);
    });

    test('sign-out always clears local credentials, even if the server call fails', () async {
      await tokens.write(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      remote.logoutError = const AppException(NetworkFailure());
      await repo.signOut();
      expect(remote.logoutCalls, 1);
      expect(await tokens.read(), isNull);
    });

    test('SSO without an identity provider fails safely', () async {
      final result = await repo.signInWithSso();
      expect(result.failureOrNull, isA<NotConfiguredFailure>());
      expect(await tokens.read(), isNull);
    });
  });

  group('AuthGrant / UserProfileDto parsing', () {
    Map<String, Object?> payload({Object? avatar = 'https://cdn.example/a.png'}) =>
        <String, Object?>{
          'accessToken': 'aaa',
          'refreshToken': 'bbb',
          'user': <String, Object?>{
            'id': 'u1',
            'displayName': 'Elena Vance',
            'title': 'VP Operations',
            'signedMemoCount': 9,
            'avatarUrl': avatar,
          },
        };

    test('parses a valid grant and defaults optional fields', () {
      final grant = AuthGrant.fromJson(JsonObject(payload()));
      expect(grant.user.displayName, 'Elena Vance');
      expect(grant.user.department, '');
      expect(grant.user.avatar, 'https://cdn.example/a.png');
    });

    test('drops non-https avatars instead of fetching them', () {
      for (final bad in <String>[
        'http://cdn.example/a.png',
        'file:///etc/passwd',
        'javascript:1',
      ]) {
        expect(
          AuthGrant.fromJson(JsonObject(payload(avatar: bad))).user.avatar,
          isNull,
          reason: bad,
        );
      }
    });

    test('rejects a grant without tokens or user', () {
      expect(
        () => AuthGrant.fromJson(JsonObject(<String, Object?>{'accessToken': 'a'})),
        throwsA(isA<MalformedResponseException>()),
      );
      expect(
        () => AuthGrant.fromJson(JsonObject(<String, Object?>{...payload(), 'user': 'nobody'})),
        throwsA(isA<MalformedResponseException>()),
      );
    });
  });

  group('SessionController + LoginController', () {
    test('starts signed out when nothing is stored', () async {
      final harness = await TestHarness.create();
      final container = harness.container();
      expect(await container.read(sessionControllerProvider.future), isNull);
    });

    test('restores a stored session', () async {
      final harness = await TestHarness.create(signedIn: true);
      final container = harness.container();
      final user = await container.read(sessionControllerProvider.future);
      expect(user?.displayName, 'Elena Vance');
    });

    test('empty fields produce inline errors and no request', () async {
      final harness = await TestHarness.create();
      final container = harness.container()..listen(loginControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);

      await container
          .read(loginControllerProvider.notifier)
          .submitCredentials(email: '', password: '');

      final state = container.read(loginControllerProvider);
      expect(state.emailError, 'Enter your work email.');
      expect(state.passwordError, 'Enter your password.');
      expect(state.isBusy, isFalse);
      expect(container.read(sessionControllerProvider).value, isNull);
    });

    test('valid credentials sign the user in', () async {
      final harness = await TestHarness.create();
      final container = harness.container()..listen(loginControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);

      await container
          .read(loginControllerProvider.notifier)
          .submitCredentials(email: 'elena@company.com', password: 'long-enough-1');

      expect(container.read(sessionControllerProvider).value?.displayName, 'Elena Vance');
      expect((await harness.tokens.read())?.accessToken, isNotEmpty);
      expect(container.read(loginControllerProvider).failure, isNull);
    });

    test('wrong credentials show one generic failure and do not sign in', () async {
      final harness = await TestHarness.create();
      final container = harness.container()..listen(loginControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);

      await container
          .read(loginControllerProvider.notifier)
          .submitCredentials(email: 'elena@company.com', password: 'short');

      expect(container.read(loginControllerProvider).failure, isA<InvalidCredentialsFailure>());
      expect(container.read(sessionControllerProvider).value, isNull);
      expect(await harness.tokens.read(), isNull);
    });

    test('five failures lock the form; further submits are ignored', () async {
      final harness = await TestHarness.create();
      final container = harness.container()..listen(loginControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);
      final controller = container.read(loginControllerProvider.notifier);

      for (var i = 0; i < LoginController.maxFailedAttempts; i++) {
        expect(container.read(loginControllerProvider).lockedOut, isFalse);
        await controller.submitCredentials(email: 'elena@company.com', password: 'short');
      }

      final locked = container.read(loginControllerProvider);
      expect(locked.lockedOut, isTrue);
      expect(locked.failure, isA<RateLimitedFailure>());

      // Even a correct password is refused while locked.
      await controller.submitCredentials(email: 'elena@company.com', password: 'long-enough-1');
      expect(container.read(sessionControllerProvider).value, isNull);
    });

    test('quick unlock without a stored session explains what to do', () async {
      final harness = await TestHarness.create();
      final container = harness.container()..listen(loginControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);

      await container.read(loginControllerProvider.notifier).quickUnlock();

      expect(container.read(loginControllerProvider).failure, isA<NoStoredSessionFailure>());
      expect(harness.biometrics.reasons, isEmpty);
    });

    test('SSO through the mock backend signs in (real backend: see repository test)', () async {
      final harness = await TestHarness.create();
      final container = harness.container()..listen(loginControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);

      await container.read(loginControllerProvider.notifier).signInWithSso();

      expect(container.read(sessionControllerProvider).value, isNotNull);
    });

    test('sign-out clears the session and the stored tokens', () async {
      final harness = await TestHarness.create(signedIn: true);
      final container = harness.container();
      await container.read(sessionControllerProvider.future);

      await container.read(sessionControllerProvider.notifier).signOut();

      expect(container.read(sessionControllerProvider).value, isNull);
      expect(await harness.tokens.read(), isNull);
    });
  });
}
