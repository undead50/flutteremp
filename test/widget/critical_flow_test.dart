import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../flows/critical_flow.dart';
import '../helpers/test_harness.dart';

void main() {
  testWidgets(
    'critical flow: welcome -> sign in -> feed -> detail -> approve -> settings -> sign out',
    (tester) async {
      final harness = await TestHarness.create();
      await pumpRelayApp(tester, harness, size: const Size(390, 2400));

      await runCriticalFlow(tester, () => settle(tester));

      // Side effects that must have happened along the way.
      expect(harness.memoSource.decisions.single.memoId, 'hybrid-workplace');
      expect(harness.biometrics.reasons, hasLength(1), reason: 'approval was step-up verified');
      expect(await harness.tokens.read(), isNull, reason: 'sign-out wiped the stored credentials');
    },
  );
}
