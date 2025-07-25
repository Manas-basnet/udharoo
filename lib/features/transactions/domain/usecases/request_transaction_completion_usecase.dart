import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class RequestTransactionCompletionUseCase {
  final TransactionRepository repository;

  RequestTransactionCompletionUseCase(this.repository);

  Future<ApiResult<Transaction>> call(String transactionId, String requestedBy) {
    return repository.requestTransactionCompletion(transactionId, requestedBy);
  }
}