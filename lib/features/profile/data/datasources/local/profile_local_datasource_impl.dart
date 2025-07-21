import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udharoo/features/profile/data/models/user_profile_model.dart';
import 'package:udharoo/features/profile/domain/datasources/local/profile_local_datasource.dart';

class ProfileLocalDatasourceImpl implements ProfileLocalDatasource {
  static const String _profileKey = 'cached_user_profile_';

  @override
  Future<UserProfileModel?> getCachedUserProfile(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_profileKey$uid');
      
      if (cachedData != null) {
        final json = jsonDecode(cachedData) as Map<String, dynamic>;
        return UserProfileModel.fromJson(json);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserProfile(UserProfileModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_profileKey}${profile.uid}',
        jsonEncode(profile.toJson()),
      );
    } catch (e) {
      // Silently ignore cache errors
    }
  }

  @override
  Future<void> clearUserProfileCache(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_profileKey$uid');
    } catch (e) {
      // Silently ignore cache errors
    }
  }
}