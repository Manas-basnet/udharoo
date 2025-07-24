import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';

class GetTransactionsUseCase {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<ApiResult<List<Transaction>>> call({
    TransactionStatus? status,
    TransactionType? type,
    String? searchQuery,
    int? limit,
    String? lastDocumentId,
  }) {
    return repository.getTransactions(
      status: status,
      type: type,
      searchQuery: searchQuery,
      limit: limit,
      lastDocumentId: lastDocumentId,
    );
  }
}