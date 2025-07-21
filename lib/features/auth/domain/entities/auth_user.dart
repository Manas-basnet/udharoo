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

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.isPhoneRequired = true,
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
    );
  }

  bool get canAccessApp => phoneVerified || !isPhoneRequired;

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
      ];
}