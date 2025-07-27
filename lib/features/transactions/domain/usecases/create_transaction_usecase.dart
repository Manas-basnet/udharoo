import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class CreateTransactionUseCase {
  final TransactionRepository repository;

  CreateTransactionUseCase(this.repository);

  Future<ApiResult<void>> call({
    required double amount,
    required String otherPartyUid,
    required String otherPartyName,
    required String otherPartyPhone,
    required String description,
    required TransactionType type,
  }) {
    return repository.createTransaction(
      amount: amount,
      otherPartyUid: otherPartyUid,
      otherPartyName: otherPartyName,
      otherPartyPhone: otherPartyPhone,
      description: description,
      type: type,
    );
  }
}