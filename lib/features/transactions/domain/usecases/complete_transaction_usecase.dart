import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class CompleteTransactionUseCase {
  final TransactionRepository repository;

  CompleteTransactionUseCase(this.repository);

  Future<ApiResult<Transaction>> call(String id) {
    return repository.completeTransaction(id);
  }
}