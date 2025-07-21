import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class VerifyPhoneCodeUseCase {
  final AuthRepository repository;

  VerifyPhoneCodeUseCase(this.repository);

  Future<ApiResult<AuthUser>> call(String verificationId, String smsCode) {
    return repository.verifyPhoneCode(verificationId, smsCode);
  }
}