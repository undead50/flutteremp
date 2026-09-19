import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/platform/haptics.dart';
import 'package:relay/core/providers/core_providers.dart';
import 'package:relay/features/settings/data/datasources/settings_remote_data_source.dart';
import 'package:relay/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:relay/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:relay/features/settings/domain/entities/sign_off_proxy.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/domain/repositories/settings_repositories.dart';
import 'package:relay/features/settings/domain/usecases/settings_usecases.dart';

// ── Data wiring ───────────────────────────────────────────────────────────

final Provider<PreferencesRepository> preferencesRepositoryProvider =
    Provider<PreferencesRepository>(
      (ref) => PreferencesRepositoryImpl(ref.watch(sharedPreferencesProvider)),
    );

final Provider<SettingsRemoteDataSource> settingsRemoteDataSourceProvider =
    Provider<SettingsRemoteDataSource>(
      (ref) => ref.watch(appConfigProvider).useMockBackend
          ? SettingsMockDataSource()
          : SettingsRemoteDataSourceImpl(ref.watch(dioProvider)),
    );

final Provider<SettingsRepository> settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(
    remote: ref.watch(settingsRemoteDataSourceProvider),
    logger: ref.watch(loggerProvider),
  ),
);

final Provider<OutboxRepository> outboxRepositoryProvider = Provider<OutboxRepository>(
  (ref) => const NoopOutboxRepository(),
);

final Provider<Haptics> hapticsProvider = Provider<Haptics>((ref) => const SystemHaptics());

// ── Use cases ─────────────────────────────────────────────────────────────

final Provider<UpdatePreferences> updatePreferencesProvider = Provider<UpdatePreferences>(
  (ref) => UpdatePreferences(ref.watch(preferencesRepositoryProvider)),
);

final Provider<GetSignOffProxy> getSignOffProxyProvider = Provider<GetSignOffProxy>(
  (ref) => GetSignOffProxy(ref.watch(settingsRepositoryProvider)),
);

final Provider<SyncOutbox> syncOutboxProvider = Provider<SyncOutbox>(
  (ref) => SyncOutbox(ref.watch(outboxRepositoryProvider)),
);

final Provider<GetOutboxCount> getOutboxCountProvider = Provider<GetOutboxCount>(
  (ref) => GetOutboxCount(ref.watch(outboxRepositoryProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────

/// Live user preferences. Drives text scale, contrast, haptics, the biometric
/// re-check and which feed filters are visible.
final NotifierProvider<PreferencesController, UserPreferences> preferencesControllerProvider =
    NotifierProvider<PreferencesController, UserPreferences>(PreferencesController.new);

class PreferencesController extends Notifier<UserPreferences> {
  @override
  UserPreferences build() => ref.read(preferencesRepositoryProvider).load();

  Future<Result<UserPreferences>> _apply(UserPreferences next) async {
    final result = await ref.read(updatePreferencesProvider)(next);
    if (result case Success<UserPreferences>(:final value)) state = value;
    return result;
  }

  Future<void> setAppearance(AppearanceMode mode) => _apply(state.copyWith(appearance: mode));

  Future<void> setTextSize(TextSizePreset preset) => _apply(state.copyWith(textSize: preset));

  Future<void> setHapticOnApproval({required bool enabled}) =>
      _apply(state.copyWith(hapticOnApproval: enabled));

  Future<void> setHighContrast({required bool enabled}) =>
      _apply(state.copyWith(highContrast: enabled));

  Future<void> setBiometricRecheck({required bool enabled}) =>
      _apply(state.copyWith(biometricRecheck: enabled));

  /// Returns the failure when the change is refused (e.g. last module).
  Future<Failure?> setModule(WorkspaceModule module, {required bool enabled}) async {
    final modules = <WorkspaceModule>{...state.activeModules};
    if (enabled) {
      modules.add(module);
    } else {
      modules.remove(module);
    }
    final result = await _apply(state.copyWith(activeModules: modules));
    return result.failureOrNull;
  }
}

/// Configured sign-off proxy for the settings card.
final FutureProvider<SignOffProxy?> signOffProxyProvider =
    FutureProvider.autoDispose<SignOffProxy?>(
      (ref) async => (await ref.watch(getSignOffProxyProvider)()).getOrThrow(),
    );

/// Number of queued offline actions.
final FutureProvider<int> outboxCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(getOutboxCountProvider)(),
);

/// Whether an outbox sync is running.
final NotifierProvider<OutboxSyncController, bool> outboxSyncControllerProvider =
    NotifierProvider.autoDispose<OutboxSyncController, bool>(OutboxSyncController.new);

class OutboxSyncController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<Result<int>> sync() async {
    if (state) return const Result<int>.success(0);
    final link = ref.keepAlive();
    state = true;
    try {
      final result = await ref.read(syncOutboxProvider)();
      ref.invalidate(outboxCountProvider);
      return result;
    } finally {
      if (ref.mounted) state = false;
      link.close();
    }
  }
}
