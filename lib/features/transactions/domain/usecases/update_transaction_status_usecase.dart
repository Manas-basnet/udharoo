import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class UpdateTransactionStatusUseCase {
  final TransactionRepository repository;

  UpdateTransactionStatusUseCase(this.repository);

  Future<ApiResult<void>> call({
    required String transactionId,
    required TransactionStatus status,
  }) {
    return repository.updateTransactionStatus(
      transactionId: transactionId,
      status: status,
    );
  }
}