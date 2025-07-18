import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/router_guard.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/features/auth/presentation/pages/login_screen.dart';
import 'package:udharoo/features/home/presentation/pages/home_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/transactions_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_form_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/qr_scanner_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/qr_generator_screen.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/contacts/presentation/pages/contacts_screen.dart';
import 'package:udharoo/features/profile/presentation/pages/profile_screen.dart';
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
  static final _transactionsNavigatorKey = GlobalKey<NavigatorState>();
  static final _contactsNavigatorKey = GlobalKey<NavigatorState>();
  static final _profileNavigatorKey = GlobalKey<NavigatorState>();

  // Shared transaction cubit instance
  static final _transactionCubit = di.sl<TransactionCubit>();

  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: RouterGuard.handleRedirect,
    routes: [
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

      GoRoute(
        path: Routes.transactionForm,
        name: 'transactionForm',
        builder: (context, state) => BlocProvider.value(
          value: _transactionCubit,
          child: const TransactionFormScreen(),
        ),
      ),

      GoRoute(
        path: Routes.qrScanner,
        name: 'qrScanner',
        builder: (context, state) => BlocProvider.value(
          value: _transactionCubit,
          child: const QrScannerScreen(),
        ),
      ),

      GoRoute(
        path: Routes.qrGenerator,
        name: 'qrGenerator',
        builder: (context, state) => const QrGeneratorScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
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

          StatefulShellBranch(
            navigatorKey: _transactionsNavigatorKey,
            routes: [
              GoRoute(
                path: Routes.transactions,
                name: 'transactions',
                builder: (context, state) => BlocProvider.value(
                  value: _transactionCubit,
                  child: const TransactionsScreen(),
                ),
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: _contactsNavigatorKey,
            routes: [
              GoRoute(
                path: Routes.contacts,
                name: 'contacts',
                builder: (context, state) => const ContactsScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: Routes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}