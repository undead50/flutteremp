import 'package:relay/core/error/result.dart';
import 'package:relay/features/settings/domain/entities/sign_off_proxy.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';

/// Device-local, non-sensitive UI preferences.
abstract interface class PreferencesRepository {
  /// Synchronous: preferences are loaded into memory before the app starts so
  /// text scale and contrast are correct on the first frame.
  UserPreferences load();

  Future<void> save(UserPreferences preferences);
}

abstract interface class SettingsRepository {
  /// `null` when no proxy is configured.
  Future<Result<SignOffProxy?>> getSignOffProxy();
}

/// Queue of actions taken offline that still need to reach the backend.
abstract interface class OutboxRepository {
  Future<int> pendingCount();

  /// Returns how many queued items were delivered.
  Future<Result<int>> sync();
}
