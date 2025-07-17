import 'dart:convert';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/presentation/services/qr_service.dart';

class QrServiceImpl implements QrService {
  static const String _qrPrefix = 'udharoo://user/';

  @override
  String generateUserQrData({
    required String userId,
    required String userName,
    String? userPhone,
  }) {
    final data = QrTransactionData(
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      qrType: 'user',
    );

    final jsonString = jsonEncode(data.toJson());
    final encodedData = base64Url.encode(utf8.encode(jsonString));
    return '$_qrPrefix$encodedData';
  }

  @override
  Future<ApiResult<QrTransactionData>> parseQrData(String qrData) async {
    try {
      if (!qrData.startsWith(_qrPrefix)) {
        return ApiResult.failure(
          'Invalid Udharoo QR code',
          FailureType.validation,
        );
      }

      final encodedData = qrData.substring(_qrPrefix.length);
      final decodedBytes = base64Url.decode(encodedData);
      final jsonString = utf8.decode(decodedBytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final qrTransactionData = QrTransactionData.fromJson(json);
      return ApiResult.success(qrTransactionData);
    } catch (e) {
      return ApiResult.failure(
        'Failed to parse QR data: ${e.toString()}',
        FailureType.validation,
      );
    }
  }
}