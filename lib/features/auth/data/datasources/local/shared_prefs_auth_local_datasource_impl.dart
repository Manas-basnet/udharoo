import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udharoo/features/auth/domain/datasources/local/auth_local_datasource.dart';

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  static const String _userDataKey = 'user_data';
  
  @override
  Future<void> saveUserData({
    required String uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    bool? emailVerified,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'emailVerified': emailVerified ?? false,
    };
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }
  
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }
  
  @override
  Future<bool> hasUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userDataKey);
  }
}