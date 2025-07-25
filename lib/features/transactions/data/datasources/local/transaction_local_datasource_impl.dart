import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/domain/datasources/local/transaction_local_datasource.dart';

class TransactionLocalDatasourceImpl implements TransactionLocalDatasource {
  static const String _transactionsKey = 'cached_transactions';
  static const String _transactionPrefix = 'cached_transaction';
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';

  String _getUserTransactionsKey(String userId) => '${_transactionsKey}_$userId';
  String _getUserTransactionKey(String userId, String transactionId) => '${_transactionPrefix}_${userId}_$transactionId';
  String _getUserSyncKey(String userId) => '${_lastSyncTimestampKey}_$userId';

  @override
  Future<void> cacheTransactions(String userId, List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions
        .map((transaction) => transaction.toJson())
        .toList();
    
    await prefs.setString(_getUserTransactionsKey(userId), jsonEncode(transactionsJson));
  }

  @override
  Future<List<TransactionModel>> getCachedTransactions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsString = prefs.getString(_getUserTransactionsKey(userId));
    
    if (transactionsString == null) {
      return [];
    }

    final transactionsJson = jsonDecode(transactionsString) as List<dynamic>;
    return transactionsJson
        .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheTransaction(String userId, TransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _getUserTransactionKey(userId, transaction.id),
      jsonEncode(transaction.toJson()),
    );
  }

  @override
  Future<TransactionModel?> getCachedTransaction(String userId, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionString = prefs.getString(_getUserTransactionKey(userId, id));
    
    if (transactionString == null) {
      return null;
    }

    final transactionJson = jsonDecode(transactionString) as Map<String, dynamic>;
    return TransactionModel.fromJson(transactionJson);
  }

  @override
  Future<void> removeCachedTransaction(String userId, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getUserTransactionKey(userId, id));
  }

  @override
  Future<void> clearCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.contains('_${userId}_') || key.endsWith('_$userId')) {
        await prefs.remove(key);
      }
    }
  }

  @override
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_transactionPrefix) || 
          key.startsWith(_transactionsKey) || 
          key.startsWith(_lastSyncTimestampKey)) {
        await prefs.remove(key);
      }
    }
  }

  @override
  Future<void> setLastSyncTimestamp(String userId, DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getUserSyncKey(userId), timestamp.toIso8601String());
  }

  @override
  Future<DateTime?> getLastSyncTimestamp(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampString = prefs.getString(_getUserSyncKey(userId));
    
    if (timestampString == null) {
      return null;
    }
    
    return DateTime.parse(timestampString);
  }

  @override
  Future<void> mergeTransactions(String userId, List<TransactionModel> newTransactions) async {
    final existingTransactions = await getCachedTransactions(userId);
    final transactionMap = <String, TransactionModel>{};
    
    for (final transaction in existingTransactions) {
      transactionMap[transaction.id] = transaction;
    }
    
    for (final transaction in newTransactions) {
      transactionMap[transaction.id] = transaction;
    }
    
    final mergedTransactions = transactionMap.values.toList();
    mergedTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    await cacheTransactions(userId, mergedTransactions);
  }
}