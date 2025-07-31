part of 'auth_session_cubit.dart';

sealed class AuthSessionState extends Equatable {
  const AuthSessionState();

  @override
  List<Object?> get props => [];
}

final class AuthSessionLoading extends AuthSessionState {
  const AuthSessionLoading();
}

final class AuthSessionAuthenticated extends AuthSessionState {
  final AuthUser user;

  const AuthSessionAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

final class AuthSessionUnauthenticated extends AuthSessionState {
  const AuthSessionUnauthenticated();
}

final class AuthSessionError extends AuthSessionState {
  final String message;
  final FailureType type;

  const AuthSessionError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}