part of 'auth_cubit.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final AuthUser user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  final String message;
  final FailureType type;

  const AuthError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}

final class PhoneVerificationRequired extends AuthState {
  final AuthUser user;

  const PhoneVerificationRequired(this.user);

  @override
  List<Object?> get props => [user];
}

final class PhoneVerificationLoading extends AuthState {
  final String? phoneNumber;
  final String? verificationId;

  const PhoneVerificationLoading({this.phoneNumber, this.verificationId});

  @override
  List<Object?> get props => [phoneNumber, verificationId];
}

final class PhoneCodeSent extends AuthState {
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

final class PhoneVerificationCompleted extends AuthState {
  final AuthUser user;

  const PhoneVerificationCompleted(this.user);

  @override
  List<Object?> get props => [user];
}