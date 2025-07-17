import 'package:udharoo/features/transactions/data/models/transaction_model.dart';

abstract class TransactionLocalDatasource {
  Future<List<TransactionModel>> getCachedTransactions(String userId);
  Future<void> cacheTransactions(String userId, List<TransactionModel> transactions);
  Future<void> clearTransactionCache(String userId);
  Future<TransactionModel?> getCachedTransaction(String transactionId);
  Future<void> cacheTransaction(TransactionModel transaction);
}