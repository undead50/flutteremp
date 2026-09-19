import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_card.dart';

/// Icons for the Settings screen.
///
/// NOTE: the Figma export for this screen could not be downloaded (design tool
/// quota), so these are Material Symbols stand-ins chosen to match the
/// original glyphs' meaning. Swap for the exported SVGs (`assets/icons`) when
/// available; only this class needs to change.
abstract final class SettingsIcons {
  static const IconData appearance = Icons.brightness_6_rounded;
  static const IconData textSize = Icons.text_fields_rounded;
  static const IconData tactile = Icons.touch_app_outlined;
  static const IconData modules = Icons.dashboard_customize_outlined;
  static const IconData proxy = Icons.switch_account_outlined;
  static const IconData haptic = Icons.vibration_rounded;
  static const IconData contrast = Icons.contrast_rounded;
  static const IconData biometric = Icons.face_rounded;
  static const IconData executiveMemos = Icons.article_outlined;
  static const IconData expenses = Icons.payments_outlined;
  static const IconData leave = Icons.calendar_month_outlined;
  static const IconData policies = Icons.gavel_rounded;
  static const IconData verified = Icons.verified_user_outlined;
  static const IconData check = Icons.check_rounded;
  static const IconData reviewerCheck = Icons.check_circle_outline_rounded;
  static const IconData sync = Icons.sync_rounded;
  static const IconData signOut = Icons.logout_rounded;
}

/// White 32pt-radius section card used by every settings group.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({super.key, required this.children, this.spacing = 20});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return RelayCard(
      radius: AppRadii.r32,
      padding: const EdgeInsets.all(28),
      shadows: AppShadows.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing,
        children: children,
      ),
    );
  }
}

/// 36pt round icon badge (mint or peach) that leads each card header.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.background,
    this.foreground,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;

  /// Defaults to the mint tint.
  final Color? background;

  /// Defaults to the brand green.
  final Color? foreground;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background ?? context.palette.mint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: iconSize, color: foreground ?? context.palette.brand),
      ),
    );
  }
}

/// Icon badge + title + subtitle (+ optional trailing widget).
class SettingsCardHeader extends StatelessWidget {
  const SettingsCardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconBackground,
    this.iconForeground,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconBackground;
  final Color? iconForeground;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconBadge(icon: icon, background: iconBackground, foreground: iconForeground),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(header: true, child: Text(title, style: AppTypography.cardTitle)),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(color: context.palette.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}
