import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/logging/app_logger.dart';
import 'package:relay/core/network/guarded_call.dart';
import 'package:relay/core/security/token_store.dart';
import 'package:relay/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:relay/features/auth/domain/entities/user_profile.dart';
import 'package:relay/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStore tokens,
    required AppLogger logger,
  }) : _remote = remote,
       _tokens = tokens,
       _logger = logger;

  final AuthRemoteDataSource _remote;
  final TokenStore _tokens;
  final AppLogger _logger;

  @override
  Future<Result<UserProfile>> signInWithCredentials({
    required String email,
    required String password,
  }) {
    return guardedCall(() async {
      final grant = await _remote.login(email: email, password: password);
      await _tokens.write(grant.tokens);
      return grant.user;
    }, _logger);
  }

  @override
  Future<Result<UserProfile>> signInWithSso() {
    return guardedCall(() async {
      final grant = await _remote.loginWithSso();
      await _tokens.write(grant.tokens);
      return grant.user;
    }, _logger);
  }

  @override
  Future<Result<UserProfile>> restoreSession() async {
    if (await _tokens.read() == null) {
      return const Result<UserProfile>.failure(UnauthorizedFailure());
    }
    final result = await guardedCall(_remote.fetchProfile, _logger);
    // The backend rejected the stored session: it is useless, so remove it.
    if (result.failureOrNull is UnauthorizedFailure) await _tokens.clear();
    return result;
  }

  @override
  Future<bool> hasStoredSession() async => await _tokens.read() != null;

  @override
  Future<void> signOut() async {
    try {
      await _remote.logout();
    } on Object catch (e) {
      // Offline sign-out must still succeed locally.
      _logger.debug('Remote logout failed (${e.runtimeType})');
    } finally {
      await _tokens.clear();
    }
  }
}
