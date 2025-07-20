import 'dart:convert';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/presentation/services/qr_service.dart';

class QrServiceImpl implements QrService {
  static const String _qrPrefix = 'udharoo://user/';
  static const String _qrPrefixAlt = 'udharoo://transaction/';

  @override
  String generateUserQrData({
    required String userId,
    required String userName,
    String? userPhone,
  }) {
    try {
      final data = QrTransactionData(
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        qrType: 'user',
      );

      final jsonString = jsonEncode(data.toJson());
      final encodedData = base64Url.encode(utf8.encode(jsonString));
      return '$_qrPrefix$encodedData';
    } catch (e) {
      throw Exception('Failed to generate QR data: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<QrTransactionData>> parseQrData(String qrData) async {
    try {
      String cleanedData = qrData.trim();
      
      if (cleanedData.isEmpty) {
        return ApiResult.failure(
          'QR data is empty',
          FailureType.validation,
        );
      }

      String? encodedData;
      
      if (cleanedData.startsWith(_qrPrefix)) {
        encodedData = cleanedData.substring(_qrPrefix.length);
      } else if (cleanedData.startsWith(_qrPrefixAlt)) {
        encodedData = cleanedData.substring(_qrPrefixAlt.length);
      } else {
        return _tryParseAsLegacyFormat(cleanedData);
      }

      if (encodedData.isEmpty) {
        return ApiResult.failure(
          'Invalid QR format: missing encoded data',
          FailureType.validation,
        );
      }

      try {
        final decodedBytes = base64Url.decode(encodedData);
        final jsonString = utf8.decode(decodedBytes);
        
        if (jsonString.isEmpty) {
          return ApiResult.failure(
            'Decoded QR data is empty',
            FailureType.validation,
          );
        }

        final json = jsonDecode(jsonString);
        
        if (json is! Map<String, dynamic>) {
          return ApiResult.failure(
            'Invalid QR data format: not a JSON object',
            FailureType.validation,
          );
        }

        final qrTransactionData = QrTransactionData.fromJson(json);
        
        if (qrTransactionData.userId.isEmpty) {
          return ApiResult.failure(
            'Invalid QR data: missing user ID',
            FailureType.validation,
          );
        }

        if (qrTransactionData.userName.isEmpty) {
          return ApiResult.failure(
            'Invalid QR data: missing user name',
            FailureType.validation,
          );
        }

        return ApiResult.success(qrTransactionData);
        
      } on FormatException catch (e) {
        return ApiResult.failure(
          'Invalid QR data format: ${e.message}',
          FailureType.validation,
        );
      } on ArgumentError catch (e) {
        return ApiResult.failure(
          'Invalid base64 encoding: ${e.message}',
          FailureType.validation,
        );
      }
    } catch (e) {
      return ApiResult.failure(
        'Failed to parse QR data: ${e.toString()}',
        FailureType.unknown,
      );
    }
  }

  ApiResult<QrTransactionData> _tryParseAsLegacyFormat(String qrData) {
    try {
      final json = jsonDecode(qrData);
      if (json is Map<String, dynamic>) {
        final qrTransactionData = QrTransactionData.fromJson(json);
        return ApiResult.success(qrTransactionData);
      }
    } catch (e) {
      // Continue to other format attempts
    }

    try {
      final uri = Uri.parse(qrData);
      if (uri.scheme == 'udharoo' || uri.scheme == 'https') {
        final params = uri.queryParameters;
        if (params.containsKey('userId') && params.containsKey('userName')) {
          final qrTransactionData = QrTransactionData(
            userId: params['userId']!,
            userName: params['userName']!,
            userPhone: params['userPhone'],
            qrType: 'user',
          );
          return ApiResult.success(qrTransactionData);
        }
      }
    } catch (e) {
      // Continue to other format attempts
    }

    return ApiResult.failure(
      'Unrecognized QR code format. Please scan a valid Udharoo QR code.',
      FailureType.validation,
    );
  }

  @override
  String generateTransactionQrData({
    required String userId,
    required String userName,
    String? userPhone,
    double? amount,
    String? description,
    DateTime? dueDate,
    bool requiresVerification = true,
  }) {
    try {
      final data = QrTransactionData(
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        amount: amount,
        description: description,
        dueDate: dueDate,
        requiresVerification: requiresVerification,
        qrType: 'transaction',
      );

      final jsonString = jsonEncode(data.toJson());
      final encodedData = base64Url.encode(utf8.encode(jsonString));
      return '$_qrPrefixAlt$encodedData';
    } catch (e) {
      throw Exception('Failed to generate transaction QR data: ${e.toString()}');
    }
  }

  @override
  bool isValidUdharooQr(String qrData) {
    return qrData.startsWith(_qrPrefix) || 
           qrData.startsWith(_qrPrefixAlt) ||
           _isLegacyFormat(qrData);
  }

  bool _isLegacyFormat(String qrData) {
    try {
      final json = jsonDecode(qrData);
      if (json is Map<String, dynamic>) {
        return json.containsKey('userId') && json.containsKey('userName');
      }
    } catch (e) {
      // Not JSON format
    }

    try {
      final uri = Uri.parse(qrData);
      if (uri.scheme == 'udharoo' || uri.scheme == 'https') {
        final params = uri.queryParameters;
        return params.containsKey('userId') && params.containsKey('userName');
      }
    } catch (e) {
      // Not URI format
    }

    return false;
  }
}