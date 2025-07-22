import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:udharoo/features/auth/data/models/user_model.dart';
import 'package:udharoo/features/auth/domain/datasources/remote/auth_remote_datasource.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  
  AuthRemoteDatasourceImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestore = firestore ?? FirebaseFirestore.instance;
  
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

  @override
  Future<String> sendPhoneVerificationCode(
    String phoneNumber, {
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    String? verificationId;
    
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: (String verId, int? resendToken) {
        verificationId = verId;
        codeSent(verId, resendToken);
      },
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
    
    return verificationId ?? '';
  }

  @override
  Future<UserCredential> verifyPhoneCode(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    
    return await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<User> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    
    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'phone-sign-in-failed',
        message: 'Failed to sign in with phone number',
      );
    }
    
    return userCredential.user!;
  }

  @override
  Future<User> linkPhoneCredential(PhoneAuthCredential credential) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found',
      );
    }

    final userCredential = await user.linkWithCredential(credential);
    
    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'phone-link-failed',
        message: 'Failed to link phone number',
      );
    }

    return userCredential.user!;
  }

  @override
  Future<User> linkPhoneNumber(String verificationId, String smsCode) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found',
      );
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await user.linkWithCredential(credential);
    
    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'phone-link-failed',
        message: 'Failed to link phone number',
      );
    }

    return userCredential.user!;
  }

  @override
  Future<User> updatePhoneNumber(String verificationId, String smsCode) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found',
      );
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    await user.updatePhoneNumber(credential);
    
    return user;
  }

  @override
  Future<List<UserModel>> getUsersWithPhoneNumber(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveUserToFirestore(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateUserInFirestore(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({
          ...data,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }
}