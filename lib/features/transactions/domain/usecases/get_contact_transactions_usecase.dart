import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class GetContactTransactionsUseCase {
  final TransactionRepository repository;

  GetContactTransactionsUseCase(this.repository);

  Future<ApiResult<List<Transaction>>> call(String contactPhone) {
    return repository.getContactTransactions(contactPhone);
  }
}