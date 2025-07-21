import 'package:udharoo/features/profile/data/models/user_profile_model.dart';

abstract class ProfileLocalDatasource {
  Future<UserProfileModel?> getCachedUserProfile(String uid);
  Future<void> cacheUserProfile(UserProfileModel profile);
  Future<void> clearUserProfileCache(String uid);
}