import 'dart:io';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/profile/domain/entities/user_profile.dart';
import 'package:udharoo/features/profile/domain/entities/profile_update_request.dart';

abstract class ProfileRepository {
  Future<ApiResult<UserProfile>> getUserProfile(String uid);
  Future<ApiResult<UserProfile>> updateProfile(String uid, ProfileUpdateRequest request);
  Future<ApiResult<String>> uploadProfileImage(String uid, File imageFile);
  Future<ApiResult<void>> deleteProfileImage(String uid);
  Future<ApiResult<bool>> checkPhoneNumberExists(String phoneNumber);
  Future<ApiResult<String>> sendPhoneVerification(String phoneNumber);
  Future<ApiResult<void>> verifyPhoneNumber(String verificationId, String smsCode);
  Future<ApiResult<UserProfile>> createUserProfile(UserProfile profile);
}