import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/domain/repositories/contact_repository.dart';

class GetContactByUserIdUseCase {
  final ContactRepository repository;

  GetContactByUserIdUseCase(this.repository);

  Future<ApiResult<Contact?>> call(String contactUserId) {
    return repository.getContactByUserId(contactUserId);
  }
}