import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/contacts/domain/repositories/contact_repository.dart';

class DeleteContactUseCase {
  final ContactRepository repository;

  DeleteContactUseCase(this.repository);

  Future<ApiResult<void>> call(String contactId) {
    return repository.deleteContact(contactId);
  }
}