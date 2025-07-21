import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udharoo/features/profile/domain/entities/user_profile.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    super.email,
    super.displayName,
    super.phoneNumber,
    super.photoURL,
    super.emailVerified,
    super.phoneVerified,
    super.createdAt,
    super.updatedAt,
  });

  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      uid: profile.uid,
      email: profile.email,
      displayName: profile.displayName,
      phoneNumber: profile.phoneNumber,
      photoURL: profile.photoURL,
      emailVerified: profile.emailVerified,
      phoneVerified: profile.phoneVerified,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  factory UserProfileModel.fromAuthUser(AuthUser authUser) {
    return UserProfileModel(
      uid: authUser.uid,
      email: authUser.email,
      displayName: authUser.displayName,
      phoneNumber: authUser.phoneNumber,
      photoURL: authUser.photoURL,
      emailVerified: authUser.emailVerified,
      phoneVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserProfileModel(
      uid: doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      photoURL: data['photoURL'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      phoneVerified: data['phoneVerified'] as bool? ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoURL: json['photoURL'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  UserProfileModel copyWith({
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
    return UserProfileModel(
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
}