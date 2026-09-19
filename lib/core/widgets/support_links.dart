import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/providers/core_providers.dart';
import 'package:relay/core/widgets/relay_dialogs.dart';

/// Opens an https URL from build configuration in the system browser, or falls
/// back to an explanatory dialog when none is configured / it can't be opened.
Future<void> openConfiguredLink(
  BuildContext context,
  WidgetRef ref, {
  required Uri? url,
  required String title,
  required String fallbackMessage,
}) async {
  final opened = await ref.read(externalLinkLauncherProvider).open(url);
  if (opened || !context.mounted) return;
  await showRelayInfoDialog(context, title: title, message: fallbackMessage);
}

/// IT helpdesk entry point shared by "Forgot?", "Locked out?" and the footers.
Future<void> openHelpdesk(BuildContext context, WidgetRef ref) {
  return openConfiguredLink(
    context,
    ref,
    url: ref.read(appConfigProvider).helpdeskUrl,
    title: 'Contact IT Operations',
    fallbackMessage:
        'Password resets and account unlocks are handled by IT Operations. '
        'Reach out through your company helpdesk.',
  );
}
