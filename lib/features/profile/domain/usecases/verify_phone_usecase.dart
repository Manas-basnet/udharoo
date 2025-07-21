import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/profile/domain/repositories/profile_repository.dart';

class SendPhoneVerificationUseCase {
  final ProfileRepository repository;

  SendPhoneVerificationUseCase(this.repository);

  Future<ApiResult<void>> call(String phoneNumber) {
    return repository.sendPhoneVerification(phoneNumber);
  }
}

class VerifyPhoneNumberUseCase {
  final ProfileRepository repository;

  VerifyPhoneNumberUseCase(this.repository);

  Future<ApiResult<void>> call(String verificationId, String smsCode) {
    return repository.verifyPhoneNumber(verificationId, smsCode);
  }
}