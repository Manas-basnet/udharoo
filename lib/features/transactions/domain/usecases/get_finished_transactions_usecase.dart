import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class GetFinishedTransactionsUseCase {
  final TransactionRepository repository;

  GetFinishedTransactionsUseCase(this.repository);

  Future<ApiResult<List<Transaction>>> call() {
    return repository.getFinishedTransactions();
  }
}