import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/data/models/transaction_contact_model.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';

abstract class TransactionRemoteDatasource {
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  Future<List<TransactionModel>> getTransactions({
    String? userId,
    TransactionStatus? status,
    TransactionType? type,
    String? searchQuery,
    int? limit,
    String? lastDocumentId,
    DateTime? lastSyncTime,
  });
  Future<TransactionModel> getTransactionById(String id, String userId);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id, String userId);
  Future<TransactionModel> verifyTransaction(String id, String verifiedBy);
  Future<List<TransactionContactModel>> getTransactionContacts(String userId);
  Future<List<TransactionModel>> getContactTransactions(String userId, String contactPhone);
  Future<bool> getGlobalVerificationSetting(String userId);
  Future<void> setGlobalVerificationSetting(String userId, bool enabled);
  Future<Map<String, dynamic>> getTransactionStats(String userId);
  Future<String?> verifyPhoneExists(String phoneNumber);
  Future<List<TransactionModel>> getReceivedTransactionRequests(String userId);
}