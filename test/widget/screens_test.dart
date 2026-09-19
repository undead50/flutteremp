import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/app/router/app_router.dart';
import 'package:relay/app/router/route_paths.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/providers/core_providers.dart';
import 'package:relay/core/widgets/relay_button.dart';
import 'package:relay/core/theme/app_theme.dart';
import 'package:relay/features/memos/domain/entities/approval_decision.dart';
import 'package:relay/features/memos/presentation/providers/memo_providers.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/presentation/providers/settings_providers.dart';
import 'package:relay/features/settings/presentation/screens/settings_screen.dart';

import '../helpers/test_harness.dart';

const Size _tall = Size(390, 2400);

Future<void> _tap(WidgetTester tester, String text, {int index = 0}) async {
  final finder = find.text(text).at(index);
  // Centre it: a plain ensureVisible can leave it under the frosted bottom bar.
  await Scrollable.ensureVisible(finder.evaluate().first, alignment: 0.5, duration: Duration.zero);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

/// The filter chips live in a horizontal list that builds lazily, so scroll to
/// the chip before tapping it.
Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    120,
    scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
  );
  // `scrollUntilVisible` stops once the chip is *built*; bring it fully on screen.
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  await settle(tester);
}

void main() {
  group('Sign-in screen', () {
    testWidgets('five wrong passwords lock the form, then it unlocks after the cool-down', (
      tester,
    ) async {
      final harness = await TestHarness.create();
      final container = await pumpRelayApp(tester, harness, size: _tall);
      container.read(routerProvider).go(RoutePaths.login);
      await settle(tester);

      await tester.enterText(find.byType(TextField).at(0), 'elena@company.com');
      for (var i = 0; i < 5; i++) {
        await tester.enterText(find.byType(TextField).at(1), 'short');
        await tester.pump();
        await _tap(tester, 'Enter Workplace');
      }

      expect(find.text('Too many attempts. Please wait a moment and try again.'), findsOneWidget);
      final button = tester.widget<RelayButton>(
        find.widgetWithText(RelayButton, 'Enter Workplace'),
      );
      expect(button.onPressed, isNull, reason: 'submit is disabled while locked out');

      await tester.pump(const Duration(seconds: 31));
      await tester.pump();
      expect(find.text('Too many attempts. Please wait a moment and try again.'), findsNothing);
    });

    testWidgets('the password field is obscured and can be revealed', (tester) async {
      final harness = await TestHarness.create();
      final container = await pumpRelayApp(tester, harness, size: _tall);
      container.read(routerProvider).go(RoutePaths.login);
      await settle(tester);

      bool obscured() => tester.widget<TextField>(find.byType(TextField).at(1)).obscureText;
      expect(obscured(), isTrue);
      await tester.tap(find.bySemanticsLabel('Show password'));
      await tester.pump();
      expect(obscured(), isFalse);
    });

    testWidgets('credential fields opt out of learning and auto-correction', (tester) async {
      final harness = await TestHarness.create();
      final container = await pumpRelayApp(tester, harness, size: _tall);
      container.read(routerProvider).go(RoutePaths.login);
      await settle(tester);

      for (var i = 0; i < 2; i++) {
        final field = tester.widget<TextField>(find.byType(TextField).at(i));
        expect(field.autocorrect, isFalse);
        expect(field.enableSuggestions, isFalse);
      }
    });

    testWidgets('quick unlock without a stored session says what to do', (tester) async {
      final harness = await TestHarness.create();
      final container = await pumpRelayApp(tester, harness, size: _tall);
      container.read(routerProvider).go(RoutePaths.login);
      await settle(tester);

      await _tap(tester, 'Quick Unlock with Face ID');
      expect(find.text('Sign in with your password once to enable quick unlock.'), findsOneWidget);
    });

    testWidgets('quick unlock resumes a stored session after a successful biometric check', (
      tester,
    ) async {
      final harness = await TestHarness.create(signedIn: true);
      final container = await pumpRelayApp(tester, harness, size: _tall);

      // The session is dropped in memory (e.g. app locked), but the refresh
      // token is still in secure storage.
      container.read(sessionEventsProvider).notifyExpired();
      await settle(tester);
      expect(find.text('Workplace memos, made effortless'), findsOneWidget);

      container.read(routerProvider).go(RoutePaths.login);
      await settle(tester);
      await _tap(tester, 'Quick Unlock with Face ID');

      expect(harness.biometrics.reasons, hasLength(1));
      expect(find.text('Good morning, Elena'), findsOneWidget);
    });

    testWidgets('quick unlock stays on Sign-in when Face ID is cancelled', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      harness.biometrics.outcome = const Result<void>.failure(BiometricCancelledFailure());
      final container = await pumpRelayApp(tester, harness, size: _tall);

      container.read(sessionEventsProvider).notifyExpired();
      await settle(tester);
      container.read(routerProvider).go(RoutePaths.login);
      await settle(tester);
      await _tap(tester, 'Quick Unlock with Face ID');

      expect(find.text('Verification was cancelled.'), findsOneWidget);
      expect(find.text('Welcome back to Relay'), findsOneWidget);
    });
  });

  group('Memo feed', () {
    testWidgets('shows the briefing, escalation, filters and pending cards', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await pumpRelayApp(tester, harness, size: _tall);

      expect(find.text('Good morning, Elena'), findsOneWidget);
      expect(find.text('Tue, Oct 24'), findsOneWidget);
      expect(
        find.text('3 critical memos await your executive sign-off before 2:00 PM.'),
        findsOneWidget,
      );
      expect(find.text('FY25 Cloud Infrastructure Allocation'), findsOneWidget);
      expect(find.text('Expiring in 2h'), findsOneWidget);
      expect(find.text('Q3 Hardware & Tooling Request'), findsOneWidget);
      expect(find.textContaining('45m ago'), findsOneWidget);
      expect(find.text('18 Approved'), findsOneWidget);
      // Counters on the chips are derived from the cards.
      expect(find.bySemanticsLabel('Memos, 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Budgets, 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Leave, 0'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Policies, 2'),
        120,
        scrollable: find
            .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
            .first,
      );
      expect(find.bySemanticsLabel('Policies, 2'), findsOneWidget);
    }, semanticsEnabled: true);

    testWidgets('filter chips narrow the list', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await pumpRelayApp(tester, harness, size: _tall);

      await _tapChip(tester, 'Policies');
      expect(find.text('Q3 Hardware & Tooling Request'), findsNothing);
      expect(find.text('Hybrid Workplace Guidelines 2025'), findsOneWidget);
      expect(find.text('Design System Offsite Proposal'), findsOneWidget);

      await _tapChip(tester, 'Leave');
      expect(find.text('Nothing in this view'), findsOneWidget);
    });

    testWidgets('a load failure shows a friendly error and Try again recovers', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      harness.memoSource.feedFailure = const NetworkFailure();
      await pumpRelayApp(tester, harness, size: _tall);

      expect(find.text("Can't reach Relay"), findsOneWidget);
      expect(find.text(const NetworkFailure().message), findsOneWidget);
      expect(find.text('Q3 Hardware & Tooling Request'), findsNothing);

      harness.memoSource.feedFailure = null;
      await _tap(tester, 'Try again');
      expect(find.text('Q3 Hardware & Tooling Request'), findsOneWidget);
    });

    testWidgets('a timeout is reported without technical detail', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      harness.memoSource.feedFailure = const TimeoutFailure();
      await pumpRelayApp(tester, harness, size: _tall);
      expect(find.text('The request took too long. Please try again.'), findsOneWidget);
    });

    testWidgets('approving everything leaves the "all caught up" empty state', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      final container = await pumpRelayApp(tester, harness, size: _tall);

      final decisions = container.read(memoDecisionControllerProvider.notifier);
      // The mock backend uses real (zero-length) timers, which only fire under runAsync.
      for (final id in <String>['hardware-q3', 'hybrid-workplace', 'design-offsite']) {
        await tester.runAsync(
          () => decisions.decide(memoId: id, decision: ApprovalDecision.approve),
        );
      }
      await settle(tester);

      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('21 Approved'), findsOneWidget);
      expect(
        find.text("Nothing is waiting on your sign-off. You're all caught up."),
        findsOneWidget,
      );
    });

    testWidgets('cancelling the confirmation submits nothing', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await pumpRelayApp(tester, harness, size: _tall);

      await _tap(tester, 'Quick Approve');
      expect(find.text('Approve this memo?'), findsOneWidget);
      await _tap(tester, 'Cancel');

      expect(harness.memoSource.decisions, isEmpty);
      expect(find.text('Q3 Hardware & Tooling Request'), findsOneWidget);
    });

    testWidgets('a rejected approval keeps the card and explains why', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      harness.memoSource.decisionFailure = const ForbiddenFailure();
      await pumpRelayApp(tester, harness, size: _tall);

      await _tap(tester, 'Quick Approve');
      await _tap(tester, 'Approve');

      expect(
        find.text("You don't have permission to do that."),
        findsOneWidget,
        reason: 'authorization is decided by the backend and reported, not bypassed',
      );
      expect(find.text('Q3 Hardware & Tooling Request'), findsOneWidget);
    });

    testWidgets('cancelling Face ID prevents the approval from being sent', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      harness.biometrics.outcome = const Result<void>.failure(BiometricCancelledFailure());
      await pumpRelayApp(tester, harness, size: _tall);

      await _tap(tester, 'Quick Approve');
      await _tap(tester, 'Approve');

      expect(find.text('Verification was cancelled.'), findsOneWidget);
      expect(harness.memoSource.decisions, isEmpty);
    });

    testWidgets('turning a module off in Settings hides its chip on the feed', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await pumpRelayApp(tester, harness, size: _tall);

      await _tap(tester, 'Settings');
      await _tap(tester, 'Expense Approvals');
      await _tap(tester, 'Memos');

      expect(find.text('Budgets'), findsNothing);
      await _tapChip(tester, 'Policies');
      expect(find.text('Policies'), findsOneWidget);
    });
  });

  group('Memo detail', () {
    Future<ProviderContainer> openDetail(
      WidgetTester tester,
      TestHarness harness,
      String id,
    ) async {
      final container = await pumpRelayApp(tester, harness, size: const Size(390, 3100));
      unawaited(container.read(routerProvider).push(RoutePaths.memoDetail(id)));
      await settle(tester);
      return container;
    }

    testWidgets('renders every section of the design with a derived total', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await openDetail(tester, harness, 'hardware-q3');

      for (final text in <String>[
        'MEMO #ENG-2024-098',
        'Urgent Priority',
        '2 min review',
        'Approval Pathway',
        'Step 2 of 3',
        'Submitted for Review',
        'Elena Vance (You)',
        'Pending',
        'Finance Sign-off',
        'Executive Summary',
        'Business Justification',
        '3.5 hrs',
        r'-$1,240',
        'Budget Allocation',
        r'$3,600',
        'Total Requisition',
        r'$4,850.00',
        'Team Impact',
        '+3',
        'Cryptographically signed with Relay ID #7F02-99B',
        r'Approve Memo ($4,850)',
        'Request Revision',
        'Decline Feedback',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('optional sections are simply absent when the memo has none', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await openDetail(tester, harness, 'hybrid-workplace');

      expect(find.text('Hybrid Workplace Guidelines 2025'), findsOneWidget);
      expect(
        find.text('Approve Memo'),
        findsOneWidget,
        reason: 'no amount when there is no budget',
      );
      expect(find.text('Budget Allocation'), findsNothing);
      expect(find.text('Team Impact'), findsNothing);
    });

    testWidgets('an unknown memo shows a safe error, not a crash', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await openDetail(tester, harness, 'does-not-exist');

      expect(find.text("Couldn't open this memo"), findsOneWidget);
      expect(find.text(const NotFoundFailure().message), findsOneWidget);
    });

    testWidgets('requesting a revision demands a note, then submits it and returns to the feed', (
      tester,
    ) async {
      final harness = await TestHarness.create(signedIn: true);
      await openDetail(tester, harness, 'hardware-q3');

      await _tap(tester, 'Request Revision');
      expect(find.text('Request a revision'), findsOneWidget);

      await _tap(tester, 'Send request');
      expect(find.text('Add a short note (at least 3 characters).'), findsOneWidget);
      expect(harness.memoSource.decisions, isEmpty);

      await tester.enterText(find.byType(TextField), 'Please attach the vendor quotes.');
      await _tap(tester, 'Send request');

      final sent = harness.memoSource.decisions.single;
      expect(sent.decision, ApprovalDecision.requestRevision);
      expect(sent.comment, 'Please attach the vendor quotes.');
      expect(find.text('Revision requested'), findsOneWidget);
      expect(
        find.text('Pending Decision Feed'),
        findsOneWidget,
        reason: 'navigated back to the feed',
      );
    });

    testWidgets('declining is a destructive, explained action', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await openDetail(tester, harness, 'hardware-q3');

      await _tap(tester, 'Decline Feedback');
      expect(find.text('Decline this memo?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Not in this quarter budget.');
      await _tap(tester, 'Decline');

      expect(harness.memoSource.decisions.single.decision, ApprovalDecision.decline);
      expect(find.text('Memo declined'), findsOneWidget);
    });

    testWidgets('approving from the detail screen returns to a feed without that memo', (
      tester,
    ) async {
      final harness = await TestHarness.create(signedIn: true);
      await openDetail(tester, harness, 'hardware-q3');

      await _tap(tester, r'Approve Memo ($4,850)');
      await _tap(tester, 'Approve');

      expect(find.text('Memo approved'), findsOneWidget);
      expect(find.text('Pending Decision Feed'), findsOneWidget);
      expect(find.text('Q3 Hardware & Tooling Request'), findsNothing);
    });
  });

  group('Settings', () {
    Future<ProviderContainer> openSettings(WidgetTester tester, TestHarness harness) async {
      final container = await pumpRelayApp(tester, harness, size: _tall);
      container.read(routerProvider).go(RoutePaths.settings);
      await settle(tester);
      return container;
    }

    testWidgets('shows the profile, proxy and every control', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await openSettings(tester, harness);

      for (final text in <String>[
        'Elena Vance',
        'VP Operations · Relay Core',
        'Staff Level 9',
        'ID: #8942-EV',
        'Text Size & Readability',
        'Tactile & Contrast',
        'Active Modules',
        '4 of 4 Active',
        'Sign-off Proxy',
        'Marcus Brody',
        'Proxy standby · 48h limit',
        'Synchronize Offline Outbox (0)',
        'Sign Out of Relay Workstation',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('choosing Large text scales the whole app and is remembered', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await openSettings(tester, harness);

      double scale() =>
          MediaQuery.of(tester.element(find.byType(SettingsScreen))).textScaler.scale(100) / 100;
      expect(scale(), closeTo(1, 0.001));

      await _tap(tester, 'Large');
      expect(scale(), closeTo(1.15, 0.001));
      expect(harness.prefs.getString('pref.text_size'), 'large');

      await _tap(tester, 'Extra Large');
      expect(scale(), closeTo(1.3, 0.001));
    });

    testWidgets('High Contrast Borders switches the theme extension', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await openSettings(tester, harness);

      bool highContrast() =>
          Theme.of(tester.element(find.byType(SettingsScreen)))
              .extension<RelayAccessibilityTheme>()!
              .highContrast;
      expect(highContrast(), isFalse);

      await _tap(tester, 'High Contrast Borders');
      expect(highContrast(), isTrue);
      expect(harness.prefs.getBool('pref.high_contrast'), isTrue);
    });

    testWidgets('the last active module cannot be switched off', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      final container = await openSettings(tester, harness);

      for (final name in <String>['Expense Approvals', 'Team Leave Schedule', 'Policy Revisions']) {
        await _tap(tester, name);
      }
      expect(find.text('1 of 4 Active'), findsOneWidget);

      await _tap(tester, 'Executive Memos');
      expect(find.text('Keep at least one module active.'), findsOneWidget);
      expect(find.text('1 of 4 Active'), findsOneWidget);
      expect(container.read(preferencesControllerProvider).activeModules, <WorkspaceModule>{
        WorkspaceModule.executiveMemos,
      });
    });

    testWidgets('Synchronize Offline Outbox reports an up-to-date queue', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await openSettings(tester, harness);

      await _tap(tester, 'Synchronize Offline Outbox (0)');
      expect(find.text('Your outbox is up to date.'), findsOneWidget);
    });

    testWidgets('cancelling the sign-out dialog keeps the session', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      await openSettings(tester, harness);

      await _tap(tester, 'Sign Out of Relay Workstation');
      await _tap(tester, 'Cancel');

      expect(find.text('Text Size & Readability'), findsOneWidget);
      expect(await harness.tokens.read(), isNotNull);
    });
  });

  group('Route guards', () {
    testWidgets('a signed-out deep link to a memo lands on Welcome', (tester) async {
      final harness = await TestHarness.create();
      final container = await pumpRelayApp(tester, harness);
      container.read(routerProvider).go(RoutePaths.memoDetail('hardware-q3'));
      await settle(tester);

      expect(find.text('Workplace memos, made effortless'), findsOneWidget);
      expect(find.text('Memo Detail'), findsNothing);
    });

    testWidgets('a signed-in user is redirected away from Welcome and Sign-in', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      final container = await pumpRelayApp(tester, harness);

      for (final path in <String>[RoutePaths.welcome, RoutePaths.login, RoutePaths.splash]) {
        container.read(routerProvider).go(path);
        await settle(tester);
        expect(find.text('Pending Decision Feed'), findsOneWidget, reason: path);
      }
    });

    testWidgets('malicious or malformed memo ids never reach the API', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      final container = await pumpRelayApp(tester, harness);

      for (final id in <String>['../admin', 'a b', 'x' * 65, '%2e%2e']) {
        container.read(routerProvider).go('${RoutePaths.memos}/${Uri.encodeComponent(id)}');
        await settle(tester);
        expect(find.text("We couldn't find that page"), findsOneWidget, reason: id);
      }
      expect(find.text('Memo Detail'), findsNothing);
    });

    testWidgets('an unknown route shows Not Found without echoing the URL', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      final container = await pumpRelayApp(tester, harness);
      container.read(routerProvider).go('/definitely/not/here?token=secret');
      await settle(tester);

      expect(find.text("We couldn't find that page"), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      await _tap(tester, 'Back to memos');
      expect(find.text('Pending Decision Feed'), findsOneWidget);
    });

    testWidgets('a mid-session credential expiry returns the user to Welcome', (tester) async {
      final harness = await TestHarness.create(signedIn: true);
      final container = await pumpRelayApp(tester, harness);
      expect(find.text('Pending Decision Feed'), findsOneWidget);

      // What the network layer does when a token refresh fails.
      container.read(sessionEventsProvider).notifyExpired();
      await settle(tester);

      expect(find.text('Workplace memos, made effortless'), findsOneWidget);
    });
  });
}
