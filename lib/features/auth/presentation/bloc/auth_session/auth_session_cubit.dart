import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/events/auth_event.dart';
import 'package:udharoo/features/auth/domain/services/auth_service.dart';
import 'package:udharoo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/update_display_name_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/check_email_verification_status_usecase.dart';

part 'auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthSessionState> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SignOutUseCase signOutUseCase;
  final UpdateDisplayNameUseCase updateDisplayNameUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final CheckEmailVerificationStatusUseCase checkEmailVerificationStatusUseCase;
  final AuthService authService;

  late final StreamSubscription<AuthUser?> _authStateSubscription;
  late final StreamSubscription<AuthEvent> _authEventSubscription;

  AuthSessionCubit({
    required this.getCurrentUserUseCase,
    required this.signOutUseCase,
    required this.updateDisplayNameUseCase,
    required this.changePasswordUseCase,
    required this.checkEmailVerificationStatusUseCase,
    required this.authService,
  }) : super(const AuthSessionLoading()) {
    _authStateSubscription = authService.authStateChanges.listen(_handleAuthStateChange);
    _authEventSubscription = authService.authEventStream.listen(_handleAuthEvent);
  }

  void _handleAuthStateChange(AuthUser? user) {
    if (!isClosed) {
      if (user != null) {
        emit(AuthSessionAuthenticated(user));
      } else {
        emit(const AuthSessionUnauthenticated());
      }
    }
  }

  void _handleAuthEvent(AuthEvent event) {
    if (!isClosed) {
      switch (event) {
        case ForceLogoutEvent():
          emit(const AuthSessionUnauthenticated());
          break;
        case AuthenticationFailedEvent():
          emit(AuthSessionError(event.reason, FailureType.auth));
          break;
        default:
          break;
      }
    }
  }

  Future<void> checkAuthStatus() async {
    emit(const AuthSessionLoading());

    final result = await getCurrentUserUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (user) {
          if (user != null) {
            emit(AuthSessionAuthenticated(user));
          } else {
            emit(const AuthSessionUnauthenticated());
          }
        },
        onFailure: (message, type) => emit(const AuthSessionUnauthenticated()),
      );
    }
  }

  void setUser(AuthUser user) {
    if (!isClosed) {
      emit(AuthSessionAuthenticated(user));
    }
  }

  Future<void> signOut() async {
    emit(const AuthSessionLoading());

    final result = await signOutUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(const AuthSessionUnauthenticated()),
        onFailure: (message, type) => emit(const AuthSessionUnauthenticated()),
      );
    }
  }

  Future<void> refreshUserData() async {
    final result = await checkEmailVerificationStatusUseCase();
    
    if (!isClosed) {
      result.fold(
        onSuccess: (user) {
          if (user != null) {
            emit(AuthSessionAuthenticated(user));
          }
        },
        onFailure: (message, type) {},
      );
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final currentState = state;
    if (currentState is! AuthSessionAuthenticated) return;

    final result = await updateDisplayNameUseCase(displayName);
    
    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(AuthSessionAuthenticated(user)),
        onFailure: (message, type) => emit(AuthSessionError(message, type)),
      );
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await changePasswordUseCase(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    
    if (!isClosed) {
      return result.isSuccess;
    }
    return false;
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    _authEventSubscription.cancel();
    authService.dispose();
    return super.close();
  }
}