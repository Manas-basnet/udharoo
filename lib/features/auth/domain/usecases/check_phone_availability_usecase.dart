import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class CheckPhoneAvailabilityUseCase {
  final AuthRepository repository;

  CheckPhoneAvailabilityUseCase(this.repository);

  Future<ApiResult<bool>> call(String phoneNumber) {
    return repository.checkPhoneNumberAvailability(phoneNumber);
  }
}