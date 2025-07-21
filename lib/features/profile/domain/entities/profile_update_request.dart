import 'dart:io';

class ProfileUpdateRequest {
  final String? displayName;
  final String? phoneNumber;
  final File? profileImage;

  const ProfileUpdateRequest({
    this.displayName,
    this.phoneNumber,
    this.profileImage,
  });

  bool get hasUpdates => 
      displayName != null || 
      phoneNumber != null || 
      profileImage != null;
}