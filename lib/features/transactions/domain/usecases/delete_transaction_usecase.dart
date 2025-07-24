import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class DeleteTransactionUseCase {
  final TransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<ApiResult<void>> call(String id) {
    return repository.deleteTransaction(id);
  }
}