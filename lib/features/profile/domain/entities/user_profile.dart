// lib/features/profile/domain/entities/user_profile.dart
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isProfileComplete => 
      displayName?.isNotEmpty == true && 
      phoneNumber?.isNotEmpty == true && 
      phoneVerified;

  bool get canUseApp => phoneVerified;

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        phoneNumber,
        photoURL,
        emailVerified,
        phoneVerified,
        createdAt,
        updatedAt,
      ];
}