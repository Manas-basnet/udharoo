import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/profile/domain/entities/user_profile.dart';
import 'package:udharoo/features/profile/domain/repositories/profile_repository.dart';

class CreateUserProfileUseCase {
  final ProfileRepository repository;

  CreateUserProfileUseCase(this.repository);

  Future<ApiResult<UserProfile>> call(UserProfile profile) {
    return repository.createUserProfile(profile);
  }
}