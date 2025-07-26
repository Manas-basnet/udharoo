import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/data/models/qr_data_model.dart';
import 'package:udharoo/features/transactions/domain/datasources/local/transaction_local_datasource.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';

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
        .map((transaction) => _transactionToLocalJson(transaction))
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
        .map((json) => _transactionFromLocalJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheTransaction(String userId, TransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _getUserTransactionKey(userId, transaction.id),
      jsonEncode(_transactionToLocalJson(transaction)),
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
    return _transactionFromLocalJson(transactionJson);
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

  @override
  Future<void> removeDeletedTransactions(String userId, List<String> deletedTransactionIds) async {
    if (deletedTransactionIds.isEmpty) return;

    final existingTransactions = await getCachedTransactions(userId);
    final filteredTransactions = existingTransactions
        .where((transaction) => !deletedTransactionIds.contains(transaction.id))
        .toList();
    
    await cacheTransactions(userId, filteredTransactions);

    for (final id in deletedTransactionIds) {
      await removeCachedTransaction(userId, id);
    }
  }

  Map<String, dynamic> _transactionToLocalJson(TransactionModel transaction) {
    return {
      'id': transaction.id,
      'creatorId': transaction.creatorId,
      'recipientId': transaction.recipientId,
      'creatorPhone': transaction.creatorPhone,
      'recipientPhone': transaction.recipientPhone,
      'contactName': transaction.contactName,
      'contactEmail': transaction.contactEmail,
      'type': transaction.type.name,
      'amount': transaction.amount,
      'description': transaction.description,
      'dueDate': transaction.dueDate?.toIso8601String(),
      'isVerified': transaction.isVerified,
      'verificationRequired': transaction.verificationRequired,
      'status': transaction.status.name,
      'isDeleted': transaction.isDeleted,
      'createdAt': transaction.createdAt.toIso8601String(),
      'updatedAt': transaction.updatedAt.toIso8601String(),
      'deletedAt': transaction.deletedAt?.toIso8601String(),
      'deletedBy': transaction.deletedBy,
      'completedAt': transaction.completedAt?.toIso8601String(),
      'completedBy': transaction.completedBy,
      'verifiedBy': transaction.verifiedBy,
      'qrGeneratedData': transaction.qrGeneratedData != null
          ? _qrDataToLocalJson(transaction.qrGeneratedData!)
          : null,
      'completionRequested': transaction.completionRequested,
      'completionRequestedBy': transaction.completionRequestedBy,
      'completionRequestedAt': transaction.completionRequestedAt?.toIso8601String(),
    };
  }

  TransactionModel _transactionFromLocalJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String? ?? json['createdBy'] as String,
      recipientId: json['recipientId'] as String?,
      creatorPhone: json['creatorPhone'] as String? ?? '',
      recipientPhone: json['recipientPhone'] as String? ?? json['contactPhone'] as String?,
      contactName: json['contactName'] as String,
      contactEmail: json['contactEmail'] as String?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationRequired: json['verificationRequired'] as bool? ?? false,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      deletedBy: json['deletedBy'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      completedBy: json['completedBy'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      qrGeneratedData: json['qrGeneratedData'] != null
          ? _qrDataFromLocalJson(json['qrGeneratedData'] as Map<String, dynamic>)
          : null,
      completionRequested: json['completionRequested'] as bool? ?? false,
      completionRequestedBy: json['completionRequestedBy'] as String?,
      completionRequestedAt: json['completionRequestedAt'] != null
          ? DateTime.parse(json['completionRequestedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> _qrDataToLocalJson(QRData qrData) {
    return {
      'userPhone': qrData.userPhone,
      'userName': qrData.userName,
      'userEmail': qrData.userEmail,
      'verificationRequired': qrData.verificationRequired,
      'generatedAt': qrData.generatedAt.toIso8601String(),
      'customMessage': qrData.customMessage,
    };
  }

  dynamic _qrDataFromLocalJson(Map<String, dynamic> json) {
    return QRDataModel(
      userPhone: json['userPhone'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String?,
      verificationRequired: json['verificationRequired'] as bool,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      customMessage: json['customMessage'] as String?,
    );
  }
}