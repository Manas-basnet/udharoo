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
      AuthAuthenticated() => _handleAuthenticated(authState, currentPath),
      AuthUnauthenticated() => _handleUnauthenticated(currentPath),
      AuthError() => _handleError(currentPath),
    };
  }
  
  static String? _handleInitial(String currentPath) {
    return currentPath == Routes.splash ? null : Routes.splash;
  }
  
  static String? _handleLoading(String currentPath) {
    final phoneVerificationRoutes = [
      Routes.phoneSetup,
      Routes.phoneVerification,
    ];
    
    if (phoneVerificationRoutes.contains(currentPath)) {
      return null;
    }
    
    return currentPath == Routes.splash ? null : Routes.splash;
  }
  
  static String? _handleAuthenticated(AuthAuthenticated authState, String currentPath) {
    final publicRoutes = [Routes.login, Routes.splash];
    
    if (publicRoutes.contains(currentPath)) {
      if (authState.canUseApp) {
        return Routes.home;
      } else if (authState.needsPhoneVerification) {
        return Routes.phoneSetup;
      } else if (authState.needsProfileSetup) {
        return Routes.phoneSetup;
      }
    }
    
    final phoneVerificationRoutes = [Routes.phoneSetup, Routes.phoneVerification];
    
    if (authState.canUseApp && phoneVerificationRoutes.contains(currentPath)) {
      return Routes.home;
    }
    
    if (authState.needsPhoneVerification && !phoneVerificationRoutes.contains(currentPath)) {
      return Routes.phoneSetup;
    }
    
    if (authState.needsProfileSetup && !phoneVerificationRoutes.contains(currentPath)) {
      return Routes.phoneSetup;
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
    return currentPath == Routes.login ? null : Routes.login;
  }
}