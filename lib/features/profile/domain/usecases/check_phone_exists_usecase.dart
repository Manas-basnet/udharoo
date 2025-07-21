import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/profile/domain/repositories/profile_repository.dart';

class CheckPhoneExistsUseCase {
  final ProfileRepository repository;

  CheckPhoneExistsUseCase(this.repository);

  Future<ApiResult<bool>> call(String phoneNumber) {
    return repository.checkPhoneNumberExists(phoneNumber);
  }
}
