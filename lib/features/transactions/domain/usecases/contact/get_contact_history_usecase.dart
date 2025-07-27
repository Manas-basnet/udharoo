import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/contact_history.dart';
import 'package:udharoo/features/transactions/domain/repositories/contact_history_repository.dart';

class GetContactHistoryUseCase {
  final ContactHistoryRepository repository;

  GetContactHistoryUseCase(this.repository);

  Future<ApiResult<List<ContactHistory>>> call({
    int? limit,
    String? userId,
  }) {
    return repository.getContactHistory(
      limit: limit,
      userId: userId,
    );
  }
}