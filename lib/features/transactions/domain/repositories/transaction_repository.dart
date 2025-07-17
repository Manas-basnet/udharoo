import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<ApiResult<List<Transaction>>> getTransactions({
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
  });
  
  Future<ApiResult<Transaction>> getTransactionById(String transactionId);
  
  Future<ApiResult<Transaction>> createTransaction(Transaction transaction);
  
  Future<ApiResult<Transaction>> updateTransactionStatus(
    String transactionId, 
    TransactionStatus status,
  );
  
  Future<ApiResult<void>> deleteTransaction(String transactionId);
  
  Stream<List<Transaction>> watchTransactions(String userId);
  
  Future<ApiResult<List<Transaction>>> searchTransactions({
    required String userId,
    String? query,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<ApiResult<Map<String, double>>> getTransactionSummary(String userId);
}