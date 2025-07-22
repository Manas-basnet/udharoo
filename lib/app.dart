import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/config/routes/router_config.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/shared/presentation/bloc/theme_cubit/theme_cubit.dart';
import 'package:udharoo/core/theme/app_theme.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _refreshTimer;

  void _scheduleRouterRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        try {
          AppRouter.router.refresh();
        } catch (e) {
          // Ignore router refresh errors during navigation
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (context) => di.sl<ThemeCubit>()),
        BlocProvider<AuthCubit>(create: (context) => di.sl<AuthCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) {
          if (previous.runtimeType == current.runtimeType) return false;
          return _shouldRefreshRouter(previous, current);
        },
        listener: (context, state) {
          _scheduleRouterRefresh();
        },
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            return MaterialApp.router(
              title: 'Udharoo',
              debugShowCheckedModeBanner: false,
              theme: state.isDarkMode
                  ? AppTheme.darkTheme
                  : AppTheme.lightTheme,
              routerConfig: AppRouter.router,
            );
          },
        ),
      ),
    );
  }

  bool _shouldRefreshRouter(AuthState previous, AuthState current) {
    if (previous is PhoneVerificationCompleted && current is AuthAuthenticated) {
      return false;
    }

    if (previous is PhoneVerificationLoading && current is AuthError) {
      return false;
    }

    if (previous is PhoneCodeSent && current is PhoneVerificationLoading) {
      return false;
    }

    return (previous is AuthInitial && current is AuthLoading) ||
        (previous is AuthLoading && current is AuthAuthenticated) ||
        (previous is AuthLoading && current is AuthUnauthenticated) ||
        (previous is AuthLoading && current is AuthError) ||
        (previous is AuthLoading && current is PhoneVerificationRequired) ||
        (previous is AuthAuthenticated && current is AuthUnauthenticated) ||
        (previous is AuthAuthenticated && current is PhoneVerificationRequired) ||
        (previous is AuthUnauthenticated && current is AuthAuthenticated) ||
        (previous is AuthUnauthenticated && current is PhoneVerificationRequired) ||
        (previous is AuthError && current is AuthAuthenticated) ||
        (previous is AuthError && current is AuthUnauthenticated) ||
        (previous is AuthError && current is PhoneVerificationRequired) ||
        (previous is PhoneVerificationRequired && current is AuthAuthenticated) ||
        (previous is PhoneVerificationRequired && current is AuthUnauthenticated) ||
        (previous is PhoneVerificationLoading && current is PhoneVerificationRequired) ||
        (previous is PhoneVerificationLoading && current is AuthAuthenticated) ||
        (previous is PhoneCodeSent && current is AuthError) ||
        (previous is PhoneCodeSent && current is AuthAuthenticated) ||
        (previous is PhoneVerificationCompleted && current is AuthError);
  }
}