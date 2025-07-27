import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

abstract class QRRepository {
  Future<ApiResult<QRTransactionData>> generateQRData({
    required String userId,
    required String userName,
    required String phoneNumber,
    String? email,
    TransactionType? transactionTypeConstraint,
    Duration? validityDuration,
  });

  Future<ApiResult<String>> generateQRCodeString(QRTransactionData qrData);

  Future<ApiResult<QRTransactionData>> parseQRData(String qrString);

  Future<ApiResult<bool>> validateQRData({
    required QRTransactionData qrData,
    required String currentUserId,
  });
}