import 'dart:developer' as developer;

/// Minimal logger that is safe by construction (OWASP A09):
///
/// * only ever records the *type* of an error, never its message/payload,
/// * redacts anything that looks like an email, bearer token or JWT,
/// * `debug` output is dropped unless [verbose] is enabled (never in prod).
final class AppLogger {
  const AppLogger({required this.verbose});

  final bool verbose;

  void debug(String message) {
    if (verbose) _emit(500, message);
  }

  void warning(String message, {Object? error}) => _emit(900, _describe(message, error));

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _emit(1000, _describe(message, error), stackTrace: verbose ? stackTrace : null);

  static String _describe(String message, Object? error) =>
      error == null ? message : '$message (${error.runtimeType})';

  void _emit(int level, String message, {StackTrace? stackTrace}) {
    developer.log(redact(message), name: 'relay', level: level, stackTrace: stackTrace);
  }

  static final List<RegExp> _sensitive = <RegExp>[
    RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'),
    RegExp(r'bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
    RegExp(r'eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]*'),
    RegExp(r'[A-Za-z0-9_\-]{32,}'),
  ];

  /// Replaces likely secrets/PII with `[redacted]`.
  static String redact(String input) {
    var out = input;
    for (final pattern in _sensitive) {
      out = out.replaceAll(pattern, '[redacted]');
    }
    return out;
  }
}
