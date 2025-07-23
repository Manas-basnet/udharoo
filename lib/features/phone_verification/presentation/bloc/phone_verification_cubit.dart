import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/usecases/send_phone_verification_code_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/verify_phone_code_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/link_phone_number_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/update_phone_number_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/check_phone_verification_status_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/send_email_verification_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/check_email_verification_status_usecase.dart';

part 'phone_verification_state.dart';

class PhoneVerificationCubit extends Cubit<PhoneVerificationState> {
  final SendPhoneVerificationCodeUseCase sendPhoneVerificationCodeUseCase;
  final VerifyPhoneCodeUseCase verifyPhoneCodeUseCase;
  final LinkPhoneNumberUseCase linkPhoneNumberUseCase;
  final UpdatePhoneNumberUseCase updatePhoneNumberUseCase;
  final CheckPhoneVerificationStatusUseCase checkPhoneVerificationStatusUseCase;
  final SendEmailVerificationUseCase sendEmailVerificationUseCase;
  final CheckEmailVerificationStatusUseCase checkEmailVerificationStatusUseCase;

  String? _currentPhoneNumber;
  String? _currentVerificationId;
  String? _pendingPhoneNumber;
  bool _isLinkingPhone = false;
  bool _isUpdatingPhone = false;
  bool _isChangingPhone = false;

  PhoneVerificationCubit({
    required this.sendPhoneVerificationCodeUseCase,
    required this.verifyPhoneCodeUseCase,
    required this.linkPhoneNumberUseCase,
    required this.updatePhoneNumberUseCase,
    required this.checkPhoneVerificationStatusUseCase,
    required this.sendEmailVerificationUseCase,
    required this.checkEmailVerificationStatusUseCase,
  }) : super(const PhoneVerificationInitial());

  Future<void> sendPhoneVerificationCode(String phoneNumber, {bool isLinking = false, bool isUpdating = false}) async {
    _currentPhoneNumber = phoneNumber;
    _isLinkingPhone = isLinking;
    _isUpdatingPhone = isUpdating || _isChangingPhone;
    
    emit(PhoneVerificationLoading(phoneNumber: phoneNumber));

    final result = await sendPhoneVerificationCodeUseCase(phoneNumber);

    if (!isClosed) {
      result.fold(
        onSuccess: (verificationId) {
          _currentVerificationId = verificationId;
          if (verificationId == 'auto-verified') {
            emit(const PhoneVerificationAutoCompleted());
          } else {
            emit(PhoneCodeSent(
              phoneNumber: phoneNumber,
              verificationId: verificationId,
            ));
          }
        },
        onFailure: (message, type) {
          _resetPhoneVerificationState();
          emit(PhoneVerificationError(message, type));
        },
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
    } else if (_isUpdatingPhone || _isChangingPhone) {
      result = await updatePhoneNumberUseCase(verificationId, smsCode);
    } else {
      result = await verifyPhoneCodeUseCase(verificationId, smsCode);
    }

    if (!isClosed) {
      result.fold(
        onSuccess: (user) {
          _resetPhoneVerificationState();
          emit(PhoneVerificationCompleted(user));
        },
        onFailure: (message, type) {
          _resetPhoneVerificationState();
          emit(PhoneVerificationError(message, type));
        },
      );
    }
  }

  Future<void> linkPhoneNumber(String phoneNumber) async {
    await sendPhoneVerificationCode(phoneNumber, isLinking: true);
  }

  Future<void> updatePhoneNumber(String phoneNumber) async {
    await sendPhoneVerificationCode(phoneNumber, isUpdating: true);
  }

  void startPhoneNumberChange(String newPhoneNumber) {
    _pendingPhoneNumber = newPhoneNumber;
    _isChangingPhone = true;
  }

  void cancelPhoneNumberChange() {
    _pendingPhoneNumber = null;
    _isChangingPhone = false;
    _resetPhoneVerificationState();
    emit(const PhoneVerificationInitial());
  }

  Future<void> checkPhoneVerificationStatus() async {
    final result = await checkPhoneVerificationStatusUseCase();
    
    if (!isClosed) {
      result.fold(
        onSuccess: (isVerified) {
          emit(PhoneVerificationStatusChecked(isVerified));
        },
        onFailure: (message, type) => emit(PhoneVerificationError(message, type)),
      );
    }
  }

  Future<void> sendEmailVerification() async {
    final result = await sendEmailVerificationUseCase();
    
    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(const EmailVerificationSent()),
        onFailure: (message, type) => emit(PhoneVerificationError(message, type)),
      );
    }
  }

  Future<void> checkEmailVerificationStatus() async {
    final result = await checkEmailVerificationStatusUseCase();
    
    if (!isClosed) {
      result.fold(
        onSuccess: (user) {
          if (user != null) {
            emit(EmailVerificationStatusChecked(user));
          }
        },
        onFailure: (message, type) => emit(PhoneVerificationError(message, type)),
      );
    }
  }

  void retryPhoneVerification() {
    if (_currentPhoneNumber != null) {
      sendPhoneVerificationCode(_currentPhoneNumber!);
    }
  }

  void resetState() {
    _resetPhoneVerificationState();
    if (!isClosed) {
      emit(const PhoneVerificationInitial());
    }
  }

  String? get pendingPhoneNumber => _pendingPhoneNumber;
  bool get isChangingPhoneNumber => _isChangingPhone;

  bool get isPhoneVerificationInProgress {
    return state is PhoneVerificationLoading || 
           state is PhoneCodeSent || 
           _currentVerificationId != null;
  }

  void _resetPhoneVerificationState() {
    _currentPhoneNumber = null;
    _currentVerificationId = null;
    _isLinkingPhone = false;
    _isUpdatingPhone = false;
  }
}