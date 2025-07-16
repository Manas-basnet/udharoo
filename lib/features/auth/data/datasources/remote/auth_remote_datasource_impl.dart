import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/features/auth/domain/datasources/remote/auth_remote_datasource.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth _firebaseAuth;
  
  AuthRemoteDatasourceImpl({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;
  
  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that email.',
        );
      }
      
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<User> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Failed to create user account.',
        );
      }
      
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during sign out: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
  
  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
  
  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  FirebaseAuthException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return FirebaseAuthException(
          code: e.code,
          message: 'No user found for that email.',
        );
      case 'wrong-password':
        return FirebaseAuthException(
          code: e.code,
          message: 'Wrong password provided for that user.',
        );
      case 'email-already-in-use':
        return FirebaseAuthException(
          code: e.code,
          message: 'The account already exists for that email.',
        );
      case 'weak-password':
        return FirebaseAuthException(
          code: e.code,
          message: 'The password provided is too weak.',
        );
      case 'invalid-email':
        return FirebaseAuthException(
          code: e.code,
          message: 'The email address is not valid.',
        );
      case 'operation-not-allowed':
        return FirebaseAuthException(
          code: e.code,
          message: 'Email/password accounts are not enabled.',
        );
      case 'too-many-requests':
        return FirebaseAuthException(
          code: e.code,
          message: 'Too many requests. Try again later.',
        );
      case 'network-request-failed':
        return FirebaseAuthException(
          code: e.code,
          message: 'Network error. Please check your connection.',
        );
      default:
        return FirebaseAuthException(
          code: e.code,
          message: e.message ?? 'An authentication error occurred.',
        );
    }
  }
}