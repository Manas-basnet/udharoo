import 'package:udharoo/features/transactions/data/models/transaction_model.dart';

abstract class TransactionLocalDatasource {
  Future<void> cacheTransactions(String userId, List<TransactionModel> transactions);
  Future<List<TransactionModel>> getCachedTransactions(String userId);
  Future<void> cacheTransaction(String userId, TransactionModel transaction);
  Future<TransactionModel?> getCachedTransaction(String userId, String id);
  Future<void> removeCachedTransaction(String userId, String id);
  Future<void> clearCache(String userId);
  Future<void> clearAllCache();
  
  Future<void> setLastSyncTimestamp(String userId, DateTime timestamp);
  Future<DateTime?> getLastSyncTimestamp(String userId);
  Future<void> mergeTransactions(String userId, List<TransactionModel> transactions);
}