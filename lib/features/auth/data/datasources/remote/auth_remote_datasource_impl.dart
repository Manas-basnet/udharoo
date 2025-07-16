import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:udharoo/features/auth/domain/datasources/remote/auth_remote_datasource.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  
  AuthRemoteDatasourceImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();
  
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
  Future<User> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'sign-in-aborted',
          message: 'Google Sign In was cancelled',
        );
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: 'Failed to sign in with Google',
        );
      }
      
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during Google Sign In: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
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
      case 'sign-in-aborted':
        return FirebaseAuthException(
          code: e.code,
          message: 'Google Sign In was cancelled.',
        );
      case 'account-exists-with-different-credential':
        return FirebaseAuthException(
          code: e.code,
          message: 'An account already exists with a different sign-in method.',
        );
      default:
        return FirebaseAuthException(
          code: e.code,
          message: e.message ?? 'An authentication error occurred.',
        );
    }
  }
}