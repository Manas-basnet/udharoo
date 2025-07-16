import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordResetEmailUseCase {
  final AuthRepository repository;

  SendPasswordResetEmailUseCase(this.repository);

  Future<ApiResult<void>> call(String email) {
    return repository.sendPasswordResetEmail(email);
  }
}