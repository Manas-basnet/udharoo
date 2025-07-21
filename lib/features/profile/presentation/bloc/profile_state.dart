part of 'profile_cubit.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

final class ProfileError extends ProfileState {
  final String message;
  final FailureType type;

  const ProfileError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}

final class ProfileUpdating extends ProfileState {
  final UserProfile currentProfile;

  const ProfileUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

final class PhoneVerificationSent extends ProfileState {
  final String verificationId;
  final String phoneNumber;

  const PhoneVerificationSent(this.verificationId, this.phoneNumber);

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

final class PhoneVerified extends ProfileState {
  final UserProfile updatedProfile;

  const PhoneVerified(this.updatedProfile);

  @override
  List<Object?> get props => [updatedProfile];
}
