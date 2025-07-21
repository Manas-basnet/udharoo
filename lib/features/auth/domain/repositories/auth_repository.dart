import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<ApiResult<AuthUser>> signInWithEmailAndPassword(String email, String password);
  Future<ApiResult<AuthUser>> signInWithPhoneAndPassword(String phoneNumber, String password);
  Future<ApiResult<AuthUser>> createUserWithEmailAndPassword(String email, String password);
  Future<ApiResult<AuthUser>> signInWithGoogle();
  Future<ApiResult<void>> signOut();
  Future<ApiResult<void>> sendPasswordResetEmail(String email);
  Future<ApiResult<void>> sendEmailVerification();
  Future<ApiResult<bool>> isAuthenticated();
  Future<ApiResult<AuthUser?>> getCurrentUser();
  Stream<AuthUser?> get authStateChanges;
}