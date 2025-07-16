import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/events/auth_event.dart';
import 'package:udharoo/features/auth/domain/services/auth_service.dart';
import 'package:udharoo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/is_authenticated_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/send_email_verification_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_up_with_email_usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInWithEmailUseCase signInWithEmailUseCase;
  final SignUpWithEmailUseCase signUpWithEmailUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final IsAuthenticatedUseCase isAuthenticatedUseCase;
  final SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase;
  final SendEmailVerificationUseCase sendEmailVerificationUseCase;
  final AuthService authService;

  late final StreamSubscription<AuthUser?> _authStateSubscription;
  late final StreamSubscription<AuthEvent> _authEventSubscription;

  AuthCubit({
    required this.signInWithEmailUseCase,
    required this.signUpWithEmailUseCase,
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.isAuthenticatedUseCase,
    required this.sendPasswordResetEmailUseCase,
    required this.sendEmailVerificationUseCase,
    required this.authService,
  }) : super(const AuthInitial()) {
    _authStateSubscription = authService.authStateChanges.listen(_handleAuthStateChange);
    _authEventSubscription = authService.authEventStream.listen(_handleAuthEvent);
    checkAuthStatus();
  }

  void _handleAuthStateChange(AuthUser? user) {
    if (!isClosed) {
      if (user != null) {
        if (state is! AuthAuthenticated || (state as AuthAuthenticated).user.uid != user.uid) {
          emit(AuthAuthenticated(user));
        }
      } else {
        if (state is! AuthUnauthenticated) {
          emit(const AuthUnauthenticated());
        }
      }
    }
  }

  void _handleAuthEvent(AuthEvent event) {
    if (!isClosed) {
      switch (event) {
        case ForceLogoutEvent():
          if (state is! AuthUnauthenticated) {
            emit(const AuthUnauthenticated());
          }
          break;
        case AuthenticationFailedEvent():
          emit(AuthError(event.reason, FailureType.auth));
          break;
        default:
          break;
      }
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(const AuthLoading());

    final result = await signInWithEmailUseCase(email, password);

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(AuthAuthenticated(user)),
        onFailure: (message, type) => emit(AuthError(message, type)),
      );
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    emit(const AuthLoading());

    final result = await signUpWithEmailUseCase(email, password);

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(AuthAuthenticated(user)),
        onFailure: (message, type) => emit(AuthError(message, type)),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());

    final result = await signInWithGoogleUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(AuthAuthenticated(user)),
        onFailure: (message, type) => emit(AuthError(message, type)),
      );
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());

    final result = await signOutUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(const AuthUnauthenticated()),
        onFailure: (message, type) => emit(const AuthUnauthenticated()),
      );
    }
  }

  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());

    final result = await getCurrentUserUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (user) {
          if (user != null) {
            emit(AuthAuthenticated(user));
          } else {
            emit(const AuthUnauthenticated());
          }
        },
        onFailure: (message, type) => emit(const AuthUnauthenticated()),
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final result = await sendPasswordResetEmailUseCase(email);
    
    if (!isClosed) {
      result.fold(
        onSuccess: (_) {
          // Handle success (maybe show a success message)
        },
        onFailure: (message, type) => emit(AuthError(message, type)),
      );
    }
  }

  Future<void> sendEmailVerification() async {
    final result = await sendEmailVerificationUseCase();
    
    if (!isClosed) {
      result.fold(
        onSuccess: (_) {
          // Handle success (maybe show a success message)
        },
        onFailure: (message, type) => emit(AuthError(message, type)),
      );
    }
  }

  void resetError() {
    if (state is AuthError && !isClosed) {
      emit(const AuthInitial());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    _authEventSubscription.cancel();
    authService.dispose();
    return super.close();
  }
}