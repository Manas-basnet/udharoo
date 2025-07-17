import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';

abstract class QrService {
  String generateUserQrData({
    required String userId,
    required String userName,
    String? userPhone,
  });
  Future<ApiResult<QrTransactionData>> parseQrData(String qrData);
}