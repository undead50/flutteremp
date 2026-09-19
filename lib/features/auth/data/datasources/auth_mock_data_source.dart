import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/security/token_store.dart';
import 'package:relay/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:relay/features/auth/data/dtos/auth_dtos.dart';
import 'package:relay/features/auth/domain/entities/user_profile.dart';

/// Offline stand-in for the auth API (dev builds with `USE_MOCK_BACKEND=true`
/// and tests). Contains no real credentials: any well-formed email with a
/// password of at least [minPasswordLength] characters signs in as Elena.
final class AuthMockDataSource implements AuthRemoteDataSource {
  AuthMockDataSource({this.latency = const Duration(milliseconds: 700)});

  static const int minPasswordLength = 8;

  final Duration latency;

  static const UserProfile elena = UserProfile(
    id: 'usr_elena_vance',
    displayName: 'Elena Vance',
    title: 'VP Operations',
    department: 'Relay Core',
    level: 'Staff Level 9',
    employeeCode: '#8942-EV',
    signedMemoCount: 9,
    avatar: '${AppImages.assetScheme}${AppImages.avatarElena}',
  );

  static const AuthTokens _tokens = AuthTokens(
    accessToken: 'mock-access-token',
    refreshToken: 'mock-refresh-token',
  );

  Future<void> _delay() => Future<void>.delayed(latency);

  @override
  Future<AuthGrant> login({required String email, required String password}) async {
    await _delay();
    if (password.length < minPasswordLength) {
      throw const AppException(InvalidCredentialsFailure());
    }
    return const AuthGrant(tokens: _tokens, user: elena);
  }

  @override
  Future<AuthGrant> loginWithSso() async {
    await _delay();
    return const AuthGrant(tokens: _tokens, user: elena);
  }

  @override
  Future<UserProfile> fetchProfile() async {
    await _delay();
    return elena;
  }

  @override
  Future<void> logout() async {}
}
