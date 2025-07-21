import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/profile/domain/entities/user_profile.dart';
import 'package:udharoo/features/profile/domain/entities/profile_update_request.dart';
import 'package:udharoo/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<ApiResult<UserProfile>> call(String uid, ProfileUpdateRequest request) {
    return repository.updateProfile(uid, request);
  }
}
