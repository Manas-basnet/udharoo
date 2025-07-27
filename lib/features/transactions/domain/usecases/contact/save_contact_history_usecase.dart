import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/repositories/contact_history_repository.dart';

class SaveContactHistoryUseCase {
  final ContactHistoryRepository repository;

  SaveContactHistoryUseCase(this.repository);

  Future<ApiResult<void>> call({
    required String phoneNumber,
    required String name,
    String? userId,
  }) {
    return repository.saveContactHistory(
      phoneNumber: phoneNumber,
      name: name,
      userId: userId,
    );
  }
}