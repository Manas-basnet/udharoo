import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';

abstract class ContactRepository {
  Future<ApiResult<void>> addContact({
    required String contactUserId,
    required String name,
    required String phoneNumber,
    String? email,
    String? photoUrl,
  });

  Future<ApiResult<List<Contact>>> getContacts();

  Future<ApiResult<List<Contact>>> searchContacts(String query);

  Future<ApiResult<Contact?>> getContactById(String contactId);

  Future<ApiResult<Contact?>> getContactByUserId(String contactUserId);

  Future<ApiResult<void>> deleteContact(String contactId);
}