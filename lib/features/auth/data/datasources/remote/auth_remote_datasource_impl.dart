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
    
    await _updateUserProviders(credential.user!);
    
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
    
    await _updateUserProviders(credential.user!);
    
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
    
    final existingUser = await _checkIfUserExistsInFirestore(googleUser.email);
    
    if (existingUser != null) {
      final hasGoogleProvider = await _checkIfUserHasGoogleProvider(googleUser.email);
      
      if (!hasGoogleProvider) {
        await _googleSignIn.signOut();
        throw FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message: 'An account already exists with this email. Please sign in with your existing method first, then link your Google account from the profile settings.',
        );
      }
      
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
    
    await _updateUserProviders(userCredential.user!);
    
    return userCredential.user!;
  }

  @override
  Future<User> linkGoogleAccount() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found',
      );
    }

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

    final userCredential = await currentUser.linkWithCredential(credential);
    
    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'google-link-failed',
        message: 'Failed to link Google account',
      );
    }

    await _updateUserProviders(userCredential.user!);

    return userCredential.user!;
  }

  @override
  Future<User> linkPassword(String password) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found',
      );
    }

    if (currentUser.email == null) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'User must have an email to link password authentication',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: currentUser.email!,
      password: password,
    );

    final userCredential = await currentUser.linkWithCredential(credential);
    
    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'password-link-failed',
        message: 'Failed to link password authentication',
      );
    }

    await _updateUserProviders(userCredential.user!);

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
    
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    
    if (userCredential.user != null) {
      await _updateUserProviders(userCredential.user!);
    }
    
    return userCredential;
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
    
    await _updateUserProviders(userCredential.user!);
    
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

    await _updateUserProviders(userCredential.user!);

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

    await _updateUserProviders(userCredential.user!);

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
    
    await _updateUserProviders(user);
    
    return user;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found',
      );
    }

    if (user.email == null) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'User must have an email to change password',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  @override
  Future<User> updateDisplayName(String displayName) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found',
      );
    }

    await user.updateDisplayName(displayName);
    await user.reload();
    
    final refreshedUser = _firebaseAuth.currentUser;
    if (refreshedUser == null) {
      throw FirebaseAuthException(
        code: 'user-update-failed',
        message: 'Failed to update display name',
      );
    }
    
    await updateUserInFirestore(refreshedUser.uid, {
      'displayName': displayName,
    });

    return refreshedUser;
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

  Future<UserModel?> _checkIfUserExistsInFirestore(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromJson(querySnapshot.docs.first.data());
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _checkIfUserHasGoogleProvider(String email) async {
    try {
      final existingUser = await _checkIfUserExistsInFirestore(email);
      return existingUser?.hasGoogleProvider ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateUserProviders(User user) async {
    try {
      final providers = user.providerData.map((info) => info.providerId).toList();
      await updateUserInFirestore(user.uid, {'providers': providers});
    } catch (e) {
    }
  }
}