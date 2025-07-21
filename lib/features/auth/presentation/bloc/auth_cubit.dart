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
import 'package:udharoo/features/auth/domain/usecases/send_phone_verification_code_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/verify_phone_code_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_in_with_phone_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/link_phone_number_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/update_phone_number_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/check_phone_verification_status_usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInWithEmailUseCase signInWithEmailUseCase;
  final SignUpWithEmailUseCase signUpWithEmailUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignInWithPhoneUseCase signInWithPhoneUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final IsAuthenticatedUseCase isAuthenticatedUseCase;
  final SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase;
  final SendEmailVerificationUseCase sendEmailVerificationUseCase;
  final SendPhoneVerificationCodeUseCase sendPhoneVerificationCodeUseCase;
  final VerifyPhoneCodeUseCase verifyPhoneCodeUseCase;
  final LinkPhoneNumberUseCase linkPhoneNumberUseCase;
  final UpdatePhoneNumberUseCase updatePhoneNumberUseCase;
  final CheckPhoneVerificationStatusUseCase checkPhoneVerificationStatusUseCase;
  final AuthService authService;

  late final StreamSubscription<AuthUser?> _authStateSubscription;
  late final StreamSubscription<AuthEvent> _authEventSubscription;

  String? _currentPhoneNumber;
  bool _isLinkingPhone = false;
  bool _isUpdatingPhone = false;

  AuthCubit({
    required this.signInWithEmailUseCase,
    required this.signUpWithEmailUseCase,
    required this.signInWithGoogleUseCase,
    required this.signInWithPhoneUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.isAuthenticatedUseCase,
    required this.sendPasswordResetEmailUseCase,
    required this.sendEmailVerificationUseCase,
    required this.sendPhoneVerificationCodeUseCase,
    required this.verifyPhoneCodeUseCase,
    required this.linkPhoneNumberUseCase,
    required this.updatePhoneNumberUseCase,
    required this.checkPhoneVerificationStatusUseCase,
    required this.authService,
  }) : super(const AuthInitial()) {
    _authStateSubscription = authService.authStateChanges.listen(_handleAuthStateChange);
    _authEventSubscription = authService.authEventStream.listen(_handleAuthEvent);
    checkAuthStatus();
  }

  void _handleAuthStateChange(AuthUser? user) {
    if (!isClosed) {
      if (user != null) {
        if (!user.canAccessApp) {
          emit(PhoneVerificationRequired(user));
        } else if (state is! AuthAuthenticated || 
                   (state as AuthAuthenticated).user.uid != user.uid) {
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
        case PhoneVerificationRequiredEvent():
          checkAuthStatus();
          break;
        case PhoneVerificationCompletedEvent():
          checkAuthStatus();
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
        onSuccess: (user) {
          if (user.canAccessApp) {
            emit(AuthAuthenticated(user));
          } else {
            emit(PhoneVerificationRequired(user));
          }
        },
        onFailure: (message, type) => emit(AuthError(message, type)),
      );
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    emit(const AuthLoading());

    final result = await signUpWithEmailUseCase(email, password);

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(PhoneVerificationRequired(user)),
        onFailure: (message, type) => emit(AuthError(message, type)),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());

    final result = await signInWithGoogleUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (user) {
          if (user.canAccessApp) {
            emit(AuthAuthenticated(user));
          } else {
            emit(PhoneVerificationRequired(user));
          }
        },
        onFailure: (message, type) => emit(AuthError(message, type)),
      );
    }
  }

  Future<void> signInWithPhone(String phoneNumber, String password) async {
    emit(const AuthLoading());

    final result = await signInWithPhoneUseCase(phoneNumber, password);

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
            if (user.canAccessApp) {
              emit(AuthAuthenticated(user));
            } else {
              emit(PhoneVerificationRequired(user));
            }
          } else {
            emit(const AuthUnauthenticated());
          }
        },
        onFailure: (message, type) => emit(const AuthUnauthenticated()),
      );
    }
  }

  Future<void> sendPhoneVerificationCode(String phoneNumber, {bool isLinking = false, bool isUpdating = false}) async {
    _currentPhoneNumber = phoneNumber;
    _isLinkingPhone = isLinking;
    _isUpdatingPhone = isUpdating;
    
    emit(PhoneVerificationLoading(phoneNumber: phoneNumber));

    final result = await sendPhoneVerificationCodeUseCase(phoneNumber);

    if (!isClosed) {
      result.fold(
        onSuccess: (verificationId) {
          emit(PhoneCodeSent(
            phoneNumber: phoneNumber,
            verificationId: verificationId,
          ));
        },
        onFailure: (message, type) => emit(AuthError(message, type)),
      );
    }
  }

  Future<void> verifyPhoneCode(String verificationId, String smsCode) async {
    emit(PhoneVerificationLoading(
      phoneNumber: _currentPhoneNumber,
      verificationId: verificationId,
    ));

    ApiResult<AuthUser> result;

    if (_isLinkingPhone) {
      result = await linkPhoneNumberUseCase(verificationId, smsCode);
    } else if (_isUpdatingPhone) {
      result = await updatePhoneNumberUseCase(verificationId, smsCode);
    } else {
      result = await verifyPhoneCodeUseCase(verificationId, smsCode);
    }

    if (!isClosed) {
      result.fold(
        onSuccess: (user) {
          emit(PhoneVerificationCompleted(user));
          
          if (user.canAccessApp) {
            emit(AuthAuthenticated(user));
          }
        },
        onFailure: (message, type) => emit(AuthError(message, type)),
      );
    }

    _isLinkingPhone = false;
    _isUpdatingPhone = false;
    _currentPhoneNumber = null;
  }

  Future<void> linkPhoneNumber(String phoneNumber) async {
    await sendPhoneVerificationCode(phoneNumber, isLinking: true);
  }

  Future<void> updatePhoneNumber(String phoneNumber) async {
    await sendPhoneVerificationCode(phoneNumber, isUpdating: true);
  }

  Future<void> checkPhoneVerificationStatus() async {
    final result = await checkPhoneVerificationStatusUseCase();
    
    if (!isClosed) {
      result.fold(
        onSuccess: (isVerified) {
          if (isVerified) {
            checkAuthStatus();
          }
        },
        onFailure: (message, type) {},
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final result = await sendPasswordResetEmailUseCase(email);
    
    if (!isClosed) {
      result.fold(
        onSuccess: (_) {
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

  void skipPhoneVerification() {
    if (state is PhoneVerificationRequired && !isClosed) {
      final user = (state as PhoneVerificationRequired).user;
      emit(AuthAuthenticated(user.copyWith(isPhoneRequired: false)));
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