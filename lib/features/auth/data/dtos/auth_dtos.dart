import 'package:relay/core/network/json_reader.dart';
import 'package:relay/core/security/https_url.dart';
import 'package:relay/core/security/token_store.dart';
import 'package:relay/features/auth/domain/entities/user_profile.dart';

/// Wire format of a user, parsed defensively from untrusted JSON.
final class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.displayName,
    required this.title,
    required this.department,
    required this.level,
    required this.employeeCode,
    required this.signedMemoCount,
    this.avatarUrl,
  });

  factory UserProfileDto.fromJson(JsonObject json) => UserProfileDto(
    id: json.string('id', maxLength: 64),
    displayName: json.string('displayName', maxLength: 80),
    title: json.optString('title', maxLength: 80) ?? '',
    department: json.optString('department', maxLength: 80) ?? '',
    level: json.optString('level', maxLength: 40) ?? '',
    employeeCode: json.optString('employeeCode', maxLength: 24) ?? '',
    signedMemoCount: json.optInt('signedMemoCount', max: 1000000) ?? 0,
    // Only https images are accepted; anything else is dropped, not fetched.
    avatarUrl: parseHttpsImageUrl(json.optString('avatarUrl', maxLength: 2048))?.toString(),
  );

  final String id;
  final String displayName;
  final String title;
  final String department;
  final String level;
  final String employeeCode;
  final int signedMemoCount;
  final String? avatarUrl;

  UserProfile toEntity() => UserProfile(
    id: id,
    displayName: displayName,
    title: title,
    department: department,
    level: level,
    employeeCode: employeeCode,
    signedMemoCount: signedMemoCount,
    avatar: avatarUrl,
  );
}

/// Successful authentication: a token pair plus the user it belongs to.
final class AuthGrant {
  const AuthGrant({required this.tokens, required this.user});

  factory AuthGrant.fromJson(JsonObject json) => AuthGrant(
    tokens: AuthTokens(
      accessToken: json.string('accessToken', maxLength: 8192),
      refreshToken: json.string('refreshToken', maxLength: 8192),
    ),
    user: UserProfileDto.fromJson(json.object('user')).toEntity(),
  );

  final AuthTokens tokens;
  final UserProfile user;
}
