import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/theme/app_theme.dart';
import 'package:relay/core/widgets/relay_avatar.dart';
import 'package:relay/core/widgets/relay_button.dart';
import 'package:relay/core/widgets/relay_card.dart';
import 'package:relay/core/widgets/relay_dialogs.dart';
import 'package:relay/core/widgets/relay_pill.dart';
import 'package:relay/core/widgets/relay_snackbar.dart';
import 'package:relay/core/widgets/relay_text_field.dart';
import 'package:relay/core/widgets/relay_toggles.dart';
import 'package:relay/core/widgets/state_views.dart';

import '../helpers/test_harness.dart';

void main() {
  group('RelayButton', () {
    testWidgets('fires onPressed when enabled', (tester) async {
      var taps = 0;
      await pumpWidgetInApp(
        tester,
        Center(
          child: RelayButton(label: 'Go', onPressed: () => taps++),
        ),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 1);
    });

    testWidgets('a null onPressed is disabled and ignores taps', (tester) async {
      await pumpWidgetInApp(tester, const Center(child: RelayButton(label: 'Go', onPressed: null)));
      await tester.tap(find.text('Go'), warnIfMissed: false);
      // Nothing to assert on a callback: the button must simply not throw and
      // must expose itself as disabled to assistive tech.
      final semantics = tester.getSemantics(find.byType(RelayButton));
      expect(semantics.getSemanticsData().flagsCollection.isEnabled.toBoolOrNull(), isFalse);
    });

    testWidgets('loading shows a spinner, keeps the label and blocks double submit', (
      tester,
    ) async {
      var taps = 0;
      await pumpWidgetInApp(
        tester,
        Center(
          child: RelayButton(label: 'Save', isLoading: true, onPressed: () => taps++),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.tap(find.text('Save'));
      expect(taps, 0);
    });

    testWidgets('grows with large text instead of overflowing', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpWidgetInApp(
        tester,
        Center(
          child: RelayButton(label: 'Approve Memo (\$4,850)', onPressed: () {}),
        ),
        size: const Size(320, 600),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(RelayButton)).height, greaterThanOrEqualTo(56));
    });
  });

  group('RelayTextField', () {
    testWidgets('shows an inline error and no error when valid', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      Widget field({String? error}) => Padding(
        padding: const EdgeInsets.all(16),
        child: RelayTextField(
          controller: controller,
          hint: 'name@company.com',
          semanticLabel: 'Work email',
          errorText: error,
        ),
      );

      await pumpWidgetInApp(tester, field(error: 'Enter your work email.'));
      expect(find.text('Enter your work email.'), findsOneWidget);
      expect(find.text('name@company.com'), findsOneWidget, reason: 'hint is visible while empty');

      await pumpWidgetInApp(tester, field());
      expect(find.text('Enter your work email.'), findsNothing);
    });

    testWidgets('obscures secrets and disables suggestions', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpWidgetInApp(
        tester,
        RelayTextField(
          controller: controller,
          hint: 'pw',
          semanticLabel: 'Password',
          obscureText: true,
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.enableSuggestions, isFalse);
      expect(field.autocorrect, isFalse);
      expect(field.enableIMEPersonalizedLearning, isFalse);
    });

    testWidgets('is 56pt tall as in the design', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpWidgetInApp(
        tester,
        Center(
          child: RelayTextField(controller: controller, hint: 'x', semanticLabel: 'x'),
        ),
      );
      expect(tester.getSize(find.byType(TextField)).height, 56);
    });
  });

  group('RelayCard', () {
    testWidgets('draws a border only in high-contrast mode', (tester) async {
      BoxDecoration decoration() =>
          tester
                  .widget<Container>(
                    find.descendant(of: find.byType(RelayCard), matching: find.byType(Container)),
                  )
                  .decoration!
              as BoxDecoration;

      await pumpWidgetInApp(tester, const RelayCard(child: Text('x')), theme: AppTheme.light());
      expect(decoration().border, isNull);

      await pumpWidgetInApp(
        tester,
        const RelayCard(child: Text('x')),
        theme: AppTheme.light(highContrast: true),
      );
      await tester.pumpAndSettle(); // the theme change animates
      expect(decoration().border, isNotNull);
    });
  });

  group('State views', () {
    testWidgets('ErrorView shows only the safe message and a working retry', (tester) async {
      var retries = 0;
      await pumpWidgetInApp(
        tester,
        ErrorView(failure: const ServerFailure(), onRetry: () => retries++),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text(const ServerFailure().message), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('ErrorView distinguishes being offline', (tester) async {
      await pumpWidgetInApp(tester, const ErrorView(failure: NetworkFailure()));
      expect(find.text("Can't reach Relay"), findsOneWidget);
      expect(find.text('Try again'), findsNothing, reason: 'no retry when none is offered');
    });

    testWidgets('EmptyView and LoadingView render their content', (tester) async {
      await pumpWidgetInApp(
        tester,
        const Column(
          children: <Widget>[
            SizedBox(
              height: 300,
              child: EmptyView(
                icon: Icons.inbox,
                title: 'Nothing yet',
                message: 'Come back later.',
              ),
            ),
            SizedBox(height: 100, child: LoadingView(label: 'Loading memos')),
          ],
        ),
      );
      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.text('Come back later.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('RelayAvatar', () {
    testWidgets('falls back to initials for missing and unsafe sources', (tester) async {
      for (final source in <String?>[
        null,
        '',
        'http://insecure.example/a.png',
        'file:///etc/passwd',
        'javascript:1',
      ]) {
        await pumpWidgetInApp(tester, RelayAvatar(source: source, name: 'Marcus Vance', size: 40));
        expect(find.text('MV'), findsOneWidget, reason: '$source');
        expect(find.byType(Image), findsNothing, reason: '$source must never be fetched');
      }
    });

    testWidgets('renders a bundled asset', (tester) async {
      await pumpWidgetInApp(
        tester,
        const RelayAvatar(
          source: 'asset:assets/images/avatar_maya_lin.png',
          name: 'Maya Lin',
          size: 40,
        ),
      );
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('RelayPill', () {
    testWidgets('shows label and trailing text', (tester) async {
      await pumpWidgetInApp(
        tester,
        const Center(
          child: RelayPill(
            label: 'Tooling.pdf',
            trailingText: '2.4 MB',
            background: Colors.grey,
            foreground: Colors.black,
          ),
        ),
      );
      expect(find.text('Tooling.pdf'), findsOneWidget);
      expect(find.text('2.4 MB'), findsOneWidget);
    });
  });

  group('Toggles', () {
    testWidgets('RelaySwitch toggles and exposes its state to accessibility', (tester) async {
      var value = false;
      await pumpWidgetInApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: RelaySwitch(
              value: value,
              semanticLabel: 'Haptic',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(RelaySwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      final data = tester.getSemantics(find.byType(RelaySwitch)).getSemanticsData();
      expect(data.flagsCollection.isToggled.toBoolOrNull(), isTrue);
    });

    testWidgets('RelayCheckbox exposes checked state and a 44pt hit area', (tester) async {
      var value = true;
      await pumpWidgetInApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: RelayCheckbox(
              value: value,
              semanticLabel: 'Module',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(RelayCheckbox)), const Size(44, 44));
      await tester.tap(find.byType(RelayCheckbox));
      await tester.pumpAndSettle();
      expect(value, isFalse);
    });
  });

  group('Dialogs and snackbar', () {
    testWidgets('confirm dialog resolves true only on confirm', (tester) async {
      Future<bool>? result;
      await pumpWidgetInApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => result = showRelayConfirmDialog(
              context,
              title: 'Sure?',
              message: 'Really?',
              confirmLabel: 'Yes',
            ),
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });

    testWidgets('dismissing the dialog by tapping outside counts as "no"', (tester) async {
      Future<bool>? result;
      await pumpWidgetInApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => result = showRelayConfirmDialog(
              context,
              title: 'Sure?',
              message: 'Really?',
              confirmLabel: 'Yes',
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });

    testWidgets('feedback dialog validates, sanitises and returns the note', (tester) async {
      String? note;
      var completed = false;
      await pumpWidgetInApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => unawaited(
              showRelayFeedbackDialog(
                context,
                title: 'Why?',
                message: 'Tell us',
                hint: 'Reason',
                confirmLabel: 'Send',
              ).then((value) {
                note = value;
                completed = true;
              }),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(find.text('Add a short note (at least 3 characters).'), findsOneWidget);
      expect(completed, isFalse, reason: 'invalid input keeps the dialog open');

      final zeroWidth = String.fromCharCode(0x200B);
      await tester.enterText(find.byType(TextField), '  Needs$zeroWidth vendor quotes  ');
      await tester.pump();
      expect(
        find.text('Add a short note (at least 3 characters).'),
        findsNothing,
        reason: 'error clears on edit',
      );
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(note, 'Needs vendor quotes');
    });

    testWidgets('snackbar shows the message for its kind', (tester) async {
      await pumpWidgetInApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => RelaySnackbar.show(context, 'Saved', kind: SnackKind.success),
            child: const Text('go'),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.text('Saved'), findsOneWidget);
      // The 4s auto-dismiss timer only starts once the entrance animation ends.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });
  });
}
