import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/profile/domain/entities/user_profile.dart';
import 'package:udharoo/features/profile/domain/repositories/profile_repository.dart';

class GetUserProfileUseCase {
  final ProfileRepository repository;

  GetUserProfileUseCase(this.repository);

  Future<ApiResult<UserProfile>> call(String uid) {
    return repository.getUserProfile(uid);
  }
}