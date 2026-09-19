/// Normalises text that comes from users or from the API before it is stored,
/// sent, or rendered (OWASP A05 Injection, A08 Integrity).
///
/// The app never renders HTML or builds queries from this text, but stripping
/// control and bidirectional-override characters still prevents log forging,
/// header injection and visual spoofing (e.g. a right-to-left override that
/// reverses an amount or a name).
///
/// The character classes are built from code points at runtime on purpose: the
/// source file itself must never contain invisible or bidi characters.
abstract final class InputSanitizer {
  static String _class(List<(int, int)> ranges) =>
      ranges.map((r) => '${String.fromCharCode(r.$1)}-${String.fromCharCode(r.$2)}').join();

  /// C0 controls (except tab, LF, CR) and DEL.
  static final RegExp _control = RegExp(
    '[${_class(<(int, int)>[(0x00, 0x08), (0x0B, 0x0C), (0x0E, 0x1F), (0x7F, 0x7F)])}]',
  );

  /// Zero-width characters, bidi embeddings/overrides/isolates and the BOM.
  static final RegExp _invisible = RegExp(
    '[${_class(<(int, int)>[(0x200B, 0x200F), (0x202A, 0x202E), (0x2060, 0x2064), (0x2066, 0x2069), (0xFEFF, 0xFEFF)])}]',
  );

  static final RegExp _spaces = RegExp('[ \\t\\r\\n${String.fromCharCode(0xA0)}]+');
  static final RegExp _inlineSpaces = RegExp('[ \\t${String.fromCharCode(0xA0)}]+');
  static final RegExp _blankLines = RegExp(r'\n{3,}');

  /// Single-line text: no control/invisible characters, collapsed whitespace.
  static String singleLine(String? input, {int maxLength = 200}) {
    if (input == null) return '';
    final cleaned = input
        .replaceAll(_control, '')
        .replaceAll(_invisible, '')
        .replaceAll(_spaces, ' ')
        .trim();
    return _clamp(cleaned, maxLength);
  }

  /// Multi-line text: like [singleLine] but keeps single/double line breaks.
  static String multiLine(String? input, {int maxLength = 1000}) {
    if (input == null) return '';
    final cleaned = input
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_control, '')
        .replaceAll(_invisible, '')
        .replaceAll(_inlineSpaces, ' ')
        .replaceAll(_blankLines, '\n\n')
        .trim();
    return _clamp(cleaned, maxLength);
  }

  /// Emails are compared case-insensitively. Only the ends are trimmed: an
  /// address with interior spaces must stay invalid rather than being silently
  /// "repaired" into a different, valid address.
  static String email(String? input) {
    if (input == null) return '';
    final cleaned = input.replaceAll(_control, '').replaceAll(_invisible, '').trim().toLowerCase();
    return _clamp(cleaned, 254);
  }

  /// Clamps by code point so a surrogate pair is never split.
  static String _clamp(String value, int maxLength) {
    final runes = value.runes;
    if (runes.length <= maxLength) return value;
    return String.fromCharCodes(runes.take(maxLength));
  }
}
