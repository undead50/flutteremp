import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/app/relay_app.dart';
import 'package:relay/core/config/app_config.dart';
import 'package:relay/core/providers/core_providers.dart';
import 'package:relay/core/security/token_store.dart';
import 'package:relay/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:relay/features/auth/presentation/providers/auth_providers.dart';
import 'package:relay/features/memos/data/datasources/memo_mock_data_source.dart';
import 'package:relay/features/memos/presentation/providers/memo_providers.dart';
import 'package:relay/features/settings/data/datasources/settings_remote_data_source.dart';
import 'package:relay/features/settings/presentation/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Tuesday 24 Oct 2023, 09:41: matches the "Tue, Oct 24 / Good morning" copy
/// in the Figma frames and keeps relative times ("45m ago") deterministic.
final DateTime testNow = DateTime(2023, 10, 24, 9, 41);

/// Everything a test may want to inspect or tweak.
class TestHarness {
  TestHarness({
    required this.prefs,
    required this.tokens,
    required this.biometrics,
    required this.haptics,
    required this.memoSource,
  });

  final SharedPreferences prefs;
  final InMemoryTokenStore tokens;
  final FakeBiometricAuthenticator biometrics;
  final RecordingHaptics haptics;
  final ProgrammableMemoDataSource memoSource;
  final RecordingLinkLauncher links = RecordingLinkLauncher();

  /// Creates a harness with zero-latency mock data sources and an in-memory
  /// token store. Pass [signedIn] to start with a restorable session.
  static Future<TestHarness> create({
    bool signedIn = false,
    Map<String, Object> preferences = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(preferences);
    final tokens = InMemoryTokenStore();
    if (signedIn) {
      await tokens.write(
        const AuthTokens(accessToken: 'test-access', refreshToken: 'test-refresh'),
      );
    }
    return TestHarness(
      prefs: await SharedPreferences.getInstance(),
      tokens: tokens,
      biometrics: FakeBiometricAuthenticator(),
      haptics: RecordingHaptics(),
      memoSource: ProgrammableMemoDataSource(
        MemoMockDataSource(clock: () => testNow, latency: Duration.zero),
      ),
    );
  }

  List<Override> get overrides => <Override>[
    appConfigProvider.overrideWithValue(const AppConfig.mock()),
    sharedPreferencesProvider.overrideWithValue(prefs),
    tokenStoreProvider.overrideWithValue(tokens),
    clockProvider.overrideWithValue(() => testNow),
    idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
    biometricAuthenticatorProvider.overrideWithValue(biometrics),
    externalLinkLauncherProvider.overrideWithValue(links),
    hapticsProvider.overrideWithValue(haptics),
    authRemoteDataSourceProvider.overrideWithValue(AuthMockDataSource(latency: Duration.zero)),
    memoRemoteDataSourceProvider.overrideWithValue(memoSource),
    settingsRemoteDataSourceProvider.overrideWithValue(
      SettingsMockDataSource(latency: Duration.zero),
    ),
  ];

  /// A container for pure controller/use-case tests (no widgets).
  ProviderContainer container() {
    final container = ProviderContainer(overrides: overrides, retry: (count, error) => null);
    addTearDown(container.dispose);
    return container;
  }
}

/// Runs real async work (asset decoding) and pumps frames until things settle.
Future<void> settle(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

/// Mounts the whole app at a phone-sized (or custom) viewport.
Future<ProviderContainer> pumpRelayApp(
  WidgetTester tester,
  TestHarness harness, {
  Size size = const Size(390, 844),
  EdgeInsets padding = EdgeInsets.zero,
  GlobalKey? boundaryKey,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..padding = FakeViewPadding(top: padding.top, bottom: padding.bottom)
    ..viewPadding = FakeViewPadding(top: padding.top, bottom: padding.bottom);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      retry: (count, error) => null,
      overrides: harness.overrides,
      child: RepaintBoundary(key: boundaryKey, child: const RelayApp()),
    ),
  );
  await settle(tester);
  return ProviderScope.containerOf(tester.element(find.byType(RelayApp)));
}

/// Mounts a single widget inside the app theme (for widget-level tests).
Future<void> pumpWidgetInApp(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  List<Override> overrides = const <Override>[],
  ThemeData? theme,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      retry: (count, error) => null,
      overrides: overrides,
      child: MaterialApp(
        theme: theme,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}
