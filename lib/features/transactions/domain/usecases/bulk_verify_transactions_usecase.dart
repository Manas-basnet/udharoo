import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/bulk_operation_result.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class BulkVerifyTransactionsUseCase {
  final TransactionRepository repository;

  BulkVerifyTransactionsUseCase(this.repository);

  Future<ApiResult<BulkOperationResult>> call(List<String> transactionIds) {
    return repository.bulkVerifyTransactions(transactionIds);
  }
}