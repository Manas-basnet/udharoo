import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/domain/datasources/local/transaction_local_datasource.dart';

class TransactionLocalDatasourceImpl implements TransactionLocalDatasource {
  static const String _transactionsKey = 'cached_transactions';
  static const String _transactionPrefix = 'cached_transaction_';
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';

  @override
  Future<void> cacheTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions
        .map((transaction) => transaction.toJson())
        .toList();
    
    await prefs.setString(_transactionsKey, jsonEncode(transactionsJson));
  }

  @override
  Future<List<TransactionModel>> getCachedTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsString = prefs.getString(_transactionsKey);
    
    if (transactionsString == null) {
      return [];
    }

    final transactionsJson = jsonDecode(transactionsString) as List<dynamic>;
    return transactionsJson
        .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheTransaction(TransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_transactionPrefix${transaction.id}',
      jsonEncode(transaction.toJson()),
    );
  }

  @override
  Future<TransactionModel?> getCachedTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionString = prefs.getString('$_transactionPrefix$id');
    
    if (transactionString == null) {
      return null;
    }

    final transactionJson = jsonDecode(transactionString) as Map<String, dynamic>;
    return TransactionModel.fromJson(transactionJson);
  }

  @override
  Future<void> removeCachedTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_transactionPrefix$id');
  }

  @override
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_transactionPrefix) || key == _transactionsKey) {
        await prefs.remove(key);
      }
    }
  }

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncTimestampKey, timestamp.toIso8601String());
  }

  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampString = prefs.getString(_lastSyncTimestampKey);
    
    if (timestampString == null) {
      return null;
    }
    
    return DateTime.parse(timestampString);
  }

  @override
  Future<void> mergeTransactions(List<TransactionModel> newTransactions) async {
    final existingTransactions = await getCachedTransactions();
    final transactionMap = <String, TransactionModel>{};
    
    for (final transaction in existingTransactions) {
      transactionMap[transaction.id] = transaction;
    }
    
    for (final transaction in newTransactions) {
      transactionMap[transaction.id] = transaction;
    }
    
    final mergedTransactions = transactionMap.values.toList();
    mergedTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    await cacheTransactions(mergedTransactions);
  }
}