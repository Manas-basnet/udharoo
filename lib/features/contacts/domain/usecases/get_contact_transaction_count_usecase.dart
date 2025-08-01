import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/contacts/domain/repositories/contact_repository.dart';

class GetContactTransactionCountUseCase {
  final ContactRepository repository;

  GetContactTransactionCountUseCase(this.repository);

  Future<ApiResult<int>> call(String contactUserId) {
    return repository.getContactTransactionCount(contactUserId);
  }
}