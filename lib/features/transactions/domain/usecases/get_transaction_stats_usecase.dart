import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class GetTransactionStatsUseCase {
  final TransactionRepository repository;

  GetTransactionStatsUseCase(this.repository);

  Future<ApiResult<Map<String, dynamic>>> call() {
    return repository.getTransactionStats();
  }
}