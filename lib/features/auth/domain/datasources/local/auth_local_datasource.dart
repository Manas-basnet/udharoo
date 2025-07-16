abstract class AuthLocalDatasource {
  Future<void> saveUserData({
    required String uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    bool? emailVerified,
  });
  
  Future<Map<String, dynamic>?> getUserData();
  Future<void> clearUserData();
  Future<bool> hasUserData();
}