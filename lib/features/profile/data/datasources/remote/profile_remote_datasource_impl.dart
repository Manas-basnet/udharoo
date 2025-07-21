import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/features/profile/data/models/user_profile_model.dart';
import 'package:udharoo/features/profile/domain/datasources/remote/profile_remote_datasource.dart';
import 'dart:async';

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
    final doc = await _firestore.collection(_usersCollection).doc(uid).get();
    
    if (doc.exists) {
      return UserProfileModel.fromFirestore(doc);
    }
    
    return null;
  }

  @override
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile) async {
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    
    await _firestore
        .collection(_usersCollection)
        .doc(profile.uid)
        .set(updatedProfile.toFirestore(), SetOptions(merge: true));
    
    return updatedProfile;
  }

  @override
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final ref = _storage.ref().child('$_profileImagesPath/$uid.jpg');
    
    await ref.putFile(imageFile);
    
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }

  @override
  Future<void> deleteProfileImage(String uid, String imageUrl) async {
    final ref = _storage.refFromURL(imageUrl);
    await ref.delete();
  }

  @override
  Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    final query = await _firestore
        .collection(_usersCollection)
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    
    return query.docs.isNotEmpty;
  }

  @override
  Future<String> sendPhoneVerification(String phoneNumber) async {
    final completer = Completer<String>();
    String formattedPhoneNumber = _formatPhoneNumber(phoneNumber);
    
    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            await currentUser.linkWithCredential(credential);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );
    
    return await completer.future;
  }

  @override
  Future<void> verifyPhoneNumber(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found',
      );
    }
    
    await currentUser.linkWithCredential(credential);
  }

  @override
  Future<UserProfileModel> createUserProfile(UserProfileModel profile) async {
    final newProfile = profile.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _firestore
        .collection(_usersCollection)
        .doc(profile.uid)
        .set(newProfile.toFirestore());
    
    return newProfile;
  }

  String _formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleanNumber.startsWith('+')) {
      return cleanNumber;
    }
    
    if (cleanNumber.length > 10 && !cleanNumber.startsWith('0')) {
      return '+$cleanNumber';
    }
    
    if (cleanNumber.startsWith('0')) {
      cleanNumber = cleanNumber.substring(1);
    }
    
    if (cleanNumber.length == 10) {
      return '+977$cleanNumber';
    }
    
    if (cleanNumber.length > 10) {
      return '+$cleanNumber';
    }
    
    return '+977$cleanNumber';
  }
}