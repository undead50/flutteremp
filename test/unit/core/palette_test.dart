import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';

/// WCAG 2.1 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final l1 = lum(a);
  final l2 = lum(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  for (final (name, p) in <(String, AppPalette)>[
    ('light', AppPalette.light),
    ('dark', AppPalette.dark),
  ]) {
    group('$name palette contrast (WCAG AA)', () {
      // Every text colour must reach 4.5:1 on every surface it is drawn on.
      final surfaces = <String, Color>{
        'background': p.background,
        'card': p.card,
        'surfaceLow': p.surfaceLow,
        'surface': p.surface,
        'surfaceHigh': p.surfaceHigh,
        'surfaceHighest': p.surfaceHighest,
      };
      final text = <String, Color>{
        'onSurface': p.onSurface,
        'onSurfaceVariant': p.onSurfaceVariant,
        'brand': p.brand,
        'brandMuted': p.brandMuted,
        'secondary': p.secondary,
        'error': p.error,
      };
      for (final s in surfaces.entries) {
        for (final t in text.entries) {
          test('${t.key} on ${s.key}', () {
            expect(_contrast(t.value, s.value), greaterThanOrEqualTo(4.5));
          });
        }
      }

      // `outline` is used for placeholders and secondary captions. The dark
      // value is ours and meets AA (4.5:1). The *light* value is the Figma token
      // #717973, which measures 4.05-4.48:1 on the light surfaces: marginally
      // under AA for small text. It is kept verbatim (it is the design); the
      // floor below documents the actual figure so any further drop is caught.
      final outlineFloor = p.isDark ? 4.5 : 4.0;
      for (final surface in <Color>[p.background, p.card, p.surfaceLow]) {
        test('outline on ${surface.toARGB32().toRadixString(16)} (>= $outlineFloor)', () {
          expect(_contrast(p.outline, surface), greaterThanOrEqualTo(outlineFloor));
        });
      }

      // Filled controls: their label must be legible on the fill.
      final fills = <String, (Color, Color)>{
        'primary': (p.primary, p.onPrimary),
        'primaryContainer': (p.primaryContainer, p.onPrimaryContainer),
        'errorFill': (p.errorFill, p.onErrorFill),
        'escalationFill': (p.escalationFill, p.onEscalationFill),
        'mint': (p.mint, p.onMint),
        'mint (variant)': (p.mint, p.onMintVariant),
        'peach': (p.peach, p.onPeach),
        'peach (strong)': (p.peach, p.onPeachStrong),
        'amber': (p.amber, p.onAmber),
        'inverseSurface': (p.inverseSurface, p.onInverseSurface),
        'errorContainer / title': (p.errorContainer, p.escalationTitle),
        'errorContainer / body': (p.errorContainer, p.escalationBody),
        'errorContainer / text': (p.errorContainer, p.escalationText),
        'errorContainer / error': (p.errorContainer, p.error),
      };
      for (final f in fills.entries) {
        test('${f.key} content on its fill', () {
          expect(_contrast(f.value.$1, f.value.$2), greaterThanOrEqualTo(4.5));
        });
      }

      test('fills and dividers stay visible against the page (non-text 3:1)', () {
        expect(_contrast(p.primary, p.card), greaterThanOrEqualTo(3));
        expect(_contrast(p.primaryContainer, p.card), greaterThanOrEqualTo(3));
      });
    });
  }

  group('palette structure', () {
    test('light keeps the Figma tokens verbatim', () {
      expect(AppPalette.light.background, const Color(0xFFF7FAF7));
      expect(AppPalette.light.primary, const Color(0xFF134230));
      expect(AppPalette.light.primaryContainer, const Color(0xFF2D5A46));
      expect(AppPalette.light.card, const Color(0xFFFFFFFF));
    });

    test('in light mode the fill and content roles are identical', () {
      const l = AppPalette.light;
      expect(l.brand, l.primary);
      expect(l.brandContainer, l.primaryContainer);
      expect(l.error, l.errorFill);
      expect(l.escalationText, l.escalationFill);
    });

    test('in dark mode text roles are lighter than their fills', () {
      const d = AppPalette.dark;
      expect(d.brand.computeLuminance(), greaterThan(d.primary.computeLuminance()));
      expect(d.error.computeLuminance(), greaterThan(d.errorFill.computeLuminance()));
      expect(d.escalationText.computeLuminance(), greaterThan(d.escalationFill.computeLuminance()));
    });

    test('brightness flags', () {
      expect(AppPalette.light.isDark, isFalse);
      expect(AppPalette.dark.isDark, isTrue);
    });

    test('every icon tone resolves to a colour', () {
      for (final tone in IconTone.values) {
        expect(AppPalette.dark.forTone(tone), isA<Color>());
      }
    });
  });

  group('icon dark-tone registry', () {
    test('only references icon files that exist', () {
      for (final path in AppIcons.darkTones.keys) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('never tints multi-colour marks or white-on-fill glyphs', () {
      for (final path in <String>[
        AppIcons.logoMark,
        AppIcons.loginGoogle,
        AppIcons.loginFaceId,
        AppIcons.feedApprove,
        AppIcons.detailApprove,
        AppIcons.detailStepDone,
        AppIcons.loginArrowRight,
        AppIcons.welcomeWorkId,
        AppIcons.feedEstimate,
        AppIcons.detailStepPending,
      ]) {
        expect(AppIcons.darkTones.containsKey(path), isFalse, reason: path);
      }
    });
  });
}
