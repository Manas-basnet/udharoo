import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/domain/datasources/local/transaction_local_datasource.dart';

class TransactionLocalDatasourceImpl implements TransactionLocalDatasource {
  static const String _transactionsKey = 'cached_transactions_';
  static const String _transactionKey = 'cached_transaction_';

  @override
  Future<List<TransactionModel>> getCachedTransactions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('${_transactionsKey}$userId');
      
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList
            .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheTransactions(String userId, List<TransactionModel> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = transactions.map((transaction) => transaction.toJson()).toList();
      await prefs.setString('${_transactionsKey}$userId', jsonEncode(jsonList));
    } catch (e) {
      // Silently ignore cache errors
    }
  }

  @override
  Future<void> clearTransactionCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_transactionsKey}$userId');
    } catch (e) {
      // Silently ignore cache errors
    }
  }

  @override
  Future<TransactionModel?> getCachedTransaction(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('${_transactionKey}$transactionId');
      
      if (cachedData != null) {
        final json = jsonDecode(cachedData) as Map<String, dynamic>;
        return TransactionModel.fromJson(json);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheTransaction(TransactionModel transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_transactionKey}${transaction.id}', 
        jsonEncode(transaction.toJson()),
      );
    } catch (e) {
      // Silently ignore cache errors
    }
  }
}