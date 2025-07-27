import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/repositories/contact_history_repository.dart';

class ClearContactHistoryUseCase {
  final ContactHistoryRepository repository;

  ClearContactHistoryUseCase(this.repository);

  Future<ApiResult<void>> call(String? userId) {
    return repository.clearContactHistory(userId);
  }
}