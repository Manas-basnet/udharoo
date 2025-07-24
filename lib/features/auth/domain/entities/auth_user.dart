import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? fullName;
  final DateTime? birthDate;
  final String? phoneNumber;
  final String? photoURL;
  final bool emailVerified;
  final bool phoneVerified;
  final bool isPhoneRequired;
  final bool isProfileComplete;
  final List<String> providers;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.fullName,
    this.birthDate,
    this.phoneNumber,
    this.photoURL,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.isPhoneRequired = true,
    this.isProfileComplete = false,
    this.providers = const [],
  });

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? fullName,
    DateTime? birthDate,
    String? phoneNumber,
    String? photoURL,
    bool? emailVerified,
    bool? phoneVerified,
    bool? isPhoneRequired,
    bool? isProfileComplete,
    List<String>? providers,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      isPhoneRequired: isPhoneRequired ?? this.isPhoneRequired,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      providers: providers ?? this.providers,
    );
  }

  bool get canAccessApp => (phoneVerified || !isPhoneRequired) && isProfileComplete;
  bool get hasGoogleProvider => providers.contains('google.com');
  bool get hasEmailProvider => providers.contains('password');
  bool get hasPhoneProvider => providers.contains('phone');

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        fullName,
        birthDate,
        phoneNumber,
        photoURL,
        emailVerified,
        phoneVerified,
        isPhoneRequired,
        isProfileComplete,
        providers,
      ];
}