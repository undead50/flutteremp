import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/router/route_paths.dart';
import 'package:relay/app/shell/main_shell.dart';
import 'package:relay/app/shell/placeholder_tab_screen.dart';
import 'package:relay/app/shell/system_screens.dart';
import 'package:relay/core/security/validators.dart';
import 'package:relay/features/auth/presentation/providers/auth_providers.dart';
import 'package:relay/features/auth/presentation/screens/login_screen.dart';
import 'package:relay/features/memos/presentation/screens/memo_detail_screen.dart';
import 'package:relay/features/memos/presentation/screens/memos_feed_screen.dart';
import 'package:relay/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:relay/features/settings/presentation/screens/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// App router.
///
/// The redirect below decides which screens are *shown* for the current
/// session. It is a UX convenience, not a security control: hiding a route does
/// not protect any data, because every API request is authorised server-side.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final sessionChanges = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (previous, next) => sessionChanges.value++);

  String? redirect(BuildContext context, GoRouterState state) {
    final session = ref.read(sessionControllerProvider);
    final location = state.matchedLocation;
    final isEntry = location == RoutePaths.welcome || location == RoutePaths.login;

    if (session.isLoading) return location == RoutePaths.splash ? null : RoutePaths.splash;
    if (session.value == null) return isEntry ? null : RoutePaths.welcome;
    if (isEntry || location == RoutePaths.splash) return RoutePaths.memos;
    return null;
  }

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: sessionChanges,
    redirect: redirect,
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: <RouteBase>[
      GoRoute(path: RoutePaths.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RoutePaths.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.memos,
                builder: (context, state) => const MemosFeedScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: RoutePaths.memoDetailPattern,
                    // Pushed above the tab bar, like a full-screen detail.
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters[RoutePaths.memoIdParam];
                      // Deep-link input is allow-listed before use.
                      if (!SafeId.isValid(id)) return const NotFoundScreen();
                      return MemoDetailScreen(memoId: id!);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.modules,
                builder: (context, state) => const PlaceholderTabScreen(
                  title: 'Modules',
                  icon: Icons.dashboard_customize_outlined,
                  message: 'Workspace modules will appear here.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.activity,
                builder: (context, state) => const PlaceholderTabScreen(
                  title: 'Activity',
                  icon: Icons.notifications_none_rounded,
                  message: 'Approvals, comments and audit events will appear here.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    sessionChanges.dispose();
  });
  return router;
});
