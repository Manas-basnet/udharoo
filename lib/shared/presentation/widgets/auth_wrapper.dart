import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session/auth_session_cubit.dart';
import 'package:udharoo/features/auth/presentation/pages/login_screen.dart';
import 'package:udharoo/features/auth/presentation/pages/profile_completion_screen.dart';
import 'package:udharoo/features/phone_verification/presentation/pages/phone_setup_screen.dart';
import 'package:udharoo/shared/presentation/pages/splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthSessionCubit, AuthSessionState>(
      builder: (context, state) {
        return switch (state) {
          AuthSessionLoading() => const SplashScreen(),
          AuthSessionUnauthenticated() => const LoginScreen(),
          AuthSessionAuthenticated() when !state.user.isProfileComplete => 
            const ProfileCompletionScreen(),
          AuthSessionAuthenticated() when !state.user.canAccessApp => 
            const PhoneVerificationFlow(),
          AuthSessionAuthenticated() => child,
          AuthSessionError() => const LoginScreen(),
        };
      },
    );
  }
}

class PhoneVerificationFlow extends StatelessWidget {
  const PhoneVerificationFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const PhoneSetupScreen();
  }
}