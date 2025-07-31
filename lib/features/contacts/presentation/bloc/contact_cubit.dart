import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/domain/usecases/add_contact_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/delete_contact_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/get_contact_by_user_id_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/search_contacts_usecase.dart';

part 'contact_state.dart';

class ContactCubit extends Cubit<ContactState> {
  final GetContactsUseCase _getContactsUseCase;
  final SearchContactsUseCase _searchContactsUseCase;
  final AddContactUseCase _addContactUseCase;
  final DeleteContactUseCase _deleteContactUseCase;
  final GetContactByUserIdUseCase _getContactByUserIdUseCase;

  ContactCubit({
    required GetContactsUseCase getContactsUseCase,
    required SearchContactsUseCase searchContactsUseCase,
    required AddContactUseCase addContactUseCase,
    required DeleteContactUseCase deleteContactUseCase,
    required GetContactByUserIdUseCase getContactByUserIdUseCase,
  })  : _getContactsUseCase = getContactsUseCase,
        _searchContactsUseCase = searchContactsUseCase,
        _addContactUseCase = addContactUseCase,
        _deleteContactUseCase = deleteContactUseCase,
        _getContactByUserIdUseCase = getContactByUserIdUseCase,
        super(const ContactInitial());

  Future<void> loadContacts() async {
    if (!isClosed) {
      emit(const ContactLoading());
    }

    final result = await _getContactsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (contacts) => emit(ContactLoaded(contacts)),
        onFailure: (message, type) => emit(ContactError(message, type)),
      );
    }
  }

  Future<void> searchContacts(String query) async {
    if (query.trim().isEmpty) {
      await loadContacts();
      return;
    }

    if (!isClosed) {
      emit(const ContactSearching());
    }

    final result = await _searchContactsUseCase(query.trim());

    if (!isClosed) {
      result.fold(
        onSuccess: (contacts) => emit(ContactSearchResults(contacts, query)),
        onFailure: (message, type) => emit(ContactError(message, type)),
      );
    }
  }

  Future<void> addContact({
    required String contactUserId,
    required String name,
    required String phoneNumber,
    String? email,
    String? photoUrl,
  }) async {
    if (!isClosed) {
      emit(const ContactAdding());
    }

    final result = await _addContactUseCase(
      contactUserId: contactUserId,
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      photoUrl: photoUrl,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (_) {
          emit(const ContactAddSuccess());
          loadContacts();
        },
        onFailure: (message, type) => emit(ContactError(message, type)),
      );
    }
  }

  Future<void> deleteContact(String contactId) async {
    final result = await _deleteContactUseCase(contactId);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) {
          emit(const ContactDeleteSuccess());
          loadContacts();
        },
        onFailure: (message, type) => emit(ContactError(message, type)),
      );
    }
  }

  Future<Contact?> getContactByUserId(String contactUserId) async {
    final result = await _getContactByUserIdUseCase(contactUserId);
    
    return result.fold(
      onSuccess: (contact) => contact,
      onFailure: (_, __) => null,
    );
  }

  void clearSearch() {
    if (!isClosed) {
      loadContacts();
    }
  }

  void clearMessages() {
    if (!isClosed && (state is ContactAddSuccess || state is ContactDeleteSuccess || state is ContactError)) {
      loadContacts();
    }
  }
}