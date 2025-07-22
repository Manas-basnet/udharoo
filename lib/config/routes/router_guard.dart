import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';

class RouterGuard {
  static String? handleRedirect(BuildContext context, GoRouterState state) {
    final authState = context.read<AuthCubit>().state;
    final currentPath = state.matchedLocation;
    
    return switch (authState) {
      AuthInitial() => _handleInitial(currentPath),
      AuthLoading() => _handleLoading(currentPath),
      AuthAuthenticated() => _handleAuthenticated(currentPath, authState),
      AuthUnauthenticated() => _handleUnauthenticated(currentPath),
      AuthError() => _handleError(currentPath),
      PhoneVerificationRequired() => _handlePhoneVerificationRequired(currentPath, authState),
      PhoneVerificationLoading() => _handlePhoneVerificationLoading(currentPath),
      PhoneCodeSent() => _handlePhoneCodeSent(currentPath),
      PhoneVerificationCompleted() => _handlePhoneVerificationCompleted(currentPath),
    };
  }
  
  static String? _handleInitial(String currentPath) {
    return currentPath == Routes.splash ? null : Routes.splash;
  }
  
  static String? _handleLoading(String currentPath) {
    return currentPath == Routes.splash ? null : Routes.splash;
  }
  
  static String? _handleAuthenticated(String currentPath, AuthAuthenticated authState) {
    final publicRoutes = [Routes.login, Routes.signUp, Routes.splash];
    
    if (publicRoutes.contains(currentPath)) {
      return Routes.home;
    }
    
    if (!authState.user.phoneVerified || !authState.user.canAccessApp) {
      final phoneRoutes = [Routes.phoneSetup, Routes.phoneVerification];
      if (!phoneRoutes.contains(currentPath)) {
        return Routes.phoneSetup;
      }
    } else {
      if (currentPath == Routes.phoneSetup || currentPath == Routes.phoneVerification) {
        return Routes.home;
      }
    }
    
    return null;
  }
  
  static String? _handleUnauthenticated(String currentPath) {
    final protectedRoutes = [
      Routes.home, 
      Routes.transactions, 
      Routes.contacts, 
      Routes.profile,
      Routes.phoneSetup,
      Routes.phoneVerification,
    ];
    if (protectedRoutes.contains(currentPath) || currentPath == Routes.splash) {
      return Routes.login;
    }
    return null;
  }
  
  static String? _handleError(String currentPath) {
    final phoneVerificationRoutes = [Routes.phoneSetup, Routes.phoneVerification];
    final authRoutes = [Routes.login, Routes.signUp];
    
    if (phoneVerificationRoutes.contains(currentPath) || authRoutes.contains(currentPath)) {
      return null;
    }
    return Routes.login;
  }

  static String? _handlePhoneVerificationRequired(String currentPath, PhoneVerificationRequired authState) {
    final phoneVerificationRoutes = [Routes.phoneSetup, Routes.phoneVerification];
    
    if (phoneVerificationRoutes.contains(currentPath)) {
      return null;
    }
    
    if (authState.user.phoneNumber != null) {
      return Routes.phoneSetup;
    }
    
    return Routes.phoneSetup;
  }

  static String? _handlePhoneVerificationLoading(String currentPath) {
    final allowedRoutes = [Routes.phoneSetup, Routes.phoneVerification, Routes.splash];
    return allowedRoutes.contains(currentPath) ? null : Routes.phoneSetup;
  }

  static String? _handlePhoneCodeSent(String currentPath) {
    return currentPath == Routes.phoneVerification ? null : Routes.phoneVerification;
  }

  static String? _handlePhoneVerificationCompleted(String currentPath) {
    final verificationRoutes = [Routes.login, Routes.signUp, Routes.splash, Routes.phoneSetup, Routes.phoneVerification];
    return verificationRoutes.contains(currentPath) ? Routes.home : null;
  }
}