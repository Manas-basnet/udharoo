import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/contact_history.dart';
import 'package:udharoo/features/transactions/domain/usecases/contact/delete_contact_history_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/contact/get_contact_history_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/contact/save_contact_history_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/contact/search_contact_history_usecase.dart';

part 'contact_history_state.dart';

class ContactHistoryCubit extends Cubit<ContactHistoryState> {
  final GetContactHistoryUseCase _getContactHistoryUseCase;
  final SaveContactHistoryUseCase _saveContactHistoryUseCase;
  final SearchContactHistoryUseCase _searchContactHistoryUseCase;
  final DeleteContactHistoryUseCase _deleteContactHistoryUseCase;
  final FirebaseAuth _firebaseAuth;

  ContactHistoryCubit({
    required GetContactHistoryUseCase getContactHistoryUseCase,
    required SaveContactHistoryUseCase saveContactHistoryUseCase,
    required SearchContactHistoryUseCase searchContactHistoryUseCase,
    required DeleteContactHistoryUseCase deleteContactHistoryUseCase,
    FirebaseAuth? firebaseAuth,
  })  : _getContactHistoryUseCase = getContactHistoryUseCase,
        _saveContactHistoryUseCase = saveContactHistoryUseCase,
        _searchContactHistoryUseCase = searchContactHistoryUseCase,
        _deleteContactHistoryUseCase = deleteContactHistoryUseCase,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(const ContactHistoryInitial());

  String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  Future<void> loadContactHistory({int? limit}) async {
    if (!isClosed) {
      emit(const ContactHistoryLoading());
    }

    final result = await _getContactHistoryUseCase(
      limit: limit ?? 10,
      userId: _currentUserId,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (contacts) {
          emit(ContactHistoryLoaded(contacts));
        },
        onFailure: (message, type) {
          emit(ContactHistoryError(message, type));
        },
      );
    }
  }

  Future<void> searchContacts(String query, {int? limit}) async {
    if (query.trim().isEmpty) {
      await loadContactHistory(limit: limit);
      return;
    }

    if (!isClosed) {
      emit(const ContactHistorySearching());
    }

    final result = await _searchContactHistoryUseCase(
      query: query.trim(),
      limit: limit ?? 10,
      userId: _currentUserId,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (contacts) {
          emit(ContactHistorySearchResults(contacts, query));
        },
        onFailure: (message, type) {
          emit(ContactHistoryError(message, type));
        },
      );
    }
  }

  Future<void> saveContact({
    required String phoneNumber,
    required String name,
  }) async {
    final result = await _saveContactHistoryUseCase(
      phoneNumber: phoneNumber,
      name: name,
      userId: _currentUserId,
    );

    // Optionally reload contacts after saving
    if (result.isSuccess) {
      await loadContactHistory();
    }
  }

  Future<void> deleteContact(String phoneNumber) async {
    final result = await _deleteContactHistoryUseCase(
      phoneNumber: phoneNumber,
      userId: _currentUserId,
    );

    if (result.isSuccess) {
      // Remove from current state if possible
      final currentState = state;
      if (currentState is ContactHistoryLoaded) {
        final updatedContacts = currentState.contacts
            .where((contact) => contact.phoneNumber != phoneNumber)
            .toList();
        
        if (!isClosed) {
          emit(ContactHistoryLoaded(updatedContacts));
        }
      } else if (currentState is ContactHistorySearchResults) {
        final updatedContacts = currentState.contacts
            .where((contact) => contact.phoneNumber != phoneNumber)
            .toList();
        
        if (!isClosed) {
          emit(ContactHistorySearchResults(updatedContacts, currentState.query));
        }
      }
    }
  }

  void clearSearchResults() {
    if (!isClosed) {
      loadContactHistory();
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const ContactHistoryInitial());
    }
  }
}