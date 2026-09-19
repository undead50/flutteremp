/// Every navigable location in one place.
abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';

  static const String memos = '/memos';
  static const String modules = '/modules';
  static const String activity = '/activity';
  static const String settings = '/settings';

  static const String memoIdParam = 'memoId';

  /// Detail route pattern (nested under [memos]).
  static const String memoDetailPattern = ':$memoIdParam';

  static String memoDetail(String id) => '$memos/${Uri.encodeComponent(id)}';
}
