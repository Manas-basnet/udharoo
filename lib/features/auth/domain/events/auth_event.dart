abstract class AuthEvent {}

class TokenRefreshedEvent extends AuthEvent {
  final String newToken;
  TokenRefreshedEvent(this.newToken);
}

class ForceLogoutEvent extends AuthEvent {}

class AuthenticationFailedEvent extends AuthEvent {
  final String reason;
  AuthenticationFailedEvent(this.reason);
}