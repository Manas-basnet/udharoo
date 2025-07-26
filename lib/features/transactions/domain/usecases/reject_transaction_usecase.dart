import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class RejectTransactionUseCase {
  final TransactionRepository repository;

  RejectTransactionUseCase(this.repository);

  Future<ApiResult<void>> call(String transactionId) {
    return repository.rejectTransaction(transactionId);
  }
}
