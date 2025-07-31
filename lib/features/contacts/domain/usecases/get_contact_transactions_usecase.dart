import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/contacts/domain/repositories/contact_repository.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class GetContactTransactionsUseCase {
  final ContactRepository repository;

  GetContactTransactionsUseCase(this.repository);

  Future<ApiResult<List<Transaction>>> call(String contactUserId) {
    return repository.getContactTransactions(contactUserId);
  }
}