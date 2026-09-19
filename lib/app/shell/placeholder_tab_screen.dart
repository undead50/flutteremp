import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/widgets/relay_headers.dart';
import 'package:relay/core/widgets/state_views.dart';
import 'package:relay/features/auth/presentation/providers/auth_providers.dart';

/// Tabs that exist in the navigation but have no design yet (Modules,
/// Activity). They render the shared empty state instead of dead-ending.
class PlaceholderTabScreen extends ConsumerWidget {
  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.viewPaddingOf(context).top + 64,
                bottom: 112,
              ),
              child: EmptyView(icon: icon, title: '$title is coming soon', message: message),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RelayBrandHeader(
              title: title,
              avatarSource: user?.avatar,
              userName: user?.displayName ?? '',
            ),
          ),
        ],
      ),
    );
  }
}
