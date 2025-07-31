import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/contacts/domain/repositories/contact_repository.dart';

class AddContactUseCase {
  final ContactRepository repository;

  AddContactUseCase(this.repository);

  Future<ApiResult<void>> call({
    required String contactUserId,
    required String name,
    required String phoneNumber,
    String? email,
    String? photoUrl,
  }) {
    return repository.addContact(
      contactUserId: contactUserId,
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      photoUrl: photoUrl,
    );
  }
}