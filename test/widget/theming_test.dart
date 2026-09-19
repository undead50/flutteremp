import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/app/router/app_router.dart';
import 'package:relay/app/router/route_paths.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_theme.dart';
import 'package:relay/core/widgets/relay_button.dart';
import 'package:relay/core/widgets/svg_asset.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/presentation/providers/settings_providers.dart';
import 'package:relay/features/settings/presentation/screens/settings_screen.dart';

import '../helpers/test_harness.dart';

const Size _tall = Size(390, 2600);

Future<void> _tap(WidgetTester tester, String text) async {
  final finder = find.text(text).first;
  await Scrollable.ensureVisible(finder.evaluate().first, alignment: 0.5, duration: Duration.zero);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(SettingsScreen))).brightness;

void main() {
  group('Appearance setting', () {
    testWidgets('defaults to System and follows the device in both directions', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      final harness = await TestHarness.create(signedIn: true);
      final container = await pumpRelayApp(tester, harness, size: _tall);
      container.read(routerProvider).go(RoutePaths.settings);
      await settle(tester);

      expect(container.read(preferencesControllerProvider).appearance, AppearanceMode.system);
      expect(_brightness(tester), Brightness.light);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await settle(tester);
      expect(_brightness(tester), Brightness.dark, reason: 'System mode tracks the OS live');

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await settle(tester);
      expect(_brightness(tester), Brightness.light);
    });

    testWidgets('Dark and Light override the device setting and are remembered', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      final harness = await TestHarness.create(signedIn: true);
      final container = await pumpRelayApp(tester, harness, size: _tall);
      container.read(routerProvider).go(RoutePaths.settings);
      await settle(tester);

      await _tap(tester, 'Dark');
      expect(_brightness(tester), Brightness.dark);
      expect(harness.prefs.getString('pref.appearance'), 'dark');
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).extension<AppPalette>()!.isDark,
        isTrue,
      );

      // The device is dark, but the user explicitly chose Light.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await _tap(tester, 'Light');
      expect(_brightness(tester), Brightness.light);
      expect(harness.prefs.getString('pref.appearance'), 'light');

      await _tap(tester, 'System');
      expect(_brightness(tester), Brightness.dark, reason: 'back to following the (dark) device');
      expect(harness.prefs.getString('pref.appearance'), 'system');
    });

    testWidgets('the saved choice is applied from the very first screen', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      final harness = await TestHarness.create(
        signedIn: true,
        preferences: <String, Object>{'pref.appearance': 'dark'},
      );
      await pumpRelayApp(tester, harness, size: _tall);

      expect(find.text('Pending Decision Feed'), findsOneWidget);
      final palette = Theme.of(tester.element(find.text('Pending Decision Feed')))
          .extension<AppPalette>()!;
      expect(palette.isDark, isTrue);
    });

    testWidgets('the segment for the current mode is exposed as selected', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      final container = await pumpRelayApp(tester, harness, size: _tall);
      container.read(routerProvider).go(RoutePaths.settings);
      await settle(tester);

      final semantics = tester.getSemantics(find.bySemanticsLabel('System'));
      expect(semantics.getSemanticsData().flagsCollection.isSelected.toBoolOrNull(), isTrue);
    });

    testWidgets('screens render without layout errors in dark mode', (tester) async {
      final harness = await TestHarness.create(
        signedIn: true,
        preferences: <String, Object>{'pref.appearance': 'dark'},
      );
      final container = await pumpRelayApp(tester, harness, size: _tall);
      for (final path in <String>[
        RoutePaths.memos,
        RoutePaths.memoDetail('hardware-q3'),
        RoutePaths.settings,
        RoutePaths.login,
      ]) {
        container.read(routerProvider).go(path);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: path);
      }
    });
  });

  group('SvgAsset dark tinting', () {
    Future<ColorFilter?> filterFor(WidgetTester tester, ThemeData theme, Widget icon) async {
      await pumpWidgetInApp(tester, Center(child: icon), theme: theme);
      await tester.pump();
      return tester.widget<SvgPicture>(find.byType(SvgPicture)).colorFilter;
    }

    testWidgets('a toned icon keeps its exported colour in light mode', (tester) async {
      final filter = await filterFor(
        tester,
        AppTheme.light(),
        const SvgAsset(AppIcons.headerSearch),
      );
      expect(filter, isNull);
    });

    testWidgets('the same icon is tinted with its palette role in dark mode', (tester) async {
      final filter = await filterFor(
        tester,
        AppTheme.dark(),
        const SvgAsset(AppIcons.headerSearch),
      );
      expect(filter, ColorFilter.mode(AppPalette.dark.onSurfaceVariant, BlendMode.srcIn));
    });

    testWidgets('multi-colour marks are never tinted, in either theme', (tester) async {
      for (final theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
        expect(await filterFor(tester, theme, const SvgAsset(AppIcons.loginGoogle)), isNull);
        expect(await filterFor(tester, theme, const SvgAsset(AppIcons.logoMark)), isNull);
      }
    });

    testWidgets('an explicit colour always wins over the registry', (tester) async {
      final filter = await filterFor(
        tester,
        AppTheme.dark(),
        const SvgAsset(AppIcons.navMemos, color: Colors.red),
      );
      expect(filter, const ColorFilter.mode(Colors.red, BlendMode.srcIn));
    });
  });

  group('Theme-aware components', () {
    testWidgets('a primary button resolves fill and label from the active palette', (tester) async {
      for (final p in <AppPalette>[AppPalette.light, AppPalette.dark]) {
        await pumpWidgetInApp(
          tester,
          Center(
            child: RelayButton(label: 'Go', onPressed: () {}),
          ),
          theme: p.isDark ? AppTheme.dark() : AppTheme.light(),
        );
        await tester.pumpAndSettle(); // let the theme cross-fade finish
        final fill = tester
            .widgetList<DecoratedBox>(
              find.descendant(of: find.byType(RelayButton), matching: find.byType(DecoratedBox)),
            )
            .map((d) => (d.decoration as BoxDecoration).color)
            .whereType<Color>()
            .first;
        expect(fill, p.primary, reason: p.isDark ? 'dark' : 'light');
        expect(tester.widget<Text>(find.text('Go')).style!.color, p.onPrimary);
      }
    });

    testWidgets('text without an explicit colour is readable in both themes', (tester) async {
      for (final theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
        await pumpWidgetInApp(tester, const Center(child: Text('plain')), theme: theme);
        await tester.pumpAndSettle(); // let the theme cross-fade finish
        final ctx = tester.element(find.text('plain'));
        final color = DefaultTextStyle.of(ctx).style.color;
        expect(color, theme.extension<AppPalette>()!.onSurface);
      }
    });
  });
}
