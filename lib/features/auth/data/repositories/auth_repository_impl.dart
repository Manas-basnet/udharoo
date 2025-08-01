import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/core/utils/exception_handler.dart';
import 'package:udharoo/features/auth/data/models/user_model.dart';
import 'package:udharoo/features/auth/domain/datasources/local/auth_local_datasource.dart';
import 'package:udharoo/features/auth/domain/datasources/remote/auth_remote_datasource.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';
import 'package:udharoo/features/auth/domain/services/device_info_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource _localDatasource;
  final AuthRemoteDatasource _remoteDatasource;
  final DeviceInfoService _deviceInfoService;

  Completer<String>? _verificationCompleter;

  AuthRepositoryImpl({
    required AuthLocalDatasource localDatasource,
    required AuthRemoteDatasource remoteDatasource,
    required DeviceInfoService deviceInfoService,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource,
        _deviceInfoService = deviceInfoService;

  @override
  Future<ApiResult<AuthUser>> signInWithEmailAndPassword(
      String email, String password) async {
    return ExceptionHandler.handleExceptions(() async {
      final user = await _remoteDatasource.signInWithEmailAndPassword(email, password);
      final authUser = await _processAuthenticatedUser(user);
      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<AuthUser>> createUserWithEmailAndPassword(
      String email, String password) async {
    return ExceptionHandler.handleExceptions(() async {
      final user = await _remoteDatasource.createUserWithEmailAndPassword(email, password);
      final authUser = await _processNewUser(user);
      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<AuthUser>> createUserWithCompleteInfo({
    required String firstName,
    required String lastName,
    required String fullName,
    required String email,
    required String password,
    required DateTime birthDate,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      final user = await _remoteDatasource.createUserWithEmailAndPassword(email, password);
      
      await user.updateDisplayName(fullName);
      await user.reload();
      final refreshedUser = _remoteDatasource.getCurrentUser();
      
      if (refreshedUser == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Failed to create user account.',
        );
      }
      
      final authUser = _mapFirebaseUserToAuthUser(refreshedUser).copyWith(
        displayName: fullName,
        fullName: fullName,
        birthDate: birthDate,
        isProfileComplete: true,
      );
      
      await _saveUserDataLocally(authUser);
      
      final userModel = UserModel(
        uid: authUser.uid,
        email: authUser.email,
        displayName: fullName,
        fullName: fullName,
        birthDate: birthDate,
        photoURL: authUser.photoURL,
        emailVerified: authUser.emailVerified,
        phoneVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        providers: authUser.providers,
        isProfileComplete: true,
      );

      await _remoteDatasource.saveUserToFirestore(userModel);
      
      return ApiResult.success(authUser.copyWith(
        displayName: fullName,
        fullName: fullName,
        birthDate: birthDate,
        phoneVerified: false,
        isPhoneRequired: true,
        isProfileComplete: true,
      ));
    });
  }

  @override
  Future<ApiResult<AuthUser>> completeProfile({
    required String fullName,
    required DateTime birthDate,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      final currentUser = _remoteDatasource.getCurrentUser();
      if (currentUser == null) {
        return ApiResult.failure(
          'No authenticated user found',
          FailureType.auth,
        );
      }

      await currentUser.updateDisplayName(fullName);
      await currentUser.reload();
      
      final refreshedUser = _remoteDatasource.getCurrentUser();
      if (refreshedUser == null) {
        throw FirebaseAuthException(
          code: 'user-update-failed',
          message: 'Failed to update user profile',
        );
      }

      await _remoteDatasource.updateUserInFirestore(refreshedUser.uid, {
        'displayName': fullName,
        'fullName': fullName,
        'birthDate': birthDate.toIso8601String(),
        'isProfileComplete': true,
      });

      final authUser = await _processAuthenticatedUser(refreshedUser);
      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<AuthUser>> signInWithGoogle() async {
    return ExceptionHandler.handleExceptions(() async {
      try {
        final user = await _remoteDatasource.signInWithGoogle();
        final authUser = await _processAuthenticatedUser(user);
        return ApiResult.success(authUser);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          return ApiResult.failure(
            e.message ?? 'Account already exists with different sign-in method. Please sign in with your existing method first.',
            FailureType.auth,
          );
        }
        rethrow;
      }
    });
  }

  @override
  Future<ApiResult<AuthUser>> linkGoogleAccount() async {
    return ExceptionHandler.handleExceptions(() async {
      final user = await _remoteDatasource.linkGoogleAccount();
      final authUser = await _processAuthenticatedUser(user);
      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<AuthUser>> linkPassword(String password) async {
    return ExceptionHandler.handleExceptions(() async {
      final user = await _remoteDatasource.linkPassword(password);
      final authUser = await _processAuthenticatedUser(user);
      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<AuthUser>> signInWithPhoneAndPassword(
      String phoneNumber, String password) async {
    return ExceptionHandler.handleExceptions(() async {
      final usersWithPhone = await _remoteDatasource.getUsersWithPhoneNumber(phoneNumber);
      
      if (usersWithPhone.isEmpty) {
        return ApiResult.failure(
          'No account found with this phone number',
          FailureType.notFound,
        );
      }

      final userModel = usersWithPhone.firstWhere((user) => (user.email != null && user.email?.isNotEmpty == true));
      if (!userModel.phoneVerified) {
        return ApiResult.failure(
          'Phone number not verified',
          FailureType.auth,
        );
      }

      final user = await _remoteDatasource.signInWithEmailAndPassword(
        userModel.email!, 
        password,
      );
      
      final authUser = await _processAuthenticatedUser(user);
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
  Future<ApiResult<AuthUser?>> checkAndSyncEmailVerificationStatus() async {
    return ExceptionHandler.handleExceptions(() async {
      final user = _remoteDatasource.getCurrentUser();
      if (user == null) {
        return ApiResult.success(null);
      }

      await user.reload();
      final refreshedUser = _remoteDatasource.getCurrentUser();
      
      if (refreshedUser == null) {
        return ApiResult.success(null);
      }

      final currentUserModel = await _remoteDatasource.getUserFromFirestore(refreshedUser.uid);
      
      if (currentUserModel != null && 
          currentUserModel.emailVerified != refreshedUser.emailVerified) {
        
        await _remoteDatasource.updateUserInFirestore(
          refreshedUser.uid,
          {'emailVerified': refreshedUser.emailVerified},
        );
      }

      final authUser = await _processAuthenticatedUser(refreshedUser);
      return ApiResult.success(authUser);
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
        final authUser = await _processAuthenticatedUser(user);
        return ApiResult.success(authUser);
      }
      return ApiResult.success(null);
    });
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _remoteDatasource.authStateChanges.asyncMap((user) async {
      if (user != null) {
        final authUser = await _processAuthenticatedUser(user);
        return authUser;
      } else {
        await _localDatasource.clearUserData();
        return null;
      }
    });
  }

  @override
  Future<ApiResult<bool>> checkPhoneNumberAvailability(String phoneNumber) async {
    return ExceptionHandler.handleExceptions(() async {
      final currentUser = _remoteDatasource.getCurrentUser();
      
      final existingUsers = await _remoteDatasource.getUsersWithPhoneNumber(phoneNumber);
      
      if (currentUser != null) {
        final hasOtherUserWithPhone = existingUsers.any((user) => user.uid != currentUser.uid);
        return ApiResult.success(!hasOtherUserWithPhone);
      } else {
        return ApiResult.success(existingUsers.isEmpty);
      }
    });
  }

  @override
  Future<ApiResult<String>> sendPhoneVerificationCode(String phoneNumber) async {
    return ExceptionHandler.handleExceptions(() async {
      final currentUser = _remoteDatasource.getCurrentUser();
      
      if (currentUser != null) {
        final currentUserModel = await _remoteDatasource.getUserFromFirestore(currentUser.uid);
        
        if (currentUser.phoneNumber == phoneNumber) {
          if (currentUserModel?.phoneVerified == true) {
            final currentDevice = await _deviceInfoService.getCurrentDevice();
            final isDeviceVerified = currentUserModel?.isDeviceVerified(currentDevice.deviceId) ?? false;
            
            if (!isDeviceVerified) {
            } else {
              return ApiResult.failure(
                'Phone number is already verified on this device',
                FailureType.validation,
              );
            }
          }
        } else {
          final existingUsers = await _remoteDatasource.getUsersWithPhoneNumber(phoneNumber);
          final hasOtherUserWithPhone = existingUsers.any((user) => user.uid != currentUser.uid);
          
          if (hasOtherUserWithPhone) {
            return ApiResult.failure(
              'This phone number is already associated with another account',
              FailureType.validation,
            );
          }
        }
      } else {
        final existingUsers = await _remoteDatasource.getUsersWithPhoneNumber(phoneNumber);
        if (existingUsers.isNotEmpty) {
          return ApiResult.failure(
            'This phone number is already associated with another account',
            FailureType.validation,
          );
        }
      }

      _verificationCompleter = Completer<String>();

      await _remoteDatasource.sendPhoneVerificationCode(
        phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            if (currentUser != null) {
              if (currentUser.phoneNumber == phoneNumber) {
                await _handleExistingPhoneVerification(currentUser, phoneNumber);
              } else {
                final user = await _remoteDatasource.linkPhoneCredential(credential);
                await _processAuthenticatedUser(user);
              }
            } else {
              final user = await _remoteDatasource.signInWithPhoneCredential(credential);
              await _processAuthenticatedUser(user);
            }
            _verificationCompleter?.complete('auto-verified');
          } catch (e) {
            _verificationCompleter?.completeError(e);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _verificationCompleter?.completeError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationCompleter?.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
        },
      );

      final result = await _verificationCompleter!.future;
      return ApiResult.success(result);
    });
  }

  @override
  Future<ApiResult<AuthUser>> verifyPhoneCode(String verificationId, String smsCode) async {
    return ExceptionHandler.handleExceptions(() async {
      final currentUser = _remoteDatasource.getCurrentUser();
      
      if (currentUser == null) {
        final userCredential = await _remoteDatasource.verifyPhoneCode(verificationId, smsCode);
        if (userCredential.user == null) {
          return ApiResult.failure(
            'Phone verification failed',
            FailureType.auth,
          );
        }
        
        await _handleNewUserPhoneVerification(userCredential.user!, userCredential.user!.phoneNumber!);
        
        final authUser = await _processAuthenticatedUser(userCredential.user!);
        return ApiResult.success(authUser.copyWith(phoneVerified: true));
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      try {
        User resultUser;
        
        if (currentUser.phoneNumber == null) {
          resultUser = await _remoteDatasource.linkPhoneCredential(credential);
          await _updateUserPhoneVerification(resultUser.uid, resultUser.phoneNumber!, true);
        } else {
          final testCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          if (testCredential.user?.phoneNumber == currentUser.phoneNumber) {
            resultUser = currentUser;
            await _handleExistingPhoneVerification(currentUser, currentUser.phoneNumber!);
          } else {
            return ApiResult.failure(
              'Phone number verification failed',
              FailureType.auth,
            );
          }
        }

        final authUser = await _processAuthenticatedUser(resultUser);
        return ApiResult.success(authUser.copyWith(phoneVerified: true));
        
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked' || e.code == 'credential-already-in-use') {
          if (currentUser.phoneNumber != null) {
            await _handleExistingPhoneVerification(currentUser, currentUser.phoneNumber!);
            final authUser = await _processAuthenticatedUser(currentUser);
            return ApiResult.success(authUser.copyWith(phoneVerified: true));
          }
        }
        rethrow;
      }
    });
  }

  @override
  Future<ApiResult<AuthUser>> linkPhoneNumber(String verificationId, String smsCode) async {
    return ExceptionHandler.handleExceptions(() async {
      final user = await _remoteDatasource.linkPhoneNumber(verificationId, smsCode);
      await _updateUserPhoneVerification(user.uid, user.phoneNumber!, true);
      final authUser = await _processAuthenticatedUser(user);
      return ApiResult.success(authUser.copyWith(phoneVerified: true));
    });
  }

  @override
  Future<ApiResult<AuthUser>> updatePhoneNumber(String verificationId, String smsCode) async {
    return ExceptionHandler.handleExceptions(() async {
      final currentUser = _remoteDatasource.getCurrentUser();
      if (currentUser == null) {
        return ApiResult.failure(
          'No authenticated user found',
          FailureType.auth,
        );
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      try {
        await currentUser.updatePhoneNumber(credential);
        
        await currentUser.reload();
        final updatedUser = _remoteDatasource.getCurrentUser();
        if (updatedUser == null || updatedUser.phoneNumber == null) {
          return ApiResult.failure(
            'Failed to update phone number',
            FailureType.unknown,
          );
        }

        await _updateUserPhoneVerification(updatedUser.uid, updatedUser.phoneNumber!, true);
        
        final authUser = await _processAuthenticatedUser(updatedUser);
        return ApiResult.success(authUser.copyWith(phoneVerified: true));
        
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'invalid-verification-code':
            return ApiResult.failure(
              'Invalid verification code. Please try again.',
              FailureType.validation,
            );
          case 'invalid-verification-id':
            return ApiResult.failure(
              'Invalid verification session. Please request a new code.',
              FailureType.validation,
            );
          case 'session-expired':
            return ApiResult.failure(
              'Verification session expired. Please request a new code.',
              FailureType.validation,
            );
          case 'quota-exceeded':
            return ApiResult.failure(
              'Too many verification attempts. Please try again later.',
              FailureType.server,
            );
          default:
            return ApiResult.failure(
              e.message ?? 'Failed to update phone number',
              FailureType.unknown,
            );
        }
      } catch (e) {
        return ApiResult.failure(
          'Unexpected error occurred while updating phone number',
          FailureType.unknown,
        );
      }
    });
  }

  @override
  Future<ApiResult<bool>> checkPhoneVerificationStatus() async {
    return ExceptionHandler.handleExceptions(() async {
      final user = _remoteDatasource.getCurrentUser();
      if (user?.phoneNumber != null) {
        final userModel = await _remoteDatasource.getUserFromFirestore(user!.uid);
        final currentDevice = await _deviceInfoService.getCurrentDevice();
        final isDeviceVerified = userModel?.isDeviceVerified(currentDevice.deviceId) ?? false;
        return ApiResult.success(userModel?.phoneVerified == true && isDeviceVerified);
      }
      return ApiResult.success(false);
    });
  }

  @override
  Future<ApiResult<bool>> checkDeviceVerification() async {
    return ExceptionHandler.handleExceptions(() async {
      final user = _remoteDatasource.getCurrentUser();
      if (user == null) {
        return ApiResult.success(false);
      }

      final userModel = await _remoteDatasource.getUserFromFirestore(user.uid);
      if (userModel == null) {
        return ApiResult.success(false);
      }

      final currentDevice = await _deviceInfoService.getCurrentDevice();
      final isDeviceVerified = userModel.isDeviceVerified(currentDevice.deviceId);
      
      return ApiResult.success(isDeviceVerified);
    });
  }

  @override
  Future<ApiResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      await _remoteDatasource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return ApiResult.success(null);
    });
  }

  @override
  Future<ApiResult<AuthUser>> updateDisplayName(String displayName) async {
    return ExceptionHandler.handleExceptions(() async {
      final user = await _remoteDatasource.updateDisplayName(displayName);
      final authUser = await _processAuthenticatedUser(user);
      await _saveUserDataLocally(authUser);
      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<void>> saveUserToFirestore(AuthUser user) async {
    return ExceptionHandler.handleExceptions(() async {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        fullName: user.fullName,
        birthDate: user.birthDate,
        phoneNumber: user.phoneNumber,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        phoneVerified: user.phoneVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        providers: user.providers,
        isProfileComplete: user.isProfileComplete,
      );

      await _remoteDatasource.saveUserToFirestore(userModel);
      return ApiResult.success(null);
    });
  }

  @override
  Future<ApiResult<AuthUser?>> getUserFromFirestore(String uid) async {
    return ExceptionHandler.handleExceptions(() async {
      final userModel = await _remoteDatasource.getUserFromFirestore(uid);
      if (userModel == null) {
        return ApiResult.success(null);
      }

      final authUser = AuthUser(
        uid: userModel.uid,
        email: userModel.email,
        displayName: userModel.displayName,
        fullName: userModel.fullName,
        birthDate: userModel.birthDate,
        phoneNumber: userModel.phoneNumber,
        photoURL: userModel.photoURL,
        emailVerified: userModel.emailVerified,
        phoneVerified: userModel.phoneVerified,
        providers: userModel.providers,
        isProfileComplete: userModel.isProfileComplete,
      );

      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<AuthUser?>> getUserByPhoneNumber(String phoneNumber) async {
    return ExceptionHandler.handleExceptions(() async {
      final usersWithPhone = await _remoteDatasource.getUsersWithPhoneNumber(phoneNumber);
      
      if (usersWithPhone.isEmpty) {
        return ApiResult.success(null);
      }
      
      final userModel = usersWithPhone.firstWhere(
        (user) => user.phoneVerified,
        orElse: () => usersWithPhone.first,
      );
      
      final authUser = AuthUser(
        uid: userModel.uid,
        email: userModel.email,
        displayName: userModel.displayName,
        fullName: userModel.fullName,
        birthDate: userModel.birthDate,
        phoneNumber: userModel.phoneNumber,
        photoURL: userModel.photoURL,
        emailVerified: userModel.emailVerified,
        phoneVerified: userModel.phoneVerified,
        providers: userModel.providers,
        isProfileComplete: userModel.isProfileComplete,
      );
      
      return ApiResult.success(authUser);
    });
  }

  @override
  Future<ApiResult<AuthUser>> createUserWithFullInfo({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      
      final user = await _remoteDatasource.createUserWithEmailAndPassword(email, password);
      
      await user.updateDisplayName(fullName);
      await user.reload();
      final refreshedUser = _remoteDatasource.getCurrentUser();
      
      if (refreshedUser == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Failed to create user account.',
        );
      }
      
      final authUser = _mapFirebaseUserToAuthUser(refreshedUser).copyWith(
        displayName: fullName,
      );
      
      await _saveUserDataLocally(authUser);
      
      final userModel = UserModel(
        uid: authUser.uid,
        email: authUser.email,
        displayName: fullName,
        photoURL: authUser.photoURL,
        emailVerified: authUser.emailVerified,
        phoneVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        providers: authUser.providers,
        isProfileComplete: false,
      );

      await _remoteDatasource.saveUserToFirestore(userModel);
      
      return ApiResult.success(authUser.copyWith(
        displayName: fullName,
        phoneVerified: false,
        isPhoneRequired: true,
        isProfileComplete: false,
      ));
    });
  }

  Future<void> _handleNewUserPhoneVerification(User user, String phoneNumber) async {
    final currentDevice = await _deviceInfoService.getCurrentDevice();
    
    final existingUserModel = await _remoteDatasource.getUserFromFirestore(user.uid);
    
    if (existingUserModel != null) {
      final updatedUserModel = existingUserModel.copyWith(
        phoneNumber: phoneNumber,
        phoneVerified: true,
        updatedAt: DateTime.now(),
      ).addVerifiedDevice(currentDevice);
      
      await _remoteDatasource.saveUserToFirestore(updatedUserModel);
    } else {
      final newUserModel = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        phoneNumber: phoneNumber,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        phoneVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        verifiedDevices: [currentDevice],
        providers: user.providerData.map((info) => info.providerId).toList(),
        isProfileComplete: false,
      );
      
      await _remoteDatasource.saveUserToFirestore(newUserModel);
    }
  }

  Future<void> _handleExistingPhoneVerification(User user, String phoneNumber) async {
    final currentDevice = await _deviceInfoService.getCurrentDevice();
    final userModel = await _remoteDatasource.getUserFromFirestore(user.uid);
    
    if (userModel != null) {
      final updatedUserModel = userModel.copyWith(
        phoneNumber: phoneNumber,
        phoneVerified: true,
        updatedAt: DateTime.now(),
      ).addVerifiedDevice(currentDevice);
      
      await _remoteDatasource.saveUserToFirestore(updatedUserModel);
    } else {
      final newUserModel = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        phoneNumber: phoneNumber,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        phoneVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        verifiedDevices: [currentDevice],
        providers: user.providerData.map((info) => info.providerId).toList(),
        isProfileComplete: false,
      );
      
      await _remoteDatasource.saveUserToFirestore(newUserModel);
    }
  }

  Future<AuthUser> _processNewUser(User firebaseUser) async {
    final authUser = _mapFirebaseUserToAuthUser(firebaseUser);
    
    await _saveUserDataLocally(authUser);
    
    final existingUserModel = await _remoteDatasource.getUserFromFirestore(authUser.uid);
    
    if (existingUserModel == null) {
      final userModel = UserModel(
        uid: authUser.uid,
        email: authUser.email,
        displayName: authUser.displayName,
        phoneNumber: authUser.phoneNumber,
        photoURL: authUser.photoURL,
        emailVerified: authUser.emailVerified,
        phoneVerified: authUser.phoneNumber != null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        providers: authUser.providers,
        isProfileComplete: false,
      );

      await _remoteDatasource.saveUserToFirestore(userModel);
      
      return authUser.copyWith(
        phoneVerified: authUser.phoneNumber != null,
        isProfileComplete: false,
      );
    }
    
    final currentDevice = await _deviceInfoService.getCurrentDevice();
    final isDeviceVerified = existingUserModel.isDeviceVerified(currentDevice.deviceId);
    
    return authUser.copyWith(
      fullName: existingUserModel.fullName,
      birthDate: existingUserModel.birthDate,
      phoneVerified: existingUserModel.phoneVerified && isDeviceVerified,
      isPhoneRequired: !(existingUserModel.phoneVerified && isDeviceVerified),
      isProfileComplete: existingUserModel.isProfileComplete,
    );
  }

  Future<AuthUser> _processAuthenticatedUser(User firebaseUser) async {
    final authUser = _mapFirebaseUserToAuthUser(firebaseUser);
    
    await _saveUserDataLocally(authUser);
    
    final userModel = await _remoteDatasource.getUserFromFirestore(authUser.uid);
    
    if (userModel != null) {
      final currentDevice = await _deviceInfoService.getCurrentDevice();
      final isDeviceVerified = userModel.isDeviceVerified(currentDevice.deviceId);
      
      bool effectivePhoneVerified = userModel.phoneVerified && isDeviceVerified;
      
      if (authUser.phoneNumber != null && userModel.phoneNumber == null) {
        final updatedUserModel = userModel.copyWith(
          phoneNumber: authUser.phoneNumber,
          updatedAt: DateTime.now(),
        );
        await _remoteDatasource.saveUserToFirestore(updatedUserModel);
      }
      
      return authUser.copyWith(
        fullName: userModel.fullName,
        birthDate: userModel.birthDate,
        phoneVerified: effectivePhoneVerified,
        isPhoneRequired: !effectivePhoneVerified,
        isProfileComplete: userModel.isProfileComplete,
      );
    } else {
      final newUserModel = UserModel(
        uid: authUser.uid,
        email: authUser.email,
        displayName: authUser.displayName,
        phoneNumber: authUser.phoneNumber,
        photoURL: authUser.photoURL,
        emailVerified: authUser.emailVerified,
        phoneVerified: authUser.phoneNumber != null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        providers: authUser.providers,
        isProfileComplete: false,
      );

      await _remoteDatasource.saveUserToFirestore(newUserModel);
      
      return authUser.copyWith(
        phoneVerified: authUser.phoneNumber != null,
        isPhoneRequired: authUser.phoneNumber == null,
        isProfileComplete: false,
      );
    }
  }

  Future<void> _updateUserPhoneVerification(String uid, String phoneNumber, bool verified) async {
    final currentDevice = await _deviceInfoService.getCurrentDevice();
    final userModel = await _remoteDatasource.getUserFromFirestore(uid);
    
    if (userModel != null) {
      final updatedUserModel = userModel.copyWith(
        phoneNumber: phoneNumber,
        phoneVerified: verified,
        updatedAt: DateTime.now(),
      );
      
      final finalUserModel = verified 
          ? updatedUserModel.addVerifiedDevice(currentDevice)
          : updatedUserModel;
          
      await _remoteDatasource.saveUserToFirestore(finalUserModel);
    } else {
      final currentUser = _remoteDatasource.getCurrentUser();
      final providers = currentUser?.providerData.map((info) => info.providerId).toList() ?? [];
      
      final newUserModel = UserModel(
        uid: uid,
        email: currentUser?.email,
        displayName: currentUser?.displayName,
        phoneNumber: phoneNumber,
        photoURL: currentUser?.photoURL,
        emailVerified: currentUser?.emailVerified ?? false,
        phoneVerified: verified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        verifiedDevices: verified ? [currentDevice] : [],
        providers: providers,
        isProfileComplete: false,
      );
      
      await _remoteDatasource.saveUserToFirestore(newUserModel);
    }
  }

  Future<void> _saveUserDataLocally(AuthUser authUser) async {
    await _localDatasource.saveUserData(
      uid: authUser.uid,
      email: authUser.email,
      displayName: authUser.displayName,
      phoneNumber: authUser.phoneNumber,
      photoURL: authUser.photoURL,
      emailVerified: authUser.emailVerified,
    );
  }

  AuthUser _mapFirebaseUserToAuthUser(User user) {
    final providers = user.providerData.map((info) => info.providerId).toList();
    
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      phoneVerified: user.phoneNumber != null,
      providers: providers,
      isProfileComplete: false,
    );
  }
}