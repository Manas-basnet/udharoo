import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/domain/datasources/local/transaction_local_datasource.dart';

class TransactionLocalDatasourceImpl implements TransactionLocalDatasource {
  static const String _transactionsKey = 'cached_transactions';
  static const String _transactionPrefix = 'cached_transaction_';

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
}