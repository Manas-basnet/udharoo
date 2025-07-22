import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDatasource {
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(String email, String password);
  Future<User> signInWithGoogle();
  Future<User> linkGoogleAccount();
  Future<User> linkPassword(String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  User? getCurrentUser();
  Stream<User?> get authStateChanges;
  
  Future<String> sendPhoneVerificationCode(
    String phoneNumber, {
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  });
  Future<UserCredential> verifyPhoneCode(String verificationId, String smsCode);
  Future<User> signInWithPhoneCredential(PhoneAuthCredential credential);
  Future<User> linkPhoneCredential(PhoneAuthCredential credential);
  Future<User> linkPhoneNumber(String verificationId, String smsCode);
  Future<User> updatePhoneNumber(String verificationId, String smsCode);
  Future<List<UserModel>> getUsersWithPhoneNumber(String phoneNumber);
  
  Future<void> saveUserToFirestore(UserModel user);
  Future<UserModel?> getUserFromFirestore(String uid);
  Future<void> updateUserInFirestore(String uid, Map<String, dynamic> data);
}