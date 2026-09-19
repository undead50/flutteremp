import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/domain/repositories/settings_repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores preferences in `SharedPreferences`. They are UI toggles, not
/// secrets, so platform secure storage is deliberately reserved for tokens.
///
/// Stored values are treated as untrusted: anything unrecognised falls back to
/// its default instead of crashing (e.g. after a downgrade or manual edit).
final class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl(this._prefs);

  static const String _appearance = 'pref.appearance';
  static const String _textSize = 'pref.text_size';
  static const String _haptic = 'pref.haptic_on_approval';
  static const String _contrast = 'pref.high_contrast';
  static const String _biometric = 'pref.biometric_recheck';
  static const String _modules = 'pref.active_modules';

  final SharedPreferences _prefs;

  @override
  UserPreferences load() {
    const defaults = UserPreferences.defaults;

    final appearance =
        AppearanceMode.values.asNameMap()[_readString(_appearance)] ?? defaults.appearance;

    final textSize = TextSizePreset.values.asNameMap()[_readString(_textSize)] ?? defaults.textSize;

    final storedModules = _readStringList(_modules);
    final modules = storedModules == null
        ? defaults.activeModules
        : storedModules
              .map((name) => WorkspaceModule.values.asNameMap()[name])
              .whereType<WorkspaceModule>()
              .toSet();

    return UserPreferences(
      appearance: appearance,
      textSize: textSize,
      hapticOnApproval: _readBool(_haptic) ?? defaults.hapticOnApproval,
      highContrast: _readBool(_contrast) ?? defaults.highContrast,
      biometricRecheck: _readBool(_biometric) ?? defaults.biometricRecheck,
      activeModules: modules.isEmpty ? defaults.activeModules : modules,
    );
  }

  @override
  Future<void> save(UserPreferences preferences) async {
    await Future.wait(<Future<bool>>[
      _prefs.setString(_appearance, preferences.appearance.name),
      _prefs.setString(_textSize, preferences.textSize.name),
      _prefs.setBool(_haptic, preferences.hapticOnApproval),
      _prefs.setBool(_contrast, preferences.highContrast),
      _prefs.setBool(_biometric, preferences.biometricRecheck),
      _prefs.setStringList(
        _modules,
        preferences.activeModules.map((m) => m.name).toList(growable: false),
      ),
    ]);
  }

  // `get` returns Object?; a wrongly typed value must not throw.
  String? _readString(String key) {
    final value = _prefs.get(key);
    return value is String ? value : null;
  }

  bool? _readBool(String key) {
    final value = _prefs.get(key);
    return value is bool ? value : null;
  }

  List<String>? _readStringList(String key) {
    final value = _prefs.get(key);
    return value is List<Object?> ? value.whereType<String>().toList(growable: false) : null;
  }
}
