import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/repositories/qr_repository.dart';

class ValidateQRDataUseCase {
  final QRRepository repository;

  ValidateQRDataUseCase(this.repository);

  Future<ApiResult<bool>> call({
    required QRTransactionData qrData,
    required String currentUserId,
  }) {
    return repository.validateQRData(
      qrData: qrData,
      currentUserId: currentUserId,
    );
  }
}