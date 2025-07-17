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
  }
  
  @override
  Future<User> createUserWithEmailAndPassword(String email, String password) async {
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
  }

  @override
  Future<User> signInWithGoogle() async {
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
  }
  
  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
  
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
  
  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
  
  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
  
  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}