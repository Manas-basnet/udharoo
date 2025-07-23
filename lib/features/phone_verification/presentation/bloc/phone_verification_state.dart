part of 'phone_verification_cubit.dart';

sealed class PhoneVerificationState extends Equatable {
  const PhoneVerificationState();

  @override
  List<Object?> get props => [];
}

final class PhoneVerificationInitial extends PhoneVerificationState {
  const PhoneVerificationInitial();
}

final class PhoneVerificationLoading extends PhoneVerificationState {
  final String? phoneNumber;
  final String? verificationId;

  const PhoneVerificationLoading({this.phoneNumber, this.verificationId});

  @override
  List<Object?> get props => [phoneNumber, verificationId];
}

final class PhoneCodeSent extends PhoneVerificationState {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const PhoneCodeSent({
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  List<Object?> get props => [phoneNumber, verificationId, resendToken];
}

final class PhoneCodeResent extends PhoneVerificationState {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const PhoneCodeResent({
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  List<Object?> get props => [phoneNumber, verificationId, resendToken];
}

final class PhoneVerificationCompleted extends PhoneVerificationState {
  final AuthUser user;

  const PhoneVerificationCompleted(this.user);

  @override
  List<Object?> get props => [user];
}

final class PhoneVerificationAutoCompleted extends PhoneVerificationState {
  const PhoneVerificationAutoCompleted();
}

final class PhoneVerificationError extends PhoneVerificationState {
  final String message;
  final FailureType type;

  const PhoneVerificationError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}

final class PhoneVerificationStatusChecked extends PhoneVerificationState {
  final bool isVerified;

  const PhoneVerificationStatusChecked(this.isVerified);

  @override
  List<Object?> get props => [isVerified];
}

final class EmailVerificationSent extends PhoneVerificationState {
  const EmailVerificationSent();
}

final class EmailVerificationStatusChecked extends PhoneVerificationState {
  final AuthUser user;

  const EmailVerificationStatusChecked(this.user);

  @override
  List<Object?> get props => [user];
}