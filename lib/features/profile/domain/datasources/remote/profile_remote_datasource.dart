import 'dart:io';
import 'package:udharoo/features/profile/data/models/user_profile_model.dart';

abstract class ProfileRemoteDatasource {
  Future<UserProfileModel?> getUserProfile(String uid);
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile);
  Future<String> uploadProfileImage(String uid, File imageFile);
  Future<void> deleteProfileImage(String uid, String imageUrl);
  Future<bool> checkPhoneNumberExists(String phoneNumber);
  Future<void> sendPhoneVerification(String phoneNumber);
  Future<void> verifyPhoneNumber(String verificationId, String smsCode);
  Future<UserProfileModel> createUserProfile(UserProfileModel profile);
}
