import 'package:udharoo/core/data/base_repository.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/core/utils/exception_handler.dart';
import 'package:udharoo/features/transactions/data/models/qr_transaction_data_model.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/qr_repository.dart';

class QRRepositoryImpl extends BaseRepository implements QRRepository {
  QRRepositoryImpl({required super.networkInfo});

  @override
  Future<ApiResult<QRTransactionData>> generateQRData({
    required String userId,
    required String userName,
    required String phoneNumber,
    String? email,
    TransactionType? transactionTypeConstraint,
    Duration? validityDuration,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      final createdAt = DateTime.now();
      final expiresAt = validityDuration != null 
          ? createdAt.add(validityDuration)
          : null;

      final qrData = QRTransactionDataModel(
        userId: userId,
        userName: userName,
        phoneNumber: phoneNumber,
        email: email,
        transactionTypeConstraint: transactionTypeConstraint,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );

      return ApiResult.success(qrData);
    });
  }

  @override
  Future<ApiResult<String>> generateQRCodeString(QRTransactionData qrData) async {
    return ExceptionHandler.handleExceptions(() async {
      final model = QRTransactionDataModel.fromEntity(qrData);
      final qrString = model.toQRString();
      return ApiResult.success(qrString);
    });
  }

  @override
  Future<ApiResult<QRTransactionData>> parseQRData(String qrString) async {
    return ExceptionHandler.handleExceptions(() async {
      if (qrString.trim().isEmpty) {
        return ApiResult.failure(
          'QR code cannot be empty',
          FailureType.validation,
        );
      }

      try {
        final qrData = QRTransactionDataModel.fromQRString(qrString);
        return ApiResult.success(qrData);
      } catch (e) {
        return ApiResult.failure(
          'Invalid QR code format. Please scan a valid Udharoo QR code.',
          FailureType.validation,
        );
      }
    });
  }

  @override
  Future<ApiResult<bool>> validateQRData({
    required QRTransactionData qrData,
    required String currentUserId,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      // Check if user is trying to scan their own QR code
      if (qrData.userId == currentUserId) {
        return ApiResult.failure(
          'You cannot create a transaction with yourself',
          FailureType.validation,
        );
      }

      // Check if QR code is expired
      if (qrData.isExpired) {
        return ApiResult.failure(
          'This QR code has expired. Please ask for a new one.',
          FailureType.validation,
        );
      }

      // Check version compatibility
      if (qrData.version != '1.0') {
        return ApiResult.failure(
          'Unsupported QR code version. Please update your app.',
          FailureType.validation,
        );
      }

      // Validate phone number format
      if (!_isValidPhoneNumber(qrData.phoneNumber)) {
        return ApiResult.failure(
          'Invalid phone number in QR code',
          FailureType.validation,
        );
      }

      // Validate user name
      if (qrData.userName.trim().isEmpty) {
        return ApiResult.failure(
          'Invalid user name in QR code',
          FailureType.validation,
        );
      }

      return ApiResult.success(true);
    });
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    // Basic phone number validation
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }
}