import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app's critical path, expressed against the real widget tree only (no
/// provider access), so the same steps run as a headless widget test and as an
/// `integration_test` on a device:
///
/// welcome -> sign in (validation, wrong password, success) -> memo feed ->
/// open a memo -> back -> quick approve (confirm + biometric) -> settings ->
/// sign out -> welcome.
///
/// [settle] lets the caller decide how to wait for frames/async work.
Future<void> runCriticalFlow(WidgetTester tester, Future<void> Function() settle) async {
  // Semantics handles must be disposed before the test body returns.
  final semantics = tester.ensureSemantics();
  try {
    await _steps(tester, settle);
  } finally {
    semantics.dispose();
  }
}

Future<void> _steps(WidgetTester tester, Future<void> Function() settle) async {
  Future<void> tapText(String text, {int index = 0}) async {
    final finder = find.text(text).at(index);
    // Centre it: a plain ensureVisible can leave it under the frosted bottom bar.
    await Scrollable.ensureVisible(
      finder.evaluate().first,
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pump();
    await tester.tap(finder);
    await settle();
  }

  // ── Welcome ───────────────────────────────────────────────────────────────
  expect(find.text('Workplace memos, made effortless'), findsOneWidget);
  await tapText('Sign in with Work ID');

  // ── Sign in: validation ──────────────────────────────────────────────────
  expect(find.text('Welcome back to Relay'), findsOneWidget);
  await tapText('Enter Workplace');
  expect(find.text('Enter your work email.'), findsOneWidget);
  expect(find.text('Enter your password.'), findsOneWidget);

  // ── Sign in: wrong password gets one vague message and clears the field ──
  await tester.enterText(find.byType(TextField).at(0), 'elena@company.com');
  await tester.enterText(find.byType(TextField).at(1), 'short');
  await tester.pump();
  expect(find.text('Enter your work email.'), findsNothing, reason: 'errors clear as you type');
  await tapText('Enter Workplace');
  expect(find.text('Email or password is incorrect.'), findsOneWidget);
  expect(tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text, isEmpty);

  // ── Sign in: success lands on the memo feed ──────────────────────────────
  await tester.enterText(find.byType(TextField).at(1), 'correct-horse-battery');
  await tester.pump();
  await tapText('Enter Workplace');
  expect(find.text('Good morning, Elena'), findsOneWidget);
  expect(find.text('Pending Decision Feed'), findsOneWidget);
  expect(find.text('Q3 Hardware & Tooling Request'), findsOneWidget);

  // ── Open a memo and come back ────────────────────────────────────────────
  await tapText('Review');
  expect(find.text('Memo Detail'), findsOneWidget);
  expect(find.text('Approval Pathway'), findsOneWidget);
  expect(find.text(r'Approve Memo ($4,850)'), findsOneWidget);
  await tester.tap(find.bySemanticsLabel('Go back'));
  await settle();
  expect(find.text('Pending Decision Feed'), findsOneWidget);

  // ── Quick approve the second memo: confirm dialog -> card disappears ─────
  expect(find.text('Hybrid Workplace Guidelines 2025'), findsOneWidget);
  await tapText('Quick Approve', index: 1);
  expect(find.text('Approve this memo?'), findsOneWidget);
  await tapText('Approve');
  expect(find.text('Memo approved'), findsOneWidget);
  // Let the toast time out, as a user would: it floats near the bottom of the
  // screen, where the (taller) Settings page later puts the Sign Out button.
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 5));
  await settle();
  expect(find.text('Memo approved'), findsNothing);
  expect(find.text('Hybrid Workplace Guidelines 2025'), findsNothing);
  expect(find.text('Q3 Hardware & Tooling Request'), findsOneWidget);

  // ── Settings -> sign out ────────────────────────────────────────────────
  await tapText('Settings');
  expect(find.text('Text Size & Readability'), findsOneWidget);
  await tapText('Sign Out of Relay Workstation');
  expect(find.text('Sign out of Relay?'), findsOneWidget);
  await tapText('Sign out');

  expect(find.text('Workplace memos, made effortless'), findsOneWidget);
  expect(find.text('Text Size & Readability'), findsNothing, reason: 'protected screens are gone');
}
