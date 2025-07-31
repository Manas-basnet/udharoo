import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/domain/repositories/contact_repository.dart';

class SearchContactsUseCase {
  final ContactRepository repository;

  SearchContactsUseCase(this.repository);

  Future<ApiResult<List<Contact>>> call(String query) {
    return repository.searchContacts(query);
  }
}