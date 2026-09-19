import 'package:relay/core/error/failure.dart';
import 'package:relay/core/security/input_sanitizer.dart';

/// Defensive accessor around a decoded JSON object.
///
/// API payloads are untrusted input (OWASP A08): every field is type-checked,
/// length-limited and sanitised. Anything missing or of the wrong type raises a
/// [MalformedResponseException] that the repository maps to a safe failure,
/// instead of a `null` dereference or `type 'X' is not a subtype of 'Y'` crash.
final class JsonObject {
  JsonObject(Object? raw, {String field = 'root'}) : _map = _asMap(raw, field), _path = field;

  final Map<String, Object?> _map;
  final String _path;

  static const int _defaultMaxText = 500;

  static Map<String, Object?> _asMap(Object? raw, String field) {
    if (raw is Map<Object?, Object?>) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    throw MalformedResponseException(field);
  }

  /// Parses a list of objects, refusing lists longer than [maxItems].
  static List<JsonObject> list(Object? raw, {required String field, int maxItems = 200}) {
    if (raw is! List<Object?> || raw.length > maxItems) {
      throw MalformedResponseException(field);
    }
    return <JsonObject>[
      for (var i = 0; i < raw.length; i++) JsonObject(raw[i], field: '$field[$i]'),
    ];
  }

  String _key(String key) => '$_path.$key';

  bool has(String key) => _map[key] != null;

  String string(String key, {int maxLength = _defaultMaxText}) {
    final value = optString(key, maxLength: maxLength);
    if (value == null || value.isEmpty) throw MalformedResponseException(_key(key));
    return value;
  }

  String? optString(String key, {int maxLength = _defaultMaxText}) {
    final raw = _map[key];
    if (raw == null) return null;
    if (raw is! String) throw MalformedResponseException(_key(key));
    return InputSanitizer.singleLine(raw, maxLength: maxLength);
  }

  /// Long-form text that may contain line breaks.
  String? optParagraph(String key, {int maxLength = 4000}) {
    final raw = _map[key];
    if (raw == null) return null;
    if (raw is! String) throw MalformedResponseException(_key(key));
    return InputSanitizer.multiLine(raw, maxLength: maxLength);
  }

  int integer(String key, {int min = 0, int max = 1 << 40}) {
    final value = optInt(key, min: min, max: max);
    if (value == null) throw MalformedResponseException(_key(key));
    return value;
  }

  int? optInt(String key, {int min = 0, int max = 1 << 40}) {
    final raw = _map[key];
    if (raw == null) return null;
    if (raw is! int || raw < min || raw > max) throw MalformedResponseException(_key(key));
    return raw;
  }

  bool boolean(String key, {bool? fallback}) {
    final raw = _map[key];
    if (raw is bool) return raw;
    if (raw == null && fallback != null) return fallback;
    throw MalformedResponseException(_key(key));
  }

  DateTime dateTime(String key) {
    final raw = _map[key];
    final parsed = raw is String ? DateTime.tryParse(raw) : null;
    if (parsed == null) throw MalformedResponseException(_key(key));
    return parsed.toUtc();
  }

  DateTime? optDateTime(String key) => has(key) ? dateTime(key) : null;

  JsonObject object(String key) => JsonObject(_map[key], field: _key(key));

  JsonObject? optObject(String key) => has(key) ? object(key) : null;

  List<JsonObject> objects(String key, {int maxItems = 200}) =>
      list(_map[key], field: _key(key), maxItems: maxItems);

  List<JsonObject> optObjects(String key, {int maxItems = 200}) =>
      has(key) ? objects(key, maxItems: maxItems) : const <JsonObject>[];

  /// Maps a wire string to an enum value. Unknown values throw unless
  /// [fallback] is given (use it for forward-compatible, non-critical enums).
  T enumValue<T extends Enum>(String key, List<T> values, {T? fallback}) {
    final raw = _map[key];
    if (raw is String) {
      for (final value in values) {
        if (value.name == raw) return value;
      }
    }
    if (fallback != null) return fallback;
    throw MalformedResponseException(_key(key));
  }
}
