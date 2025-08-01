import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:udharoo/config/routes/router_config.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/features/auth/presentation/bloc/sign_in/signin_cubit.dart';
import 'package:udharoo/features/phone_verification/presentation/bloc/phone_verification_cubit.dart';
import 'package:udharoo/shared/presentation/bloc/shorebird_update/shorebird_update_cubit.dart';
import 'package:udharoo/shared/presentation/bloc/theme_cubit/theme_cubit.dart';
import 'package:udharoo/core/theme/app_theme.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session/auth_session_cubit.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (context) => di.sl<ThemeCubit>()),
        BlocProvider<AuthSessionCubit>(
          create: (context) => di.sl<AuthSessionCubit>()..checkAuthStatus(),
        ),
        BlocProvider(create: (_) => di.sl<SignInCubit>()),
        BlocProvider(create: (_) => di.sl<PhoneVerificationCubit>()),

        BlocProvider<ShorebirdUpdateCubit>(
          create: (context) =>
              ShorebirdUpdateCubit(shorebird.ShorebirdUpdater())..checkForUpdates(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Udharoo',
            debugShowCheckedModeBanner: false,
            theme: themeState.isDarkMode
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}