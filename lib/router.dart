import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/player/player_screen.dart';
import 'screens/downloads/downloads_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/bottom_nav.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/player',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: CustomBottomNav(
            currentRoute: state.uri.toString(),
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/player',
          builder: (context, state) => const PlayerScreen(),
        ),
        GoRoute(
          path: '/downloads',
          builder: (context, state) {
            final url = state.uri.queryParameters['url'];
            return DownloadsScreen(sharedUrl: url);
          },
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
