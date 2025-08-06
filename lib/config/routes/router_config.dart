import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/features/auth/presentation/pages/login_screen.dart';
import 'package:udharoo/features/auth/presentation/pages/profile_completion_screen.dart';
import 'package:udharoo/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/contacts/presentation/pages/contact_borrowed_transactions_page.dart';
import 'package:udharoo/features/contacts/presentation/pages/contact_lent_transactions_page.dart';
import 'package:udharoo/features/contacts/presentation/pages/contact_transactions_page.dart';
import 'package:udharoo/features/contacts/presentation/pages/contacts_page.dart';
import 'package:udharoo/features/phone_verification/presentation/pages/phone_setup_screen.dart';
import 'package:udharoo/features/phone_verification/presentation/pages/phone_verification_screen.dart';
import 'package:udharoo/features/phone_verification/presentation/pages/change_phone_setup_screen.dart';
import 'package:udharoo/features/phone_verification/presentation/pages/change_phone_verification_screen.dart';
import 'package:udharoo/features/home/presentation/pages/home_screen.dart';
import 'package:udharoo/features/profile/presentation/pages/profile_screen.dart';
import 'package:udharoo/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/qr_generator/qr_generator_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/qr_scanner/qr_scanner_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_form/transaction_form_cubit.dart';
import 'package:udharoo/features/transactions/presentation/pages/qr/qr_generartor_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/qr/qr_scanner_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_form_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_detail_screen.dart';
import 'package:udharoo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:udharoo/features/transactions/presentation/pages/rejected_transactions_page.dart';
import 'package:udharoo/features/transactions/presentation/pages/lent_transactions_page.dart';
import 'package:udharoo/features/transactions/presentation/pages/borrowed_transactions_page.dart';
import 'package:udharoo/shared/presentation/bloc/multi_select_mode/multi_select_mode_cubit.dart';
import 'package:udharoo/shared/presentation/layouts/scaffold_with_bottom_nav_bar.dart';
import 'package:udharoo/shared/presentation/widgets/auth_wrapper.dart';

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

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AuthWrapper(
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => di.sl<ContactCubit>()),
                BlocProvider(create: (_) => di.sl<TransactionCubit>()..loadTransactions()),
                BlocProvider(create: (_) => MultiSelectModeCubit()),
              ],
              child: ScaffoldWithBottomNavBar(navigationShell: navigationShell),
            ),
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
                routes: [
                  GoRoute(
                    path: '/transaction-detail',
                    name: 'homeTransactionDetail',
                    builder: (context, state) {
                      final transaction = state.extra as Transaction;
                      return TransactionDetailScreen(
                        transaction: transaction,
                      );
                    },
                  ),
                ]
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
              ShellRoute(
                builder: (context, state, child) {
                  return child;
                },
                routes: [
                  GoRoute(
                    path: Routes.transactions,
                    name: 'transactions',
                    builder: (context, state) => const TransactionsPage(),
                    routes: [
                      GoRoute(
                        path: '/lent',
                        name: 'lentTransactions',
                        builder: (context, state) => const LentTransactionsPage(),
                      ),
                      GoRoute(
                        path: '/borrowed',
                        name: 'borrowedTransactions',
                        builder: (context, state) => const BorrowedTransactionsPage(),
                      ),
                      GoRoute(
                        path: '/transaction-form',
                        name: 'transactionForm',
                        builder: (context, state) {
                          QRTransactionData? qrData;
                          Contact? prefilledContact;
                          TransactionType? initialTransactionType;

                          final extra = state.extra;
                          if (extra is TransactionFormExtra) {
                            qrData = extra.qrData;
                            prefilledContact = extra.prefilledContact;
                            initialTransactionType = extra.initialTransactionType;
                          }

                          return MultiBlocProvider(
                            providers: [
                              BlocProvider(create: (_) => di.sl<TransactionFormCubit>()),
                            ],
                            child: TransactionFormScreen(
                              qrData: qrData, 
                              prefilledContact: prefilledContact,
                              initialTransactionType: initialTransactionType,
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: '/rejected-transactions',
                        name: 'rejectedTransactions',
                        builder: (context, state) =>
                            const RejectedTransactionsPage(),
                      ),
                      GoRoute(
                        path: '/transaction-detail',
                        name: 'transactionDetail',
                        builder: (context, state) {
                          final transaction = state.extra as Transaction;
                          return TransactionDetailScreen(
                            transaction: transaction,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: _contactsNavigatorKey,
            routes: [
              ShellRoute(
                builder: (context, state, child) {
                  return child;
                },
                routes: [
                  GoRoute(
                    path: Routes.contacts,
                    name: 'contacts',
                    builder: (context, state) => const ContactsPage(),
                    routes: [
                      GoRoute(
                        path: '/contact-transactions',
                        name: 'contactTransactions',
                        builder: (context, state) {
                          final contactUserId = state.uri.queryParameters['contactUserId'];
                          
                          if (contactUserId == null || contactUserId.isEmpty) {
                            return Scaffold(
                              body: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Invalid Contact',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Contact ID is required',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () => context.go(Routes.contacts),
                                      child: const Text('Go Back'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return MultiBlocProvider(
                            providers: [
                              BlocProvider(create: (_) => di.sl<ContactTransactionsCubit>()),
                            ],
                            child: ContactTransactionsPage(contactUserId: contactUserId),
                          );
                        },
                        routes: [
                          GoRoute(
                            path: '/lent',
                            name: 'contactLentTransactions',
                            builder: (context, state) {
                              final contactUserId = state.uri.queryParameters['contactUserId'];
                              
                              if (contactUserId == null || contactUserId.isEmpty) {
                                return Scaffold(
                                  body: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Invalid Contact',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Contact ID is required',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton(
                                          onPressed: () => context.go(Routes.contacts),
                                          child: const Text('Go Back'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return MultiBlocProvider(
                                providers: [
                                  BlocProvider(create: (_) => di.sl<ContactTransactionsCubit>()),
                                ],
                                child: ContactLentTransactionsPage(contactUserId: contactUserId),
                              );
                            },
                          ),
                          GoRoute(
                            path: '/borrowed',
                            name: 'contactBorrowedTransactions',
                            builder: (context, state) {
                              final contactUserId = state.uri.queryParameters['contactUserId'];
                              
                              if (contactUserId == null || contactUserId.isEmpty) {
                                return Scaffold(
                                  body: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Invalid Contact',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Contact ID is required',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton(
                                          onPressed: () => context.go(Routes.contacts),
                                          child: const Text('Go Back'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return MultiBlocProvider(
                                providers: [
                                  BlocProvider(create: (_) => di.sl<ContactTransactionsCubit>()),
                                ],
                                child: ContactBorrowedTransactionsPage(contactUserId: contactUserId),
                              );
                            },
                          ),
                        
                          GoRoute(
                            path: '/transaction-detail',
                            name: 'contactTransactionDetail',
                            builder: (context, state) {
                              final transaction = state.extra as Transaction;
                              return TransactionDetailScreen(
                                transaction: transaction,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
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
        path: Routes.qrGenerator,
        name: 'qrGenerator',
        builder: (context, state) => BlocProvider(
          create: (_) => di.sl<QRGeneratorCubit>(),
          child: const QRGeneratorScreen(),
        ),
      ),

      GoRoute(
        path: Routes.qrScanner,
        name: 'qrScanner',
        builder: (context, state) => BlocProvider(
          create: (_) => di.sl<QRScannerCubit>(),
          child: const QRScannerScreen(),
        ),
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
        path: Routes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
}