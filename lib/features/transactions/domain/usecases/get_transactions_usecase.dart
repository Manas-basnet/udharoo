import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class GetTransactionsUseCase {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<ApiResult<List<Transaction>>> call({
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
  }) {
    return repository.getTransactions(
      userId: userId,
      type: type,
      status: status,
    );
  }
}

class UpdateTransactionStatusUseCase {
  final TransactionRepository repository;

  UpdateTransactionStatusUseCase(this.repository);

  Future<ApiResult<Transaction>> call(
    String transactionId, 
    TransactionStatus status,
  ) {
    return repository.updateTransactionStatus(transactionId, status);
  }
}

class GetTransactionSummaryUseCase {
  final TransactionRepository repository;

  GetTransactionSummaryUseCase(this.repository);

  Future<ApiResult<Map<String, double>>> call(String userId) {
    return repository.getTransactionSummary(userId);
  }
}

class SearchTransactionsUseCase {
  final TransactionRepository repository;

  SearchTransactionsUseCase(this.repository);

  Future<ApiResult<List<Transaction>>> call({
    required String userId,
    String? query,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return repository.searchTransactions(
      userId: userId,
      query: query,
      type: type,
      status: status,
      startDate: startDate,
      endDate: endDate,
    );
  }
}