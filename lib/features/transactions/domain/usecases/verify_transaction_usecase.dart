import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class VerifyTransactionUseCase {
  final TransactionRepository repository;

  VerifyTransactionUseCase(this.repository);

  Future<ApiResult<Transaction>> call(String id, String verifiedBy) {
    return repository.verifyTransaction(id, verifiedBy);
  }
}