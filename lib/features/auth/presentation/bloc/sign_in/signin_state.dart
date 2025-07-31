part of 'signin_cubit.dart';

sealed class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => [];
}

final class SignInInitial extends SignInState {
  const SignInInitial();
}

final class SignInLoading extends SignInState {
  const SignInLoading();
}

final class SignInSuccess extends SignInState {
  final AuthUser user;

  const SignInSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

final class SignUpSuccess extends SignInState {
  final AuthUser user;

  const SignUpSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

final class ProfileCompleted extends SignInState {
  final AuthUser user;

  const ProfileCompleted(this.user);

  @override
  List<Object?> get props => [user];
}

final class SignInError extends SignInState {
  final String message;
  final FailureType type;

  const SignInError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}

final class PasswordResetSent extends SignInState {
  const PasswordResetSent();
}

final class GoogleAccountLinked extends SignInState {
  final AuthUser user;

  const GoogleAccountLinked(this.user);

  @override
  List<Object?> get props => [user];
}

final class PasswordLinked extends SignInState {
  final AuthUser user;

  const PasswordLinked(this.user);

  @override
  List<Object?> get props => [user];
}