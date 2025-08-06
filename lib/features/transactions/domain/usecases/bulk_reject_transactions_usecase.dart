import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/bulk_operation_result.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class BulkRejectTransactionsUseCase {
  final TransactionRepository repository;

  BulkRejectTransactionsUseCase(this.repository);

  Future<ApiResult<BulkOperationResult>> call(List<String> transactionIds) {
    return repository.bulkRejectTransactions(transactionIds);
  }
}