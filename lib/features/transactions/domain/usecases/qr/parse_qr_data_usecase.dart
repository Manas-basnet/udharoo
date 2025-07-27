import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/repositories/qr_repository.dart';

class ParseQRDataUseCase {
  final QRRepository repository;

  ParseQRDataUseCase(this.repository);

  Future<ApiResult<QRTransactionData>> call(String qrString) {
    return repository.parseQRData(qrString);
  }
}