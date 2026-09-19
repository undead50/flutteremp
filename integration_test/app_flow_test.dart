import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/flows/critical_flow.dart';
import '../test/helpers/test_harness.dart';

/// End-to-end run of the critical path on a real engine (device, simulator or
/// desktop). It boots the *real* `RelayApp` + router + providers against the
/// offline mock backend, so it needs no network and no credentials:
///
///     flutter test integration_test --dart-define-from-file=config/dev.json
///
/// The exact same steps also run headless in
/// `test/widget/critical_flow_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'critical flow: welcome -> sign in -> feed -> detail -> approve -> settings -> sign out',
    (tester) async {
      final harness = await TestHarness.create();
      await pumpRelayApp(tester, harness, size: const Size(390, 2400));

      await runCriticalFlow(tester, () async {
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      });

      expect(harness.memoSource.decisions.single.memoId, 'hybrid-workplace');
      expect(await harness.tokens.read(), isNull);
    },
  );
}
