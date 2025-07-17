import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class CreateTransactionUseCase {
  final TransactionRepository repository;

  CreateTransactionUseCase(this.repository);

  Future<ApiResult<Transaction>> call({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required TransactionType type,
    String? description,
    DateTime? dueDate,
    bool requiresVerification = true,
    String? fromUserName,
    String? toUserName,
    String? fromUserPhone,
    String? toUserPhone,
  }) async {
    final transaction = Transaction(
      id: '',
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      type: type,
      status: requiresVerification ? TransactionStatus.pending : TransactionStatus.verified,
      description: description,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      fromUserName: fromUserName,
      toUserName: toUserName,
      fromUserPhone: fromUserPhone,
      toUserPhone: toUserPhone,
    );

    return repository.createTransaction(transaction);
  }
}