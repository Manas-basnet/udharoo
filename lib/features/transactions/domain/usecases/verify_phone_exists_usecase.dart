import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class VerifyPhoneExistsUseCase {
  final TransactionRepository repository;

  VerifyPhoneExistsUseCase(this.repository);

  Future<ApiResult<String?>> call(String phoneNumber) {
    return repository.verifyPhoneExists(phoneNumber);
  }
}