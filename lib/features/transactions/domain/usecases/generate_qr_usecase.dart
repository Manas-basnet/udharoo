import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class GenerateQRUseCase {
  final TransactionRepository repository;

  GenerateQRUseCase(this.repository);

  Future<ApiResult<QRData>> call({
    required String userPhone,
    required String userName,
    String? userEmail,
    required bool verificationRequired,
    String? customMessage,
  }) {
    return repository.generateQRCode(
      userPhone: userPhone,
      userName: userName,
      userEmail: userEmail,
      verificationRequired: verificationRequired,
      customMessage: customMessage,
    );
  }
}