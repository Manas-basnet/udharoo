import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<ApiResult<AuthUser>> signInWithEmailAndPassword(String email, String password);
  Future<ApiResult<AuthUser>> createUserWithEmailAndPassword(String email, String password);
  Future<ApiResult<AuthUser>> createUserWithFullInfo({
    required String fullName,
    required String email,
    required String password,
  });
  Future<ApiResult<AuthUser>> createUserWithCompleteInfo({
    required String firstName,
    required String lastName,
    required String fullName,
    required String email,
    required String password,
    required DateTime birthDate,
  });
  Future<ApiResult<AuthUser>> completeProfile({
    required String fullName,
    required DateTime birthDate,
  });
  Future<ApiResult<AuthUser>> signInWithGoogle();
  Future<ApiResult<AuthUser>> linkGoogleAccount();
  Future<ApiResult<AuthUser>> linkPassword(String password);
  Future<ApiResult<AuthUser>> signInWithPhoneAndPassword(String phoneNumber, String password);
  Future<ApiResult<void>> signOut();
  Future<ApiResult<void>> sendPasswordResetEmail(String email);
  Future<ApiResult<void>> sendEmailVerification();
  Future<ApiResult<bool>> isAuthenticated();
  Future<ApiResult<AuthUser?>> getCurrentUser();
  Future<ApiResult<AuthUser?>> checkAndSyncEmailVerificationStatus();
  Stream<AuthUser?> get authStateChanges;
  
  Future<ApiResult<bool>> checkPhoneNumberAvailability(String phoneNumber);
  Future<ApiResult<String>> sendPhoneVerificationCode(String phoneNumber);
  Future<ApiResult<AuthUser>> verifyPhoneCode(String verificationId, String smsCode);
  Future<ApiResult<AuthUser>> linkPhoneNumber(String verificationId, String smsCode);
  Future<ApiResult<AuthUser>> updatePhoneNumber(String verificationId, String smsCode);
  Future<ApiResult<bool>> checkPhoneVerificationStatus();
  Future<ApiResult<bool>> checkDeviceVerification();
  Future<ApiResult<void>> saveUserToFirestore(AuthUser user);
  Future<ApiResult<AuthUser?>> getUserFromFirestore(String uid);
  
  Future<ApiResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<ApiResult<AuthUser>> updateDisplayName(String displayName);
}