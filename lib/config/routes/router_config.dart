import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/features/auth/presentation/pages/login_screen.dart';
import 'package:udharoo/features/auth/presentation/pages/profile_completion_screen.dart';
import 'package:udharoo/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:udharoo/features/phone_verification/presentation/pages/phone_setup_screen.dart';
import 'package:udharoo/features/phone_verification/presentation/pages/phone_verification_screen.dart';
import 'package:udharoo/features/phone_verification/presentation/pages/change_phone_setup_screen.dart';
import 'package:udharoo/features/phone_verification/presentation/pages/change_phone_verification_screen.dart';
import 'package:udharoo/features/home/presentation/pages/home_screen.dart';
import 'package:udharoo/features/transactions/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/finished_transactions/finished_transactions_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/qr_code/qr_code_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_detail/transaction_detail_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_form/transaction_form_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_list/transaction_list_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_stats/transaction_stats_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/received_transaction_requests/received_transaction_requests_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/completion_requests/completion_requests_cubit.dart';
import 'package:udharoo/features/transactions/presentation/pages/transactions_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_form_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_detail_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/qr_scanner_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/qr_generator_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/finished_transactions_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/contact_transactions_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/received_transaction_requests_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/completion_requests_screen.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/contacts/presentation/pages/contacts_screen.dart';
import 'package:udharoo/features/profile/presentation/pages/profile_screen.dart';
import 'package:udharoo/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:udharoo/shared/presentation/layouts/scaffold_with_bottom_nav_bar.dart';
import 'package:udharoo/shared/presentation/widgets/auth_wrapper.dart';

class AppRouter {
  static final AppRouter _instance = AppRouter._internal();

  AppRouter._internal();

  factory AppRouter() {
    return _instance;
  }

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _transactionListCubit = di.sl<TransactionListCubit>();
  static final _transactionStatsCubit = di.sl<TransactionStatsCubit>();

  static final _homeNavigatorKey = GlobalKey<NavigatorState>();
  static final _transactionsNavigatorKey = GlobalKey<NavigatorState>();
  static final _contactsNavigatorKey = GlobalKey<NavigatorState>();
  static final _profileNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AuthWrapper(
            child: ScaffoldWithBottomNavBar(navigationShell: navigationShell),
          );
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
              GoRoute(
                path: Routes.signUp,
                name: 'signUp',
                builder: (context, state) => const SignUpScreen(),
              ),
              GoRoute(
                path: Routes.login,
                name: 'login',
                builder: (context, state) => const LoginScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: _transactionsNavigatorKey,
            routes: [
              GoRoute(
                path: Routes.transactions,
                name: 'transactions',
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: _transactionListCubit),
                    BlocProvider.value(value: _transactionStatsCubit),
                    BlocProvider(create: (context) => di.sl<ReceivedTransactionRequestsCubit>()),
                    BlocProvider(create: (context) => di.sl<CompletionRequestsCubit>()),
                  ],
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

      GoRoute(
        path: Routes.profileCompletion,
        name: 'profileCompletion',
        builder: (context, state) => const ProfileCompletionScreen(),
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
        path: Routes.phoneSetup,
        name: 'phoneSetup',
        builder: (context, state) {
          return PhoneSetupScreen();
        },
      ),

      GoRoute(
        path: Routes.changePhoneSetup,
        name: 'changePhoneSetup',
        builder: (context, state) {
          final newPhoneNumber = state.extra as String;

          return ChangePhoneSetupScreen(newPhoneNumber: newPhoneNumber);
        },
      ),

      GoRoute(
        path: Routes.changePhoneVerification,
        name: 'changePhoneVerification',
        builder: (context, state) {
          final extra = state.extra as ChangePhoneVerificationExtra;

          return ChangePhoneVerificationScreen(
            currentPhoneNumber: extra.currentPhoneNumber,
            newPhoneNumber: extra.newPhoneNumber,
            verificationId: extra.verificationId,
          );
        },
      ),

      GoRoute(
        path: Routes.qrScanner,
        name: 'qrScanner',
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<QRCodeCubit>(),
          child: const QRScannerScreen(),
        ),
      ),

      GoRoute(
        path: Routes.qrGenerator,
        name: 'qrGenerator',
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<QRCodeCubit>(),
          child: const QRGeneratorScreen(),
        ),
      ),

      GoRoute(
        path: Routes.transactionForm,
        name: 'transactionForm',
        builder: (context, state) {
          final extra = state.extra;

          String? scannedContactPhone;
          String? scannedContactName;
          String? scannedContactEmail;
          bool? scannedVerificationRequired;
          Transaction? transaction;

          if (extra is Map<String, dynamic>) {
            scannedContactPhone = extra['scannedContactPhone']?.toString();
            scannedContactName = extra['scannedContactName']?.toString();
            scannedContactEmail = extra['scannedContactEmail']?.toString();
            scannedVerificationRequired =
                extra['scannedVerificationRequired'] as bool?;
          } else if (extra is Transaction) {
            transaction = extra;
          }

          return BlocProvider(
            create: (context) => di.sl<TransactionFormCubit>(),
            child: TransactionFormScreen(
              transaction: transaction,
              scannedContactPhone: scannedContactPhone,
              scannedContactName: scannedContactName,
              scannedContactEmail: scannedContactEmail,
              scannedVerificationRequired: scannedVerificationRequired,
            ),
          );
        },
      ),

      GoRoute(
        path: '${Routes.transactionDetail}/:id',
        name: 'transactionDetail',
        builder: (context, state) {
          final transactionId = state.pathParameters['id']!;
          return BlocProvider(
            create: (context) => di.sl<TransactionDetailCubit>(),
            child: TransactionDetailScreen(transactionId: transactionId),
          );
        },
      ),

      GoRoute(
        path: Routes.finishedTransactions,
        name: 'finishedTransactions',
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<FinishedTransactionsCubit>(),
          child: const FinishedTransactionsScreen(),
        ),
      ),

      GoRoute(
        path: Routes.contactTransactions,
        name: 'contactTransactions',
        builder: (context, state) {
          final args = state.extra as ContactTransactionsScreenArguments;

          final contact = TransactionContact(
            phone: args.contactPhone,
            name: args.contactName,
            transactionCount: 0,
            lastTransactionDate: DateTime.now(),
          );

          return BlocProvider(
            create: (context) => di.sl<ContactTransactionsCubit>(),
            child: ContactTransactionsScreen(contact: contact),
          );
        },
      ),

      GoRoute(
        path: Routes.receivedTransactionRequests,
        name: 'receivedTransactionRequests',
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<ReceivedTransactionRequestsCubit>(),
          child: const ReceivedTransactionRequestsScreen(),
        ),
      ),

      GoRoute(
        path: Routes.completionRequests,
        name: 'completionRequests',
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<CompletionRequestsCubit>(),
          child: const CompletionRequestsScreen(),
        ),
      ),

      GoRoute(
        path: Routes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
}