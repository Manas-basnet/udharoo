import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class SendPhoneVerificationCodeUseCase {
  final AuthRepository repository;

  SendPhoneVerificationCodeUseCase(this.repository);

  Future<ApiResult<String>> call(String phoneNumber) {
    return repository.sendPhoneVerificationCode(phoneNumber);
  }
}







