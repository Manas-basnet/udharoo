part of 'auth_cubit.dart';

enum AuthenticatedUserStatus {
  active,
  phoneVerificationRequired,
  phoneVerificationInProgress,
  profileSetupRequired,
}

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
  final UserProfile? profile;
  final AuthenticatedUserStatus status;

  const AuthAuthenticated(
    this.user, 
    this.profile, {
    this.status = AuthenticatedUserStatus.active,
  });

  bool get canUseApp => status == AuthenticatedUserStatus.active;
  bool get needsPhoneVerification => 
      status == AuthenticatedUserStatus.phoneVerificationRequired ||
      status == AuthenticatedUserStatus.phoneVerificationInProgress;
  bool get needsProfileSetup => status == AuthenticatedUserStatus.profileSetupRequired;

  AuthAuthenticated copyWith({
    AuthUser? user,
    UserProfile? profile,
    AuthenticatedUserStatus? status,
  }) {
    return AuthAuthenticated(
      user ?? this.user,
      profile ?? this.profile,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [user, profile, status];
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