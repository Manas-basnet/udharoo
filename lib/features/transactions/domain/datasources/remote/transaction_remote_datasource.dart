import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

abstract class TransactionRemoteDatasource {
  Future<List<TransactionModel>> getTransactions({
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
  });
  
  Future<TransactionModel> getTransactionById(String transactionId);
  
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  
  Future<TransactionModel> updateTransactionStatus(
    String transactionId, 
    TransactionStatus status,
  );
  
  Future<void> deleteTransaction(String transactionId);
  
  Stream<List<TransactionModel>> watchTransactions(String userId);
  
  Future<List<TransactionModel>> searchTransactions({
    required String userId,
    String? query,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<Map<String, double>> getTransactionSummary(String userId);
}