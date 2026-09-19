@Tags(<String>['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/app/router/route_paths.dart';
import 'package:relay/app/router/app_router.dart';

import '../helpers/test_harness.dart';

/// Renders each screen at the exact size of its Figma frame and writes a PNG to
/// `build/design_check/`, so the implementation can be compared with the design
/// by eye. It asserts nothing about pixels (fonts/rasterisation differ per
/// platform), which is why it lives behind the `screenshots` tag.
Future<void> _save(WidgetTester tester, GlobalKey key, String name, {double pixelRatio = 1}) async {
  final bytes = await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('build/design_check/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  for (final mode in <String>['light', 'dark']) {
    final suffix = mode == 'light' ? '' : '_dark';
    final prefs = <String, Object>{'pref.appearance': mode};

    testWidgets('welcome (390x893) $mode', (tester) async {
      final key = GlobalKey();
      final harness = await TestHarness.create(preferences: prefs);
      await pumpRelayApp(tester, harness, size: const Size(390, 893), boundaryKey: key);
      await _save(tester, key, '1_welcome$suffix');
    });

    testWidgets('login (390x958) $mode', (tester) async {
      final key = GlobalKey();
      final harness = await TestHarness.create(preferences: prefs);
      final container = await pumpRelayApp(
        tester,
        harness,
        size: const Size(390, 958),
        boundaryKey: key,
      );
      // ignore: unawaited_futures
      container.read(routerProvider).push(RoutePaths.login);
      await settle(tester);
      await _save(tester, key, '2_login$suffix');
    });

    testWidgets('memos feed (390x1898) $mode', (tester) async {
      final key = GlobalKey();
      final harness = await TestHarness.create(signedIn: true, preferences: prefs);
      await pumpRelayApp(tester, harness, size: const Size(390, 1898), boundaryKey: key);
      await _save(tester, key, '3_memos$suffix');
    });

    testWidgets('memo detail (390x3008) $mode', (tester) async {
      final key = GlobalKey();
      final harness = await TestHarness.create(signedIn: true, preferences: prefs);
      final container = await pumpRelayApp(
        tester,
        harness,
        size: const Size(390, 3008),
        boundaryKey: key,
      );
      // ignore: unawaited_futures
      container.read(routerProvider).push(RoutePaths.memoDetail('hardware-q3'));
      await settle(tester);
      await _save(tester, key, '4_detail$suffix');
    });

    testWidgets('settings (390x2400) $mode', (tester) async {
      final key = GlobalKey();
      final harness = await TestHarness.create(signedIn: true, preferences: prefs);
      final container = await pumpRelayApp(
        tester,
        harness,
        size: const Size(390, 2400),
        boundaryKey: key,
      );
      container.read(routerProvider).go(RoutePaths.settings);
      await settle(tester);
      await _save(tester, key, '5_settings$suffix');
    });
  }
}
