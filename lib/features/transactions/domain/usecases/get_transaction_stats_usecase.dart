import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_stats.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class GetTransactionStatsUseCase {
  final TransactionRepository repository;

  GetTransactionStatsUseCase(this.repository);

  Future<ApiResult<TransactionStats>> call() {
    return repository.getTransactionStats();
  }
}