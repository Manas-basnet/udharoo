import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/repositories/contact_history_repository.dart';

class DeleteContactHistoryUseCase {
  final ContactHistoryRepository repository;

  DeleteContactHistoryUseCase(this.repository);

  Future<ApiResult<void>> call({
    required String phoneNumber,
    String? userId,
  }) {
    return repository.deleteContactHistory(
      phoneNumber: phoneNumber,
      userId: userId,
    );
  }
}