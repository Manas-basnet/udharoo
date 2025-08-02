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
import 'package:udharoo/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/search_contacts_usecase.dart';

part 'contact_state.dart';

class ContactCubit extends Cubit<ContactState> {
  final GetContactsUseCase _getContactsUseCase;
  final SearchContactsUseCase _searchContactsUseCase;
  final AddContactUseCase _addContactUseCase;
  final DeleteContactUseCase _deleteContactUseCase;
  final GetContactByUserIdUseCase _getContactByUserIdUseCase;
  final GetUserByPhoneUseCase _getUserByPhoneUseCase;
  final FirebaseAuth _firebaseAuth;

  ContactCubit({
    required GetContactsUseCase getContactsUseCase,
    required SearchContactsUseCase searchContactsUseCase,
    required AddContactUseCase addContactUseCase,
    required DeleteContactUseCase deleteContactUseCase,
    required GetContactByUserIdUseCase getContactByUserIdUseCase,
    required GetUserByPhoneUseCase getUserByPhoneUseCase,
    required FirebaseAuth firebaseAuth,
  })  : _getContactsUseCase = getContactsUseCase,
        _searchContactsUseCase = searchContactsUseCase,
        _addContactUseCase = addContactUseCase,
        _deleteContactUseCase = deleteContactUseCase,
        _getContactByUserIdUseCase = getContactByUserIdUseCase,
        _getUserByPhoneUseCase = getUserByPhoneUseCase,
        _firebaseAuth = firebaseAuth,
        super(ContactState.initial());

  String? get _currentUserPhone => _firebaseAuth.currentUser?.phoneNumber;

  Future<void> loadContacts() async {
    if (!isClosed && !state.isInitialized) {
      emit(state.copyWith(isInitialLoading: true));
    }

    try {
      final result = await _getContactsUseCase();

      if (!isClosed) {
        result.fold(
          onSuccess: (contacts) {
            emit(state.copyWith(
              contacts: contacts,
              isInitialLoading: false,
              isInitialized: true,
              searchQuery: null,
              searchResults: [],
            ).clearError());
          },
          onFailure: (message, type) {
            emit(state.copyWith(
              isInitialLoading: false,
              errorMessage: message,
              isInitialized: true,
            ));
          },
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(
          isInitialLoading: false,
          errorMessage: _getErrorMessage(error),
          isInitialized: true,
        ));
      }
    }
  }

  Future<void> searchContacts(String query) async {
    final trimmedQuery = query.trim();
    
    if (trimmedQuery.isEmpty) {
      emit(state.copyWith(
        searchQuery: null,
        searchResults: [],
      ));
      return;
    }

    if (!isClosed) {
      emit(state.copyWith(
        isSearching: true,
        searchQuery: trimmedQuery,
      ).clearError());
    }

    try {
      final result = await _searchContactsUseCase(trimmedQuery);

      if (!isClosed) {
        result.fold(
          onSuccess: (searchResults) {
            emit(state.copyWith(
              searchResults: searchResults,
              isSearching: false,
              searchQuery: trimmedQuery,
            ).clearError());
          },
          onFailure: (message, type) {
            emit(state.copyWith(
              isSearching: false,
              errorMessage: message,
              searchResults: [],
            ));
          },
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(
          isSearching: false,
          errorMessage: _getErrorMessage(error),
          searchResults: [],
        ));
      }
    }
  }

  Future<void> lookupUserByPhone(String phoneNumber) async {
    final trimmedPhoneNumber = phoneNumber.trim();

    if (trimmedPhoneNumber.isEmpty) {
      return;
    }

    if (_currentUserPhone != null && trimmedPhoneNumber == _currentUserPhone) {
      emit(state.copyWith(
        errorMessage: 'You cannot create a contact with yourself.',
        foundUser: null,
      ));
      return;
    }

    if (!isClosed) {
      emit(state.copyWith(
        isLookingUpUser: true,
        foundUser: null,
      ).clearError());
    }

    try {
      final result = await _getUserByPhoneUseCase(trimmedPhoneNumber);

      if (!isClosed) {
        result.fold(
          onSuccess: (user) {
            if (user != null) {
              emit(state.copyWith(
                foundUser: user,
                isLookingUpUser: false,
              ).clearError());
            } else {
              emit(state.copyWith(
                errorMessage: 'User not found.',
                isLookingUpUser: false,
                foundUser: null,
              ));
            }
          },
          onFailure: (message, type) {
            emit(state.copyWith(
              errorMessage: message,
              isLookingUpUser: false,
              foundUser: null,
            ));
          },
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(
          errorMessage: _getErrorMessage(error),
          isLookingUpUser: false,
          foundUser: null,
        ));
      }
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
      emit(state.copyWith(isAdding: true).clearMessages());
    }

    try {
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
            emit(state.copyWith(
              isAdding: false,
              successMessage: 'Contact added successfully',
              foundUser: null,
            ));
            loadContacts();
          },
          onFailure: (message, type) {
            emit(state.copyWith(
              isAdding: false,
              errorMessage: message,
            ));
          },
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(
          isAdding: false,
          errorMessage: _getErrorMessage(error),
        ));
      }
    }
  }

  Future<void> deleteContact(String contactId) async {
    if (!isClosed) {
      emit(state.copyWith(isDeleting: true).clearMessages());
    }

    try {
      final result = await _deleteContactUseCase(contactId);

      if (!isClosed) {
        result.fold(
          onSuccess: (_) {
            emit(state.copyWith(
              isDeleting: false,
              successMessage: 'Contact deleted successfully',
            ));
            loadContacts();
          },
          onFailure: (message, type) {
            emit(state.copyWith(
              isDeleting: false,
              errorMessage: message,
            ));
          },
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(
          isDeleting: false,
          errorMessage: _getErrorMessage(error),
        ));
      }
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
      emit(state.copyWith(
        searchQuery: null,
        searchResults: [],
      ));
    }
  }

  void clearMessages() {
    if (!isClosed) {
      emit(state.clearMessages());
    }
  }

  void clearError() {
    if (!isClosed) {
      emit(state.clearError());
    }
  }

  void clearSuccess() {
    if (!isClosed) {
      emit(state.clearSuccess());
    }
  }

  void clearFoundUser() {
    if (!isClosed) {
      emit(state.clearFoundUser());
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(ContactState.initial());
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is String) return error;
    return error?.toString() ?? 'An unexpected error occurred';
  }
}