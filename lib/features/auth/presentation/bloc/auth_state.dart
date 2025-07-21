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
  final UserProfile profile;

  const AuthAuthenticated(this.user, this.profile);

  @override
  List<Object?> get props => [user, profile];
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

final class AuthPhoneVerificationRequired extends AuthState {
  final AuthUser user;
  final UserProfile profile;

  const AuthPhoneVerificationRequired(this.user, this.profile);

  @override
  List<Object?> get props => [user, profile];
}

final class AuthProfileSetupRequired extends AuthState {
  final AuthUser user;

  const AuthProfileSetupRequired(this.user);

  @override
  List<Object?> get props => [user];
}