import 'package:flutter_test/flutter_test.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/domain/repositories/settings_repositories.dart';
import 'package:relay/features/settings/domain/usecases/settings_usecases.dart';
import 'package:relay/features/settings/presentation/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_harness.dart';

class _CountingRepository implements PreferencesRepository {
  int saves = 0;

  @override
  UserPreferences load() => UserPreferences.defaults;

  @override
  Future<void> save(UserPreferences preferences) async => saves++;
}

Future<PreferencesRepositoryImpl> _repoWith(Map<String, Object> stored) async {
  SharedPreferences.setMockInitialValues(stored);
  return PreferencesRepositoryImpl(await SharedPreferences.getInstance());
}

void main() {
  appearanceTests();

  group('PreferencesRepositoryImpl', () {
    test('defaults when nothing is stored', () async {
      final repo = await _repoWith(<String, Object>{});
      expect(repo.load(), UserPreferences.defaults);
    });

    test('round-trips every setting', () async {
      final repo = await _repoWith(<String, Object>{});
      const changed = UserPreferences(
        textSize: TextSizePreset.extraLarge,
        hapticOnApproval: false,
        highContrast: true,
        biometricRecheck: false,
        activeModules: <WorkspaceModule>{WorkspaceModule.teamLeave, WorkspaceModule.executiveMemos},
      );
      await repo.save(changed);
      expect(repo.load(), changed);
    });

    test('corrupted or tampered values fall back to defaults instead of crashing', () async {
      final repo = await _repoWith(<String, Object>{
        'pref.text_size': 'gigantic',
        'pref.haptic_on_approval': 'yes',
        'pref.high_contrast': 1,
        'pref.active_modules': <String>['bogus', 'also-bogus'],
      });
      expect(repo.load(), UserPreferences.defaults);
    });

    test('unknown module names are ignored but valid ones survive', () async {
      final repo = await _repoWith(<String, Object>{
        'pref.active_modules': <String>['teamLeave', 'nope'],
      });
      expect(repo.load().activeModules, <WorkspaceModule>{WorkspaceModule.teamLeave});
    });
  });

  group('UpdatePreferences (use case)', () {
    test('refuses to deactivate the last module and does not persist', () async {
      final repo = _CountingRepository();
      final result = await UpdatePreferences(repo)(
        UserPreferences.defaults.copyWith(activeModules: const <WorkspaceModule>{}),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, 'Keep at least one module active.');
      expect(repo.saves, 0);
    });

    test('persists a valid change', () async {
      final repo = _CountingRepository();
      final result = await UpdatePreferences(repo)(
        UserPreferences.defaults.copyWith(highContrast: true),
      );
      expect(result.valueOrNull?.highContrast, isTrue);
      expect(repo.saves, 1);
    });
  });

  group('PreferencesController', () {
    test('applies text size, contrast and toggles, and survives a restart', () async {
      final harness = await TestHarness.create();
      final container = harness.container();
      final controller = container.read(preferencesControllerProvider.notifier);

      await controller.setTextSize(TextSizePreset.large);
      await controller.setHighContrast(enabled: true);
      await controller.setHapticOnApproval(enabled: false);

      final state = container.read(preferencesControllerProvider);
      expect(state.textSize, TextSizePreset.large);
      expect(state.highContrast, isTrue);
      expect(state.hapticOnApproval, isFalse);

      // "Restart": a fresh container over the same storage.
      final restarted = harness.container();
      expect(restarted.read(preferencesControllerProvider).textSize, TextSizePreset.large);
    });

    test('the last active module cannot be switched off', () async {
      final harness = await TestHarness.create();
      final container = harness.container();
      final controller = container.read(preferencesControllerProvider.notifier);

      expect(await controller.setModule(WorkspaceModule.expenseApprovals, enabled: false), isNull);
      expect(await controller.setModule(WorkspaceModule.teamLeave, enabled: false), isNull);
      expect(await controller.setModule(WorkspaceModule.policyRevisions, enabled: false), isNull);

      final refused = await controller.setModule(WorkspaceModule.executiveMemos, enabled: false);
      expect(refused, isA<ValidationFailure>());
      expect(container.read(preferencesControllerProvider).activeModules, <WorkspaceModule>{
        WorkspaceModule.executiveMemos,
      });
    });

    test('text scale presets multiply, never shrink, the system scale', () {
      expect(TextSizePreset.standard.scale, 1);
      expect(TextSizePreset.large.scale, greaterThan(1));
      expect(TextSizePreset.extraLarge.scale, greaterThan(TextSizePreset.large.scale));
    });
  });

  group('Outbox and sign-off proxy', () {
    test('the outbox is empty and syncing delivers nothing', () async {
      final harness = await TestHarness.create();
      final container = harness.container();
      expect(await container.read(outboxCountProvider.future), 0);
      final result = await container.read(outboxSyncControllerProvider.notifier).sync();
      expect(result.valueOrNull, 0);
      expect(container.read(outboxSyncControllerProvider), isFalse);
    });

    test('the mock proxy resolves', () async {
      final harness = await TestHarness.create();
      final container = harness.container();
      final proxy = await container.read(signOffProxyProvider.future);
      expect(proxy?.name, 'Marcus Brody');
    });
  });
}

void appearanceTests() {
  group('Appearance preference', () {
    test('defaults to following the system', () {
      expect(UserPreferences.defaults.appearance, AppearanceMode.system);
    });

    test('round-trips through storage', () async {
      final repo = await _repoWith(<String, Object>{});
      for (final mode in AppearanceMode.values) {
        await repo.save(UserPreferences.defaults.copyWith(appearance: mode));
        expect(repo.load().appearance, mode);
      }
    });

    test('a corrupted stored value falls back to System', () async {
      final repo = await _repoWith(<String, Object>{'pref.appearance': 'sepia'});
      expect(repo.load().appearance, AppearanceMode.system);
      final wrongType = await _repoWith(<String, Object>{'pref.appearance': 3});
      expect(wrongType.load().appearance, AppearanceMode.system);
    });

    test('the controller applies and persists a change', () async {
      final harness = await TestHarness.create();
      final container = harness.container();
      await container
          .read(preferencesControllerProvider.notifier)
          .setAppearance(AppearanceMode.dark);
      expect(container.read(preferencesControllerProvider).appearance, AppearanceMode.dark);
      expect(harness.prefs.getString('pref.appearance'), 'dark');
      // Other preferences are untouched.
      expect(container.read(preferencesControllerProvider).textSize, TextSizePreset.standard);
    });
  });
}
