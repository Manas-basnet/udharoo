import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';

abstract class QrService {
  String generateUserQrData({
    required String userId,
    required String userName,
    String? userPhone,
  });
  
  String generateTransactionQrData({
    required String userId,
    required String userName,
    String? userPhone,
    double? amount,
    String? description,
    DateTime? dueDate,
    bool requiresVerification = true,
  });
  
  Future<ApiResult<QrTransactionData>> parseQrData(String qrData);
  
  bool isValidUdharooQr(String qrData);
}