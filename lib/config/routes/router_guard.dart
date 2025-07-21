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
      AuthAuthenticated() => _handleAuthenticated(currentPath),
      AuthUnauthenticated() => _handleUnauthenticated(currentPath),
      AuthError() => _handleError(currentPath),
      AuthPhoneVerificationRequired() => _handlePhoneVerificationRequired(currentPath),
      AuthProfileSetupRequired() => _handleProfileSetupRequired(currentPath),
    };
  }
  
  static String? _handleInitial(String currentPath) {
    return currentPath == Routes.splash ? null : Routes.splash;
  }
  
  static String? _handleLoading(String currentPath) {
    return currentPath == Routes.splash ? null : Routes.splash;
  }
  
  static String? _handleAuthenticated(String currentPath) {
    final publicRoutes = [Routes.login, Routes.splash];
    return publicRoutes.contains(currentPath) ? Routes.home : null;
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
    return currentPath == Routes.login ? null : Routes.login;
  }
  
  static String? _handlePhoneVerificationRequired(String currentPath) {
    final allowedRoutes = [Routes.phoneSetup, Routes.phoneVerification];
    return allowedRoutes.contains(currentPath) ? null : Routes.phoneSetup;
  }
  
  static String? _handleProfileSetupRequired(String currentPath) {
    final allowedRoutes = [Routes.phoneSetup, Routes.phoneVerification];
    return allowedRoutes.contains(currentPath) ? null : Routes.phoneSetup;
  }
}