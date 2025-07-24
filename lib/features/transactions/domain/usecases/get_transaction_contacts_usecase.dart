import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class GetTransactionContactsUseCase {
  final TransactionRepository repository;

  GetTransactionContactsUseCase(this.repository);

  Future<ApiResult<List<TransactionContact>>> call() {
    return repository.getTransactionContacts();
  }
}
