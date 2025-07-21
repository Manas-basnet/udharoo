import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/config/routes/router_config.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/shared/presentation/bloc/theme_cubit/theme_cubit.dart';
import 'package:udharoo/core/theme/app_theme.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          AppRouter.router.refresh();
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
    return (previous is AuthInitial && current is AuthLoading) ||
        (previous is AuthLoading && current is AuthAuthenticated) ||
        (previous is AuthLoading && current is AuthUnauthenticated) ||
        (previous is AuthLoading && current is AuthError) ||
        (previous is AuthLoading && current is AuthPhoneVerificationRequired) ||
        (previous is AuthLoading && current is AuthProfileSetupRequired) ||
        (previous is AuthAuthenticated && current is AuthUnauthenticated) ||
        (previous is AuthAuthenticated && current is AuthPhoneVerificationRequired) ||
        (previous is AuthAuthenticated && current is AuthProfileSetupRequired) ||
        (previous is AuthUnauthenticated && current is AuthAuthenticated) ||
        (previous is AuthUnauthenticated && current is AuthPhoneVerificationRequired) ||
        (previous is AuthUnauthenticated && current is AuthProfileSetupRequired) ||
        (previous is AuthError && current is AuthAuthenticated) ||
        (previous is AuthError && current is AuthUnauthenticated) ||
        (previous is AuthError && current is AuthPhoneVerificationRequired) ||
        (previous is AuthError && current is AuthProfileSetupRequired) ||
        (previous is AuthPhoneVerificationRequired && current is AuthAuthenticated) ||
        (previous is AuthPhoneVerificationRequired && current is AuthUnauthenticated) ||
        (previous is AuthPhoneVerificationRequired && current is AuthError) ||
        (previous is AuthProfileSetupRequired && current is AuthAuthenticated) ||
        (previous is AuthProfileSetupRequired && current is AuthUnauthenticated) ||
        (previous is AuthProfileSetupRequired && current is AuthPhoneVerificationRequired) ||
        (previous is AuthProfileSetupRequired && current is AuthError);
  }
}