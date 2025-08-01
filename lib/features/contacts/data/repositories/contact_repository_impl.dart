import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/core/data/base_repository.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/core/utils/exception_handler.dart';
import 'package:udharoo/features/contacts/data/datasources/local/contact_local_datasource.dart';
import 'package:udharoo/features/contacts/data/datasources/remote/contact_remote_datasource.dart';
import 'package:udharoo/features/contacts/data/models/contact_model.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/domain/repositories/contact_repository.dart';

class ContactRepositoryImpl extends BaseRepository implements ContactRepository {
  final ContactLocalDatasource _localDatasource;
  final ContactRemoteDatasource _remoteDatasource;
  final FirebaseAuth _firebaseAuth;

  ContactRepositoryImpl({
    required ContactLocalDatasource localDatasource,
    required ContactRemoteDatasource remoteDatasource,
    required super.networkInfo,
    FirebaseAuth? firebaseAuth,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  String get _currentUserId {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }
    return user.uid;
  }

  @override
  Future<ApiResult<void>> addContact({
    required String contactUserId,
    required String name,
    required String phoneNumber,
    String? email,
    String? photoUrl,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      if (contactUserId == _currentUserId) {
        return ApiResult.failure(
          'You cannot add yourself as a contact',
          FailureType.validation,
        );
      }

      final existingContact = await _localDatasource.getContactByUserId(contactUserId, _currentUserId);
      if (existingContact != null) {
        return ApiResult.failure(
          'Contact already exists',
          FailureType.validation,
        );
      }

      final now = DateTime.now();
      final contactId = '${_currentUserId}_${contactUserId}_${now.millisecondsSinceEpoch}';
      
      final contact = ContactModel(
        id: contactId,
        userId: _currentUserId,
        contactUserId: contactUserId,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        photoUrl: photoUrl,
        addedAt: now,
        lastInteractionAt: now,
      );

      await _localDatasource.saveContact(contact);

      if (await networkInfo.isConnected) {
        try {
          await _remoteDatasource.saveContact(contact);
        } catch (e) {
        }
      }

      return ApiResult.success(null);
    });
  }

  @override
  Future<ApiResult<List<Contact>>> getContacts() async {
    return ExceptionHandler.handleExceptions(() async {
      List<ContactModel> contacts = await _localDatasource.getContacts(_currentUserId);

      if (await networkInfo.isConnected) {
        try {
          final remoteContacts = await _remoteDatasource.getContacts(_currentUserId);
          await _localDatasource.saveContacts(remoteContacts, _currentUserId);
          contacts = remoteContacts;
        } catch (e) {
        }
      }

      return ApiResult.success(contacts.cast<Contact>());
    });
  }

  @override
  Future<ApiResult<List<Contact>>> searchContacts(String query) async {
    return ExceptionHandler.handleExceptions(() async {
      if (query.trim().isEmpty) {
        return getContacts();
      }

      final contacts = await _localDatasource.searchContacts(query.trim(), _currentUserId);
      return ApiResult.success(contacts.cast<Contact>());
    });
  }

  @override
  Future<ApiResult<Contact?>> getContactById(String contactId) async {
    return ExceptionHandler.handleExceptions(() async {
      final contact = await _localDatasource.getContactById(contactId, _currentUserId);
      return ApiResult.success(contact);
    });
  }

  @override
  Future<ApiResult<Contact?>> getContactByUserId(String contactUserId) async {
    return ExceptionHandler.handleExceptions(() async {
      final contact = await _localDatasource.getContactByUserId(contactUserId, _currentUserId);
      return ApiResult.success(contact);
    });
  }

  @override
  Future<ApiResult<void>> deleteContact(String contactId) async {
    return ExceptionHandler.handleExceptions(() async {
      await _localDatasource.deleteContact(contactId, _currentUserId);

      if (await networkInfo.isConnected) {
        await _remoteDatasource.deleteContact(contactId, _currentUserId);
      }

      return ApiResult.success(null);
    });
  }
}