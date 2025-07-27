import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/qr_repository.dart';

class GenerateQRDataUseCase {
  final QRRepository repository;

  GenerateQRDataUseCase(this.repository);

  Future<ApiResult<QRTransactionData>> call({
    required String userId,
    required String userName,
    required String phoneNumber,
    String? email,
    TransactionType? transactionTypeConstraint,
    Duration? validityDuration,
  }) {
    return repository.generateQRData(
      userId: userId,
      userName: userName,
      phoneNumber: phoneNumber,
      email: email,
      transactionTypeConstraint: transactionTypeConstraint,
      validityDuration: validityDuration,
    );
  }
}