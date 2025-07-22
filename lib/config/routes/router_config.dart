import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/router_guard.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/features/auth/presentation/pages/login_screen.dart';
import 'package:udharoo/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:udharoo/features/auth/presentation/pages/phone_setup_screen.dart';
import 'package:udharoo/features/auth/presentation/pages/phone_verification_screen.dart';
import 'package:udharoo/features/home/presentation/pages/home_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/transactions_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_form_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_detail_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/qr_scanner_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/qr_generator_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/finished_transactions_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/contact_transactions_screen.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/contacts/presentation/pages/contacts_screen.dart';
import 'package:udharoo/features/profile/presentation/pages/profile_screen.dart';
import 'package:udharoo/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:udharoo/shared/presentation/layouts/scaffold_with_bottom_nav_bar.dart';
import 'package:udharoo/shared/presentation/pages/splash_screen.dart';

class PhoneVerificationExtra {
  final String phoneNumber;
  final String verificationId;

  const PhoneVerificationExtra({
    required this.phoneNumber,
    required this.verificationId,
  });
}

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
        path: Routes.signUp,
        name: 'signUp',
        builder: (context, state) => const SignUpScreen(),
      ),

      GoRoute(
        path: Routes.phoneSetup,
        name: 'phoneSetup',
        builder: (context, state) => const PhoneSetupScreen(),
      ),

      GoRoute(
        path: Routes.phoneVerification,
        name: 'phoneVerification',
        builder: (context, state) {
          final extra = state.extra;
          String phoneNumber = '';
          String verificationId = '';
          
          if (extra is PhoneVerificationExtra) {
            phoneNumber = extra.phoneNumber;
            verificationId = extra.verificationId;
          } else if (extra is Map<String, dynamic>) {
            phoneNumber = extra['phoneNumber']?.toString() ?? '';
            verificationId = extra['verificationId']?.toString() ?? '';
          }
          
          return PhoneVerificationScreen(
            phoneNumber: phoneNumber,
            verificationId: verificationId,
          );
        },
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

      GoRoute(
        path: Routes.transactionForm,
        name: 'transactionForm',
        builder: (context, state) {
          final extra = state.extra as TransactionFormScreenArguments?;
          return BlocProvider.value(
            value: _transactionCubit,
            child: TransactionFormScreen(
              qrData: extra?.qrData,
              initialType: extra?.initialType,
            ),
          );
        },
      ),

      GoRoute(
        path: Routes.transactionDetail,
        name: 'transactionDetail',
        builder: (context, state) {
          final transaction = state.extra as Transaction;
          return BlocProvider.value(
            value: _transactionCubit,
            child: TransactionDetailScreen(transaction: transaction),
          );
        },
      ),

      GoRoute(
        path: Routes.finishedTransactions,
        name: 'finishedTransactions',
        builder: (context, state) => BlocProvider.value(
          value: _transactionCubit,
          child: const FinishedTransactionsScreen(),
        ),
      ),

      GoRoute(
        path: Routes.contactTransactions,
        name: 'contactTransactions',
        builder: (context, state) {
          final args = state.extra as ContactTransactionsScreenArguments;
          return BlocProvider.value(
            value: _transactionCubit,
            child: ContactTransactionsScreen(
              contactName: args.contactName,
              contactPhone: args.contactPhone,
            ),
          );
        },
      ),

      GoRoute(
        path: Routes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
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