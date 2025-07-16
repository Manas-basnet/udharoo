import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/core/utils/exception_handler.dart';
import 'package:udharoo/features/auth/domain/datasources/local/auth_local_datasource.dart';
import 'package:udharoo/features/auth/domain/datasources/remote/auth_remote_datasource.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource _localDatasource;
  final AuthRemoteDatasource _remoteDatasource;

  AuthRepositoryImpl({
    required AuthLocalDatasource localDatasource,
    required AuthRemoteDatasource remoteDatasource,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource;

  @override
  Future<ApiResult<AuthUser>> signInWithEmailAndPassword(
      String email, String password) async {
    return ExceptionHandler.handleExceptions(() async {
      final user = await _remoteDatasource.signInWithEmailAndPassword(email, password);
      final authUser = _mapFirebaseUserToAuthUser(user);
      
      await _localDatasource.saveUserData(
        uid: authUser.uid,
        email: authUser.email,
        displayName: authUser.displayName,
        phoneNumber: authUser.phoneNumber,
        photoURL: authUser.photoURL,
        emailVerified: authUser.emailVerified,
      );
      
      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<AuthUser>> createUserWithEmailAndPassword(
      String email, String password) async {
    return ExceptionHandler.handleExceptions(() async {
      final user = await _remoteDatasource.createUserWithEmailAndPassword(email, password);
      final authUser = _mapFirebaseUserToAuthUser(user);
      
      await _localDatasource.saveUserData(
        uid: authUser.uid,
        email: authUser.email,
        displayName: authUser.displayName,
        phoneNumber: authUser.phoneNumber,
        photoURL: authUser.photoURL,
        emailVerified: authUser.emailVerified,
      );
      
      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<AuthUser>> signInWithGoogle() async {
    return ExceptionHandler.handleExceptions(() async {
      final user = await _remoteDatasource.signInWithGoogle();
      final authUser = _mapFirebaseUserToAuthUser(user);
      
      await _localDatasource.saveUserData(
        uid: authUser.uid,
        email: authUser.email,
        displayName: authUser.displayName,
        phoneNumber: authUser.phoneNumber,
        photoURL: authUser.photoURL,
        emailVerified: authUser.emailVerified,
      );
      
      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<void>> signOut() async {
    return ExceptionHandler.handleExceptions(() async {
      await _remoteDatasource.signOut();
      await _localDatasource.clearUserData();
      return ApiResult.success(null);
    });
  }

  @override
  Future<ApiResult<void>> sendPasswordResetEmail(String email) async {
    return ExceptionHandler.handleExceptions(() async {
      await _remoteDatasource.sendPasswordResetEmail(email);
      return ApiResult.success(null);
    });
  }

  @override
  Future<ApiResult<void>> sendEmailVerification() async {
    return ExceptionHandler.handleExceptions(() async {
      await _remoteDatasource.sendEmailVerification();
      return ApiResult.success(null);
    });
  }

  @override
  Future<ApiResult<bool>> isAuthenticated() async {
    return ExceptionHandler.handleExceptions(() async {
      final user = _remoteDatasource.getCurrentUser();
      return ApiResult.success(user != null);
    });
  }

  @override
  Future<ApiResult<AuthUser?>> getCurrentUser() async {
    return ExceptionHandler.handleExceptions(() async {
      final user = _remoteDatasource.getCurrentUser();
      if (user != null) {
        final authUser = _mapFirebaseUserToAuthUser(user);
        
        await _localDatasource.saveUserData(
          uid: authUser.uid,
          email: authUser.email,
          displayName: authUser.displayName,
          phoneNumber: authUser.phoneNumber,
          photoURL: authUser.photoURL,
          emailVerified: authUser.emailVerified,
        );
        
        return ApiResult.success(authUser);
      }
      return ApiResult.success(null);
    });
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _remoteDatasource.authStateChanges.map((user) {
      if (user != null) {
        final authUser = _mapFirebaseUserToAuthUser(user);
        _localDatasource.saveUserData(
          uid: authUser.uid,
          email: authUser.email,
          displayName: authUser.displayName,
          phoneNumber: authUser.phoneNumber,
          photoURL: authUser.photoURL,
          emailVerified: authUser.emailVerified,
        );
        return authUser;
      } else {
        _localDatasource.clearUserData();
        return null;
      }
    });
  }

  AuthUser _mapFirebaseUserToAuthUser(User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }
}