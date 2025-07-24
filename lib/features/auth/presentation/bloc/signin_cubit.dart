import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_in_with_phone_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_up_with_full_info_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_up_with_complete_info_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/link_google_account_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/link_password_usecase.dart';

part 'signin_state.dart';

class SignInCubit extends Cubit<SignInState> {
  final SignInWithEmailUseCase signInWithEmailUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignInWithPhoneUseCase signInWithPhoneUseCase;
  final SignUpWithEmailUseCase signUpWithEmailUseCase;
  final SignUpWithFullInfoUseCase signUpWithFullInfoUseCase;
  final SignUpWithCompleteInfoUseCase signUpWithCompleteInfoUseCase;
  final CompleteProfileUseCase completeProfileUseCase;
  final SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase;
  final LinkGoogleAccountUseCase linkGoogleAccountUseCase;
  final LinkPasswordUseCase linkPasswordUseCase;

  SignInCubit({
    required this.signInWithEmailUseCase,
    required this.signInWithGoogleUseCase,
    required this.signInWithPhoneUseCase,
    required this.signUpWithEmailUseCase,
    required this.signUpWithFullInfoUseCase,
    required this.signUpWithCompleteInfoUseCase,
    required this.completeProfileUseCase,
    required this.sendPasswordResetEmailUseCase,
    required this.linkGoogleAccountUseCase,
    required this.linkPasswordUseCase,
  }) : super(const SignInInitial());

  Future<void> signInWithEmail(String email, String password) async {
    emit(const SignInLoading());

    final result = await signInWithEmailUseCase(email, password);

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(SignInSuccess(user)),
        onFailure: (message, type) => emit(SignInError(message, type)),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const SignInLoading());

    final result = await signInWithGoogleUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(SignInSuccess(user)),
        onFailure: (message, type) => emit(SignInError(message, type)),
      );
    }
  }

  Future<void> signInWithPhone(String phoneNumber, String password) async {
    emit(const SignInLoading());

    final result = await signInWithPhoneUseCase(phoneNumber, password);

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(SignInSuccess(user)),
        onFailure: (message, type) => emit(SignInError(message, type)),
      );
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    emit(const SignInLoading());

    final result = await signUpWithEmailUseCase(email, password);

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(SignUpSuccess(user)),
        onFailure: (message, type) => emit(SignInError(message, type)),
      );
    }
  }

  Future<void> signUpWithFullInfo({
    required String fullName,
    required String email,
    required String password,
  }) async {
    emit(const SignInLoading());

    final result = await signUpWithFullInfoUseCase(
      fullName: fullName,
      email: email,
      password: password,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(SignUpSuccess(user)),
        onFailure: (message, type) => emit(SignInError(message, type)),
      );
    }
  }

  Future<void> signUpWithCompleteInfo({
    required String firstName,
    required String lastName,
    required String fullName,
    required String email,
    required String password,
    required DateTime birthDate,
  }) async {
    emit(const SignInLoading());

    final result = await signUpWithCompleteInfoUseCase(
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      email: email,
      password: password,
      birthDate: birthDate,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(SignUpSuccess(user)),
        onFailure: (message, type) => emit(SignInError(message, type)),
      );
    }
  }

  Future<void> completeProfile({
    required String fullName,
    required DateTime birthDate,
  }) async {
    emit(const SignInLoading());

    final result = await completeProfileUseCase(
      fullName: fullName,
      birthDate: birthDate,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(ProfileCompleted(user)),
        onFailure: (message, type) => emit(SignInError(message, type)),
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final result = await sendPasswordResetEmailUseCase(email);
    
    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(const PasswordResetSent()),
        onFailure: (message, type) => emit(SignInError(message, type)),
      );
    }
  }

  Future<void> linkGoogleAccount() async {
    emit(const SignInLoading());

    final result = await linkGoogleAccountUseCase();
    
    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(GoogleAccountLinked(user)),
        onFailure: (message, type) => emit(SignInError(message, type)),
      );
    }
  }

  Future<void> linkPassword(String password) async {
    emit(const SignInLoading());

    final result = await linkPasswordUseCase(password);
    
    if (!isClosed) {
      result.fold(
        onSuccess: (user) => emit(PasswordLinked(user)),
        onFailure: (message, type) => emit(SignInError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const SignInInitial());
    }
  }
}