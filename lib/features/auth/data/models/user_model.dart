import 'package:equatable/equatable.dart';
import 'package:udharoo/features/auth/domain/entities/user_device.dart';

class UserModel extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? fullName;
  final DateTime? birthDate;
  final String? phoneNumber;
  final String? photoURL;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<UserDevice> verifiedDevices;
  final Map<String, dynamic>? additionalData;
  final List<String> providers;
  final bool isProfileComplete;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.fullName,
    this.birthDate,
    this.phoneNumber,
    this.photoURL,
    this.emailVerified = false,
    this.phoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.verifiedDevices = const [],
    this.additionalData,
    this.providers = const [],
    this.isProfileComplete = false,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? fullName,
    DateTime? birthDate,
    String? phoneNumber,
    String? photoURL,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<UserDevice>? verifiedDevices,
    Map<String, dynamic>? additionalData,
    List<String>? providers,
    bool? isProfileComplete,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verifiedDevices: verifiedDevices ?? this.verifiedDevices,
      additionalData: additionalData ?? this.additionalData,
      providers: providers ?? this.providers,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  bool isDeviceVerified(String deviceId) {
    return verifiedDevices.any((device) => 
        device.deviceId == deviceId && device.isActive);
  }

  bool get hasGoogleProvider => providers.contains('google.com');

  UserModel addVerifiedDevice(UserDevice device) {
    final updatedDevices = [...verifiedDevices];
    
    final existingIndex = updatedDevices.indexWhere(
      (d) => d.deviceId == device.deviceId,
    );
    
    if (existingIndex != -1) {
      updatedDevices[existingIndex] = device;
    } else {
      updatedDevices.add(device);
    }
    
    return copyWith(
      verifiedDevices: updatedDevices,
      updatedAt: DateTime.now(),
    );
  }

  UserModel removeDevice(String deviceId) {
    final updatedDevices = verifiedDevices
        .where((device) => device.deviceId != deviceId)
        .toList();
    
    return copyWith(
      verifiedDevices: updatedDevices,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'fullName': fullName,
      'birthDate': birthDate?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'verifiedDevices': verifiedDevices.map((device) => device.toJson()).toList(),
      'additionalData': additionalData,
      'providers': providers,
      'isProfileComplete': isProfileComplete,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      fullName: json['fullName'] as String?,
      birthDate: json['birthDate'] != null 
          ? DateTime.parse(json['birthDate'] as String) 
          : null,
      phoneNumber: json['phoneNumber'] as String?,
      photoURL: json['photoURL'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      verifiedDevices: (json['verifiedDevices'] as List<dynamic>?)
              ?.map((device) => UserDevice.fromJson(device as Map<String, dynamic>))
              .toList() ??
          [],
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      providers: (json['providers'] as List<dynamic>?)?.cast<String>() ?? [],
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
    );
  }

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
        createdAt,
        updatedAt,
        verifiedDevices,
        additionalData,
        providers,
        isProfileComplete,
      ];
}