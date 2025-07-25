import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_contacts_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_contact_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/delete_transaction_usecase.dart';

part 'contact_transactions_state.dart';

class ContactTransactionsCubit extends Cubit<ContactTransactionsState> {
  final GetTransactionContactsUseCase getTransactionContactsUseCase;
  final GetContactTransactionsUseCase getContactTransactionsUseCase;
  final VerifyTransactionUseCase verifyTransactionUseCase;
  final CompleteTransactionUseCase completeTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;

  ContactTransactionsCubit({
    required this.getTransactionContactsUseCase,
    required this.getContactTransactionsUseCase,
    required this.verifyTransactionUseCase,
    required this.completeTransactionUseCase,
    required this.deleteTransactionUseCase,
  }) : super(const ContactTransactionsInitial());

  Future<void> loadTransactionContacts() async {
    emit(const ContactTransactionsLoading());

    final result = await getTransactionContactsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (contacts) => emit(ContactsLoaded(contacts)),
        onFailure: (message, type) => emit(ContactTransactionsError(message, type)),
      );
    }
  }

  Future<void> loadContactTransactions(String contactPhone) async {
    emit(const ContactTransactionsLoading());

    final result = await getContactTransactionsUseCase(contactPhone);

    if (!isClosed) {
      result.fold(
        onSuccess: (transactions) => emit(ContactTransactionsLoaded(
          transactions: transactions,
          contactPhone: contactPhone,
        )),
        onFailure: (message, type) => emit(ContactTransactionsError(message, type)),
      );
    }
  }

  Future<void> verifyTransaction(String id, String verifiedBy) async {
    final result = await verifyTransactionUseCase(id, verifiedBy);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          emit(ContactTransactionUpdated(transaction));
          _reloadCurrentContactTransactions();
        },
        onFailure: (message, type) => emit(ContactTransactionsError(message, type)),
      );
    }
  }

  Future<void> completeTransaction(String id) async {
    final result = await completeTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          emit(ContactTransactionUpdated(transaction));
          _reloadCurrentContactTransactions();
        },
        onFailure: (message, type) => emit(ContactTransactionsError(message, type)),
      );
    }
  }

  Future<void> deleteTransaction(String id) async {
    final result = await deleteTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) {
          emit(ContactTransactionDeleted(id));
          _reloadCurrentContactTransactions();
        },
        onFailure: (message, type) => emit(ContactTransactionsError(message, type)),
      );
    }
  }

  void _reloadCurrentContactTransactions() {
    if (state is ContactTransactionsLoaded) {
      final currentState = state as ContactTransactionsLoaded;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!isClosed) {
          loadContactTransactions(currentState.contactPhone);
        }
      });
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const ContactTransactionsInitial());
    }
  }
}