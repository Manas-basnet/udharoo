import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/domain/repositories/contact_repository.dart';

class GetContactsUseCase {
  final ContactRepository repository;

  GetContactsUseCase(this.repository);

  Future<ApiResult<List<Contact>>> call() {
    return repository.getContacts();
  }
}