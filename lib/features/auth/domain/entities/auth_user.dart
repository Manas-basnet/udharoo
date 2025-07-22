import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final bool emailVerified;
  final bool phoneVerified;
  final bool isPhoneRequired;
  final List<String> providers;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.isPhoneRequired = true,
    this.providers = const [],
  });

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    bool? emailVerified,
    bool? phoneVerified,
    bool? isPhoneRequired,
    List<String>? providers,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      isPhoneRequired: isPhoneRequired ?? this.isPhoneRequired,
      providers: providers ?? this.providers,
    );
  }

  bool get canAccessApp => phoneVerified || !isPhoneRequired;
  bool get hasGoogleProvider => providers.contains('google.com');
  bool get hasEmailProvider => providers.contains('password');
  bool get hasPhoneProvider => providers.contains('phone');

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        phoneNumber,
        photoURL,
        emailVerified,
        phoneVerified,
        isPhoneRequired,
        providers,
      ];
}