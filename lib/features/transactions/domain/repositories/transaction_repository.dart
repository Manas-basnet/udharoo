import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<ApiResult<void>> createTransaction({
    required double amount,
    required String otherPartyUid,
    required String otherPartyName,
    required String description,
    required TransactionType type,
  });

  Stream<List<Transaction>> getTransactions();

  Future<ApiResult<void>> updateTransactionStatus({
    required String transactionId,
    required TransactionStatus status,
  });

  Future<ApiResult<void>> verifyTransaction(String transactionId);

  Future<ApiResult<void>> completeTransaction(String transactionId);

  Future<ApiResult<void>> rejectTransaction(String transactionId);

  Future<ApiResult<List<Transaction>>> getTransactionsByType(TransactionType type);

  Future<ApiResult<List<Transaction>>> getTransactionsByStatus(TransactionStatus status);

  Future<ApiResult<Transaction?>> getTransactionById(String transactionId);
}