import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/profile/domain/entities/user_profile.dart';
import 'package:udharoo/features/profile/domain/entities/profile_update_request.dart';
import 'package:udharoo/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:udharoo/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:udharoo/features/profile/domain/usecases/check_phone_exists_usecase.dart';
import 'package:udharoo/features/profile/domain/usecases/verify_phone_usecase.dart';
import 'package:udharoo/features/profile/domain/usecases/create_user_profile_usecase.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetUserProfileUseCase getUserProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final CheckPhoneExistsUseCase checkPhoneExistsUseCase;
  final SendPhoneVerificationUseCase sendPhoneVerificationUseCase;
  final VerifyPhoneNumberUseCase verifyPhoneNumberUseCase;
  final CreateUserProfileUseCase createUserProfileUseCase;

  ProfileCubit({
    required this.getUserProfileUseCase,
    required this.updateProfileUseCase,
    required this.checkPhoneExistsUseCase,
    required this.sendPhoneVerificationUseCase,
    required this.verifyPhoneNumberUseCase,
    required this.createUserProfileUseCase,
  }) : super(const ProfileInitial());

  Future<void> loadUserProfile(String uid) async {
    emit(const ProfileLoading());

    final result = await getUserProfileUseCase(uid);

    if (!isClosed) {
      result.fold(
        onSuccess: (profile) => emit(ProfileLoaded(profile)),
        onFailure: (message, type) => emit(ProfileError(message, type)),
      );
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    File? profileImage,
  }) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating(currentState.profile));

      final request = ProfileUpdateRequest(
        displayName: displayName,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
      );

      final result = await updateProfileUseCase(uid, request);

      if (!isClosed) {
        result.fold(
          onSuccess: (profile) => emit(ProfileLoaded(profile)),
          onFailure: (message, type) => emit(ProfileError(message, type)),
        );
      }
    }
  }

  Future<bool> checkPhoneExists(String phoneNumber) async {
    final result = await checkPhoneExistsUseCase(phoneNumber);
    
    return result.fold(
      onSuccess: (exists) => exists,
      onFailure: (_, __) => false,
    );
  }

  Future<void> sendPhoneVerification(String phoneNumber) async {
    emit(const ProfileLoading());

    final result = await sendPhoneVerificationUseCase(phoneNumber);

    if (!isClosed) {
      result.fold(
        onSuccess: (verificationId) => emit(PhoneVerificationSent(verificationId, phoneNumber)),
        onFailure: (message, type) => emit(ProfileError(message, type)),
      );
    }
  }

  Future<void> verifyPhoneNumber(String verificationId, String smsCode, String uid) async {
    emit(const ProfileLoading());

    final result = await verifyPhoneNumberUseCase(verificationId, smsCode);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) async {
          final profileResult = await getUserProfileUseCase(uid);
          profileResult.fold(
            onSuccess: (profile) {
              final updatedProfile = profile.copyWith(phoneVerified: true);
              emit(PhoneVerified(updatedProfile));
            },
            onFailure: (message, type) => emit(ProfileError(message, type)),
          );
        },
        onFailure: (message, type) => emit(ProfileError(message, type)),
      );
    }
  }

  Future<void> createProfile(UserProfile profile) async {
    emit(const ProfileLoading());

    final result = await createUserProfileUseCase(profile);

    if (!isClosed) {
      result.fold(
        onSuccess: (profile) => emit(ProfileLoaded(profile)),
        onFailure: (message, type) => emit(ProfileError(message, type)),
      );
    }
  }

  void resetError() {
    if (state is ProfileError && !isClosed) {
      emit(const ProfileInitial());
    }
  }
}