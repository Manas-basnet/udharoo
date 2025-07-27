import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/contact_history.dart';
import 'package:udharoo/features/transactions/domain/repositories/contact_history_repository.dart';

class SearchContactHistoryUseCase {
  final ContactHistoryRepository repository;

  SearchContactHistoryUseCase(this.repository);

  Future<ApiResult<List<ContactHistory>>> call({
    required String query,
    int? limit,
    String? userId,
  }) {
    return repository.searchContactHistory(
      query: query,
      limit: limit,
      userId: userId,
    );
  }
}