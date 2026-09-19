/// Relative paths of the backend contract this client speaks. All calls go to
/// the HTTPS base URL from [AppConfig]; nothing here is absolute.
abstract final class ApiEndpoints {
  static const String login = '/v1/auth/login';
  static const String refresh = '/v1/auth/refresh';
  static const String logout = '/v1/auth/logout';
  static const String me = '/v1/me';
  static const String signOffProxy = '/v1/me/sign-off-proxy';
  static const String memoFeed = '/v1/memos/feed';

  static String memo(String id) => '/v1/memos/${Uri.encodeComponent(id)}';

  static String memoDecision(String id) => '${memo(id)}/decisions';
}
