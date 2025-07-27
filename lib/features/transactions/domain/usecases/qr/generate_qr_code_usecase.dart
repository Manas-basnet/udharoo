import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/repositories/qr_repository.dart';

class GenerateQRCodeUseCase {
  final QRRepository repository;

  GenerateQRCodeUseCase(this.repository);

  Future<ApiResult<String>> call(QRTransactionData qrData) {
    return repository.generateQRCodeString(qrData);
  }
}