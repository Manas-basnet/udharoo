import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final bool emailVerified;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.emailVerified = false,
  });

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    bool? emailVerified,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        phoneNumber,
        photoURL,
        emailVerified,
      ];
}