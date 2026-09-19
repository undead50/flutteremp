import 'package:relay/core/security/input_sanitizer.dart';

/// Form validators. Each returns a user-facing message, or `null` when valid.
///
/// Client-side validation is a UX aid only; the backend must re-validate every
/// value it receives.
abstract final class Validators {
  static const int maxEmailLength = 254;
  static const int maxEmailLocalLength = 64;
  static const int maxPasswordLength = 128;
  static const int minCommentLength = 3;
  static const int maxCommentLength = 500;

  static final RegExp _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  static String? email(String? raw) {
    final value = InputSanitizer.email(raw);
    if (value.isEmpty) return 'Enter your work email.';
    final at = value.indexOf('@');
    if (value.length > maxEmailLength ||
        at < 1 ||
        at > maxEmailLocalLength ||
        !_email.hasMatch(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Login only checks presence and length. Complexity rules belong to the
  /// identity provider; enforcing them here would also leak the policy.
  static String? password(String? raw) {
    if (raw == null || raw.isEmpty) return 'Enter your password.';
    if (raw.length > maxPasswordLength) return 'Password is too long.';
    return null;
  }

  static String? feedbackComment(String? raw) {
    final value = InputSanitizer.multiLine(raw, maxLength: maxCommentLength + 1);
    if (value.length < minCommentLength) {
      return 'Add a short note (at least $minCommentLength characters).';
    }
    if (value.length > maxCommentLength) {
      return 'Keep the note under $maxCommentLength characters.';
    }
    return null;
  }
}

/// Identifiers taken from deep links or API payloads are allow-listed before
/// they are placed into a request path (prevents path traversal / injection).
abstract final class SafeId {
  static final RegExp _pattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static bool isValid(String? value) => value != null && _pattern.hasMatch(value);
}
