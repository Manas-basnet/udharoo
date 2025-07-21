import 'dart:io';
import 'package:udharoo/core/data/base_repository.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/profile/data/models/user_profile_model.dart';
import 'package:udharoo/features/profile/domain/entities/user_profile.dart';
import 'package:udharoo/features/profile/domain/entities/profile_update_request.dart';
import 'package:udharoo/features/profile/domain/repositories/profile_repository.dart';
import 'package:udharoo/features/profile/domain/datasources/remote/profile_remote_datasource.dart';
import 'package:udharoo/features/profile/domain/datasources/local/profile_local_datasource.dart';

class ProfileRepositoryImpl extends BaseRepository implements ProfileRepository {
  final ProfileRemoteDatasource _remoteDatasource;
  final ProfileLocalDatasource _localDatasource;

  ProfileRepositoryImpl({
    required ProfileRemoteDatasource remoteDatasource,
    required ProfileLocalDatasource localDatasource,
    required super.networkInfo,
  }) : _remoteDatasource = remoteDatasource,
       _localDatasource = localDatasource;

  @override
  Future<ApiResult<UserProfile>> getUserProfile(String uid) async {
    return handleCacheCallFirst<UserProfile>(
      localCall: () async {
        final cachedProfile = await _localDatasource.getCachedUserProfile(uid);
        if (cachedProfile != null) {
          return ApiResult.success(cachedProfile);
        }
        return ApiResult.failure('Profile not found in cache', FailureType.notFound);
      },
      remoteCall: () async {
        final profile = await _remoteDatasource.getUserProfile(uid);
        if (profile != null) {
          return ApiResult.success(profile);
        }
        return ApiResult.failure('Profile not found', FailureType.notFound);
      },
      saveLocalData: (profile) async {
        if (profile != null) {
          final profileModel = UserProfileModel.fromEntity(profile);
          await _localDatasource.cacheUserProfile(profileModel);
        }
      },
    );
  }

  @override
  Future<ApiResult<UserProfile>> updateProfile(String uid, ProfileUpdateRequest request) async {
    return handleRemoteCallFirst<UserProfile>(
      remoteCall: () async {
        final existingProfile = await _remoteDatasource.getUserProfile(uid);
        if (existingProfile == null) {
          return ApiResult.failure('Profile not found', FailureType.notFound);
        }

        String? newPhotoURL = existingProfile.photoURL;
        
        if (request.profileImage != null) {
          if (existingProfile.photoURL != null) {
            try {
              await _remoteDatasource.deleteProfileImage(uid, existingProfile.photoURL!);
            } catch (e) {
              // Continue even if deletion fails
            }
          }
          
          newPhotoURL = await _remoteDatasource.uploadProfileImage(uid, request.profileImage!);
        }

        final updatedProfile = existingProfile.copyWith(
          displayName: request.displayName,
          phoneNumber: request.phoneNumber,
          photoURL: newPhotoURL,
        );

        final result = await _remoteDatasource.updateUserProfile(updatedProfile);
        return ApiResult.success(result);
      },
      saveLocalData: (profile) async {
        if (profile != null) {
          final profileModel = UserProfileModel.fromEntity(profile);
          await _localDatasource.cacheUserProfile(profileModel);
        }
      },
    );
  }

  @override
  Future<ApiResult<String>> uploadProfileImage(String uid, File imageFile) async {
    return handleRemoteCallFirst<String>(
      remoteCall: () async {
        final downloadUrl = await _remoteDatasource.uploadProfileImage(uid, imageFile);
        return ApiResult.success(downloadUrl);
      },
      saveLocalData: (_) async {},
    );
  }

  @override
  Future<ApiResult<void>> deleteProfileImage(String uid) async {
    return handleRemoteCallFirst<void>(
      remoteCall: () async {
        final profile = await _remoteDatasource.getUserProfile(uid);
        if (profile?.photoURL != null) {
          await _remoteDatasource.deleteProfileImage(uid, profile!.photoURL!);
          
          final updatedProfile = profile.copyWith(photoURL: null);
          await _remoteDatasource.updateUserProfile(updatedProfile);
        }
        return ApiResult.success(null);
      },
      saveLocalData: (_) async {
        final cachedProfile = await _localDatasource.getCachedUserProfile(uid);
        if (cachedProfile != null) {
          final updatedProfile = cachedProfile.copyWith(photoURL: null);
          await _localDatasource.cacheUserProfile(updatedProfile);
        }
      },
    );
  }

  @override
  Future<ApiResult<bool>> checkPhoneNumberExists(String phoneNumber) async {
    return handleRemoteCallFirst<bool>(
      remoteCall: () async {
        final exists = await _remoteDatasource.checkPhoneNumberExists(phoneNumber);
        return ApiResult.success(exists);
      },
      saveLocalData: (_) async {},
    );
  }

  @override
  Future<ApiResult<void>> sendPhoneVerification(String phoneNumber) async {
    return handleRemoteCallFirst<void>(
      remoteCall: () async {
        await _remoteDatasource.sendPhoneVerification(phoneNumber);
        return ApiResult.success(null);
      },
      saveLocalData: (_) async {},
    );
  }

  @override
  Future<ApiResult<void>> verifyPhoneNumber(String verificationId, String smsCode) async {
    return handleRemoteCallFirst<void>(
      remoteCall: () async {
        await _remoteDatasource.verifyPhoneNumber(verificationId, smsCode);
        return ApiResult.success(null);
      },
      saveLocalData: (_) async {},
    );
  }

  @override
  Future<ApiResult<UserProfile>> createUserProfile(UserProfile profile) async {
    return handleRemoteCallFirst<UserProfile>(
      remoteCall: () async {
        final profileModel = UserProfileModel.fromEntity(profile);
        final created = await _remoteDatasource.createUserProfile(profileModel);
        return ApiResult.success(created);
      },
      saveLocalData: (profile) async {
        if (profile != null) {
          final profileModel = UserProfileModel.fromEntity(profile);
          await _localDatasource.cacheUserProfile(profileModel);
        }
      },
    );
  }
}