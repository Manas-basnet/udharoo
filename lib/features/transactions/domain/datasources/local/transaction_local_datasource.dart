import 'package:udharoo/features/transactions/data/models/transaction_model.dart';

abstract class TransactionLocalDatasource {
  Future<void> cacheTransactions(List<TransactionModel> transactions);
  Future<List<TransactionModel>> getCachedTransactions();
  Future<void> cacheTransaction(TransactionModel transaction);
  Future<TransactionModel?> getCachedTransaction(String id);
  Future<void> removeCachedTransaction(String id);
  Future<void> clearCache();
  
  Future<void> setLastSyncTimestamp(DateTime timestamp);
  Future<DateTime?> getLastSyncTimestamp();
  Future<void> mergeTransactions(List<TransactionModel> transactions);
}