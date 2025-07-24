import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';

abstract class TransactionRepository {
  Future<ApiResult<Transaction>> createTransaction(Transaction transaction);
  Future<ApiResult<List<Transaction>>> getTransactions({
    TransactionStatus? status,
    TransactionType? type,
    String? searchQuery,
    int? limit,
    String? lastDocumentId,
  });
  Future<ApiResult<Transaction>> getTransactionById(String id);
  Future<ApiResult<Transaction>> updateTransaction(Transaction transaction);
  Future<ApiResult<void>> deleteTransaction(String id);
  Future<ApiResult<Transaction>> verifyTransaction(String id, String verifiedBy);
  Future<ApiResult<Transaction>> completeTransaction(String id);
  Future<ApiResult<List<TransactionContact>>> getTransactionContacts();
  Future<ApiResult<List<Transaction>>> getContactTransactions(String contactPhone);
  Future<ApiResult<QRData>> generateQRCode({
    required String userPhone,
    required String userName,
    String? userEmail,
    required bool verificationRequired,
    String? customMessage,
  });
  Future<ApiResult<QRData>> parseQRCode(String qrCodeData);
  Future<ApiResult<bool>> getGlobalVerificationSetting();
  Future<ApiResult<void>> setGlobalVerificationSetting(bool enabled);
  Future<ApiResult<Map<String, dynamic>>> getTransactionStats();
}