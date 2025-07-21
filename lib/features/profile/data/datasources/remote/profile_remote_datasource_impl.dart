// lib/features/profile/data/datasources/remote/profile_remote_datasource_impl.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/features/profile/data/models/user_profile_model.dart';
import 'package:udharoo/features/profile/domain/datasources/remote/profile_remote_datasource.dart';

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  static const String _usersCollection = 'users';
  static const String _profileImagesPath = 'profile_images';

  ProfileRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<UserProfileModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      
      if (doc.exists) {
        return UserProfileModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile) async {
    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection(_usersCollection)
          .doc(profile.uid)
          .set(updatedProfile.toFirestore(), SetOptions(merge: true));
      
      return updatedProfile;
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  @override
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('$_profileImagesPath/$uid.jpg');
      
      await ref.putFile(imageFile);
      
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  @override
  Future<void> deleteProfileImage(String uid, String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }

  @override
  Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check phone number: $e');
    }
  }

  @override
  Future<void> sendPhoneVerification(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {},
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      throw Exception('Failed to send phone verification: $e');
    }
  }

  @override
  Future<void> verifyPhoneNumber(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);
      }
    } catch (e) {
      throw Exception('Failed to verify phone number: $e');
    }
  }

  @override
  Future<UserProfileModel> createUserProfile(UserProfileModel profile) async {
    try {
      final newProfile = profile.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestore
          .collection(_usersCollection)
          .doc(profile.uid)
          .set(newProfile.toFirestore());
      
      return newProfile;
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }
}