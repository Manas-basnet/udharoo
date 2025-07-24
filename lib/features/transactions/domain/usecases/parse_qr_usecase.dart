import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class ParseQRUseCase {
  final TransactionRepository repository;

  ParseQRUseCase(this.repository);

  Future<ApiResult<QRData>> call(String qrCodeData) {
    return repository.parseQRCode(qrCodeData);
  }
}
