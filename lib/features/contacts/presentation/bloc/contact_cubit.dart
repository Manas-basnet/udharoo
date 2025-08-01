import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/usecases/get_user_by_phone_usecase.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/domain/usecases/add_contact_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/delete_contact_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/get_contact_by_user_id_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/get_contact_transaction_count_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/search_contacts_usecase.dart';

part 'contact_state.dart';

class ContactCubit extends Cubit<ContactState> {
  final GetContactsUseCase _getContactsUseCase;
  final SearchContactsUseCase _searchContactsUseCase;
  final AddContactUseCase _addContactUseCase;
  final DeleteContactUseCase _deleteContactUseCase;
  final GetContactByUserIdUseCase _getContactByUserIdUseCase;
  final GetContactTransactionCountUseCase _getContactTransactionCountUseCase;
  final GetUserByPhoneUseCase _getUserByPhoneUseCase;
  final FirebaseAuth _firebaseAuth;

  final Map<String, int> _transactionCounts = {};

  ContactCubit({
    required GetContactsUseCase getContactsUseCase,
    required SearchContactsUseCase searchContactsUseCase,
    required AddContactUseCase addContactUseCase,
    required DeleteContactUseCase deleteContactUseCase,
    required GetContactByUserIdUseCase getContactByUserIdUseCase,
    required GetContactTransactionCountUseCase getContactTransactionCountUseCase,
    required GetUserByPhoneUseCase getUserByPhoneUseCase,
    required FirebaseAuth firebaseAuth,
  })  : _getContactsUseCase = getContactsUseCase,
        _searchContactsUseCase = searchContactsUseCase,
        _addContactUseCase = addContactUseCase,
        _deleteContactUseCase = deleteContactUseCase,
        _getContactByUserIdUseCase = getContactByUserIdUseCase,
        _getContactTransactionCountUseCase = getContactTransactionCountUseCase,
        _getUserByPhoneUseCase = getUserByPhoneUseCase,
        _firebaseAuth = firebaseAuth,
        super(const ContactInitial());

  String? get _currentUserPhone => _firebaseAuth.currentUser?.phoneNumber;

  int getTransactionCount(String contactUserId) {
    return _transactionCounts[contactUserId] ?? 0;
  }

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

  Future<void> lookupUserByPhone(String phoneNumber) async {
    final trimmedPhoneNumber = phoneNumber.trim();

    if (trimmedPhoneNumber.isEmpty) {
      return;
    }

    if(_currentUserPhone != null && trimmedPhoneNumber == _currentUserPhone) {
      emit(ContactError('You cannot create a contact with yourself.', FailureType.validation));
      return;
    }

    final result = await _getUserByPhoneUseCase(trimmedPhoneNumber);

    if (!isClosed) {
      result.fold(
        onSuccess: (user) {
          if (user != null) {
            emit(ContactUserLookupSuccess(user));
          } else {
            emit(const ContactError('User not found.', FailureType.validation));
          }
        },
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

  Future<void> updateContactTransactionCount(String contactUserId) async {
    final result = await _getContactTransactionCountUseCase(contactUserId);
    
    result.fold(
      onSuccess: (count) {
        _transactionCounts[contactUserId] = count;
        if (!isClosed) {
          final currentState = state;
          if (currentState is ContactLoaded) {
            emit(ContactTransactionCountUpdated(currentState.contacts, Map.from(_transactionCounts)));
          } else if (currentState is ContactSearchResults) {
            emit(ContactSearchTransactionCountUpdated(currentState.contacts, currentState.query, Map.from(_transactionCounts)));
          }
        }
      },
      onFailure: (_, __) {
      },
    );
  }

  Future<void> refreshContactTransactionCounts() async {
    final currentState = state;
    List<Contact> contacts = [];
    
    if (currentState is ContactLoaded) {
      contacts = currentState.contacts;
    } else if (currentState is ContactSearchResults) {
      contacts = currentState.contacts;
    } else {
      return;
    }

    for (final contact in contacts) {
      final result = await _getContactTransactionCountUseCase(contact.contactUserId);
      result.fold(
        onSuccess: (count) {
          _transactionCounts[contact.contactUserId] = count;
        },
        onFailure: (_, __) {
        },
      );
    }

    if (!isClosed) {
      if (currentState is ContactLoaded) {
        emit(ContactTransactionCountUpdated(contacts, Map.from(_transactionCounts)));
      } else if (currentState is ContactSearchResults) {
        emit(ContactSearchTransactionCountUpdated(contacts, currentState.query, Map.from(_transactionCounts)));
      }
    }
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