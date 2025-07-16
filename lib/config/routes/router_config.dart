import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/router_guard.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/auth/presentation/pages/login_screen.dart';
import 'package:udharoo/features/home/presentation/pages/home_screen.dart';
import 'package:udharoo/shared/presentation/layouts/scaffold_with_bottom_nav_bar.dart';
import 'package:udharoo/shared/presentation/pages/splash_screen.dart';

class AppRouter {
  static final AppRouter _instance = AppRouter._internal();

  AppRouter._internal();

  factory AppRouter() {
    return _instance;
  }

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _homeNavigatorKey = GlobalKey<NavigatorState>();
  static final _profileNavigatorKey = GlobalKey<NavigatorState>();
  static final _settingsNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: RouterGuard.handleRedirect,
    routes: [
      // Auth routes
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main stateful shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home branch
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: Routes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Profile branch
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [

            ],
          ),


          // Settings branch
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [

            ],
          ),
        ],
      ),
    ],
  );
}
