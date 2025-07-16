import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDatasource {
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(String email, String password);
  Future<User> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  User? getCurrentUser();
  Stream<User?> get authStateChanges;
}