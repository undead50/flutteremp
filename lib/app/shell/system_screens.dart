import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/router/route_paths.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/widgets/relay_button.dart';
import 'package:relay/core/widgets/state_views.dart';

/// Shown while the stored session is being validated at launch.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image(
              image: AssetImage(AppImages.appEmblem),
              width: 64,
              height: 64,
              semanticLabel: 'Relay',
            ),
            SizedBox(height: 16),
            LoadingView(label: 'Opening Relay'),
          ],
        ),
      ),
    );
  }
}

/// Unknown route or rejected deep link. Never echoes the offending URL.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: EmptyView(
          icon: Icons.search_off_rounded,
          title: "We couldn't find that page",
          message: 'The link may be out of date or you may not have access to it.',
          action: RelayButton(
            label: 'Back to memos',
            expand: false,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            onPressed: () => context.go(RoutePaths.memos),
          ),
        ),
      ),
    );
  }
}
