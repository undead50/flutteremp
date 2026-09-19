import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/router/route_paths.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/providers/core_providers.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_button.dart';
import 'package:relay/core/widgets/relay_card.dart';
import 'package:relay/core/widgets/relay_pill.dart';
import 'package:relay/core/widgets/relay_snackbar.dart';
import 'package:relay/core/widgets/responsive_body.dart';
import 'package:relay/core/widgets/support_links.dart';
import 'package:relay/core/widgets/svg_asset.dart';
import 'package:relay/features/auth/presentation/providers/login_controller.dart';

/// First screen for signed-out users: brand, value proposition and the two
/// entry points (Work ID / company SSO).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final login = ref.watch(loginControllerProvider);
    final config = ref.watch(appConfigProvider);

    // Only report failures of the SSO attempt started from *this* screen. The
    // controller is shared with the sign-in page stacked on top of this one,
    // whose errors are shown inline there.
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure != null && previous?.submitting == LoginMethod.sso) {
        RelaySnackbar.show(context, failure.message, kind: SnackKind.error);
      }
    });

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Stack(
        children: <Widget>[
          const _AmbientBlobs(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              // The frame has no status bar: content starts 64pt down, or 16pt
              // below the notch/status bar on devices that have one.
              padding: EdgeInsets.fromLTRB(
                16,
                math.max(64, MediaQuery.viewPaddingOf(context).top + 16),
                16,
                24,
              ),
              child: ResponsiveBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _BrandBlock(),
                    const SizedBox(height: 24),
                    const _Headline(),
                    const SizedBox(height: 24),
                    const _DailyPulseCard(),
                    const SizedBox(height: 32),
                    RelayButton(
                      label: 'Sign in with Work ID',
                      height: 54,
                      radius: AppRadii.pill,
                      shadows: AppShadows.primaryButton,
                      onPressed: login.isBusy ? null : () => context.push(RoutePaths.login),
                      leading: const SvgAsset(AppIcons.welcomeWorkId, width: 16.67, height: 16.67),
                    ),
                    const SizedBox(height: 12),
                    RelayButton.tonal(
                      label: 'Company Single Sign-On',
                      height: 54,
                      radius: AppRadii.pill,
                      background: context.palette.surfaceHigh,
                      isLoading: login.submitting == LoginMethod.sso,
                      onPressed: login.isBusy
                          ? null
                          : ref.read(loginControllerProvider.notifier).signInWithSso,
                      leading: const SvgAsset(AppIcons.welcomeBuilding, width: 16.67, height: 15),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: RelayPill(
                        label: 'Secured by Enterprise SSO & Biometrics',
                        background: context.palette.surface,
                        foreground: context.palette.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        gap: 8,
                        maxLines: 2,
                        leading: const SvgAsset(
                          AppIcons.welcomeFingerprint,
                          width: 12.03,
                          height: 13.31,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    _LegalLinks(
                      onPrivacy: () => openConfiguredLink(
                        context,
                        ref,
                        url: config.privacyUrl,
                        title: 'Privacy Charter',
                        fallbackMessage: 'The privacy charter is not available in this build.',
                      ),
                      onHelpdesk: () => openHelpdesk(context, ref),
                      onTrust: () => openConfiguredLink(
                        context,
                        ref,
                        url: config.trustCenterUrl,
                        title: 'Trust Center',
                        fallbackMessage: 'The trust center is not available in this build.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two soft colour washes behind the content (mint top-right, peach left).
class _AmbientBlobs extends StatelessWidget {
  const _AmbientBlobs();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: <Widget>[
              Positioned(
                top: -64,
                right: -64,
                child: _Blob(
                  size: 224,
                  color: context.palette.mint.withValues(alpha: 0.3),
                  sigma: 32,
                ),
              ),
              Positioned(
                left: -80,
                top: constraints.maxHeight * 0.3602,
                child: _Blob(
                  size: 192,
                  color: context.palette.peach.withValues(alpha: 0.4),
                  sigma: 20,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color, required this.sigma});

  final double size;
  final Color color;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RelayCard(
          padding: EdgeInsets.zero,
          radius: AppRadii.r24,
          shadows: AppShadows.level1,
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  context.palette.mint.withValues(alpha: 0.2),
                  context.palette.mint.withValues(alpha: 0),
                ],
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Image(
                    image: AssetImage(AppImages.relayEmblem),
                    width: 112,
                    height: 112,
                    fit: BoxFit.cover,
                    semanticLabel: 'Relay',
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        RelayPill(
          label: 'v2.4 • Enterprise Suite',
          background: context.palette.surfaceHigh,
          foreground: context.palette.brand,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: SizedBox.square(
            dimension: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(color: context.palette.brand, shape: BoxShape.circle),
            ),
          ),
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              'Workplace memos, made effortless',
              textAlign: TextAlign.center,
              style: AppTypography.titleHeroLight,
            ),
          ),
          const SizedBox(height: 9),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              'A stress-reductive space for thoughtful executive reviews, '
              'sound decisions, and team alignment.',
              textAlign: TextAlign.center,
              style: context.text.body17,
            ),
          ),
        ],
      ),
    );
  }
}

/// Static product teaser card ("Daily Pulse"). Decorative, not interactive.
class _DailyPulseCard extends StatelessWidget {
  const _DailyPulseCard();

  @override
  Widget build(BuildContext context) {
    return RelayCard(
      radius: AppRadii.r24,
      shadows: AppShadows.level1,
      padding: const EdgeInsets.all(16),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.palette.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Daily Pulse', style: AppTypography.label14),
                  ],
                ),
                RelayPill(
                  label: 'Ready to sign',
                  background: context.palette.surface,
                  foreground: context.palette.onSurfaceVariant,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.palette.surfaceLow,
                borderRadius: BorderRadius.circular(AppRadii.r16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.palette.mint,
                        shape: BoxShape.circle,
                      ),
                      child: const SvgAsset(AppIcons.welcomeDocument, width: 14.67, height: 18.33),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Q3 Capital Allocation Memo',
                            style: AppTypography.label14,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Pending your final endorsement',
                            style: AppTypography.caption.copyWith(
                              color: context.palette.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.palette.surfaceHighest,
                        shape: BoxShape.circle,
                      ),
                      child: const SvgAsset(AppIcons.welcomeArrowRight, width: 12, height: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _Meta(
                    icon: AppIcons.welcomeClock,
                    iconWidth: 13.33,
                    iconHeight: 13.33,
                    text: 'Avg. 2 min read',
                  ),
                  _Meta(
                    icon: AppIcons.welcomeShield,
                    iconWidth: 10.67,
                    iconHeight: 13.33,
                    text: 'Zero clutter',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.iconWidth,
    required this.iconHeight,
    required this.text,
  });

  final String icon;
  final double iconWidth;
  final double iconHeight;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SvgAsset(icon, width: iconWidth, height: iconHeight),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.caption.copyWith(color: context.palette.onSurfaceVariant)),
      ],
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.onPrivacy, required this.onHelpdesk, required this.onTrust});

  final VoidCallback onPrivacy;
  final VoidCallback onHelpdesk;
  final VoidCallback onTrust;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.captionRegular.copyWith(
      letterSpacing: 0,
      color: context.palette.outline,
    );
    Widget link(String text, VoidCallback onTap) => Semantics(
      link: true,
      button: true,
      excludeSemantics: true,
      label: text,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Text(text, style: style),
        ),
      ),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: <Widget>[
        link('Privacy Charter', onPrivacy),
        Text('•', style: style),
        link('IT Helpdesk', onHelpdesk),
        Text('•', style: style),
        link('Trust Center', onTrust),
      ],
    );
  }
}
