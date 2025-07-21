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

class PhoneVerificationRequiredEvent extends AuthEvent {
  final String uid;
  PhoneVerificationRequiredEvent(this.uid);
}

class PhoneVerificationCompletedEvent extends AuthEvent {
  final String uid;
  final String phoneNumber;
  PhoneVerificationCompletedEvent(this.uid, this.phoneNumber);
}

class DeviceVerificationRequiredEvent extends AuthEvent {
  final String uid;
  final String deviceId;
  DeviceVerificationRequiredEvent(this.uid, this.deviceId);
}