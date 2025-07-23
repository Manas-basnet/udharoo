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
  PhoneVerificationMode _currentMode = PhoneVerificationMode.standard;

  PhoneVerificationCubit({
    required this.sendPhoneVerificationCodeUseCase,
    required this.verifyPhoneCodeUseCase,
    required this.linkPhoneNumberUseCase,
    required this.updatePhoneNumberUseCase,
    required this.checkPhoneVerificationStatusUseCase,
    required this.sendEmailVerificationUseCase,
    required this.checkEmailVerificationStatusUseCase,
  }) : super(const PhoneVerificationInitial());

  Future<void> sendPhoneVerificationCode(String phoneNumber) async {
    _currentPhoneNumber = phoneNumber;
    _currentMode = PhoneVerificationMode.standard;
    
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
          _resetState();
          emit(PhoneVerificationError(message, type));
        },
      );
    }
  }

  Future<void> linkPhoneNumber(String phoneNumber) async {
    _currentPhoneNumber = phoneNumber;
    _currentMode = PhoneVerificationMode.linking;
    
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
          _resetState();
          emit(PhoneVerificationError(message, type));
        },
      );
    }
  }

  Future<void> updatePhoneNumber(String phoneNumber) async {
    _currentPhoneNumber = phoneNumber;
    _currentMode = PhoneVerificationMode.updating;
    
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
          _resetState();
          emit(PhoneVerificationError(message, type));
        },
      );
    }
  }

  Future<void> resendPhoneVerificationCode() async {
    if (_currentPhoneNumber != null) {
      emit(PhoneVerificationLoading(phoneNumber: _currentPhoneNumber));

      final result = await sendPhoneVerificationCodeUseCase(_currentPhoneNumber!);

      if (!isClosed) {
        result.fold(
          onSuccess: (verificationId) {
            _currentVerificationId = verificationId;
            if (verificationId == 'auto-verified') {
              emit(const PhoneVerificationAutoCompleted());
            } else {
              emit(PhoneCodeResent(
                phoneNumber: _currentPhoneNumber!,
                verificationId: verificationId,
              ));
            }
          },
          onFailure: (message, type) {
            emit(PhoneVerificationError(message, type));
          },
        );
      }
    }
  }

  Future<void> verifyPhoneCode(String verificationId, String smsCode) async {
    emit(PhoneVerificationLoading(
      phoneNumber: _currentPhoneNumber,
      verificationId: verificationId,
    ));

    ApiResult<AuthUser> result;
    
    switch (_currentMode) {
      case PhoneVerificationMode.linking:
        result = await linkPhoneNumberUseCase(verificationId, smsCode);
        break;
      case PhoneVerificationMode.updating:
        result = await updatePhoneNumberUseCase(verificationId, smsCode);
        break;
      case PhoneVerificationMode.standard:
      result = await verifyPhoneCodeUseCase(verificationId, smsCode);
        break;
    }

    if (!isClosed) {
      result.fold(
        onSuccess: (user) {
          _resetState();
          emit(PhoneVerificationCompleted(user));
        },
        onFailure: (message, type) {
          emit(PhoneVerificationError(message, type));
        },
      );
    }
  }

  void startPhoneNumberChange(String newPhoneNumber) {
    _pendingPhoneNumber = newPhoneNumber;
  }

  void cancelPhoneNumberChange() {
    _pendingPhoneNumber = null;
    _resetState();
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

  void resetState() {
    _resetState();
    if (!isClosed) {
      emit(const PhoneVerificationInitial());
    }
  }

  String? get pendingPhoneNumber => _pendingPhoneNumber;
  bool get isChangingPhoneNumber => _pendingPhoneNumber != null;

  bool get isPhoneVerificationInProgress {
    return state is PhoneVerificationLoading || 
           state is PhoneCodeSent || 
           state is PhoneCodeResent ||
           _currentVerificationId != null;
  }

  void _resetState() {
    _currentPhoneNumber = null;
    _currentVerificationId = null;
    _currentMode = PhoneVerificationMode.standard;
  }
}

enum PhoneVerificationMode {
  standard,
  linking,
  updating,
}